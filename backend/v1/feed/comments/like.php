<?php
require_once("../../configs/configs.php");
header('Content-Type: application/json');

$input_data = file_get_contents("php://input");
$data = json_decode($input_data, true);

// Validate input
if (empty($data['token']) || empty($data['comment_id'])) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Token and comment_id are required."
    ]);
    exit;
}

$token = mysqli_real_escape_string($connection, $data['token']);
$comment_id = intval($data['comment_id']);

// Get current user
$userQuery = mysqli_query($connection, "
    SELECT u.id FROM users u
    WHERE u.token = '$token' AND u.status = 'active' LIMIT 1
");

if (!$userQuery || mysqli_num_rows($userQuery) === 0) {
    http_response_code(403);
    echo json_encode([
        "code" => 403,
        "status" => "error",
        "message" => "Unauthorized. Invalid token."
    ]);
    exit;
}

$user = mysqli_fetch_assoc($userQuery);
$user_id = $user['id'];

// Check if comment exists
$commentQuery = mysqli_query($connection, "
    SELECT id FROM feed_comments 
    WHERE id = $comment_id AND status = 'active'
    LIMIT 1
");

if (!$commentQuery || mysqli_num_rows($commentQuery) === 0) {
    http_response_code(404);
    echo json_encode([
        "code" => 404,
        "status" => "error",
        "message" => "Comment not found."
    ]);
    exit;
}

// Check if already liked
$likeQuery = mysqli_query($connection, "
    SELECT id FROM feed_interactions 
    WHERE user_id = $user_id AND post_id = $comment_id AND interaction_type = 'like'
    LIMIT 1
");

if (mysqli_num_rows($likeQuery) > 0) {
    // Unlike the comment
    $delete = mysqli_query($connection, "
        DELETE FROM feed_interactions 
        WHERE user_id = $user_id AND post_id = $comment_id AND interaction_type = 'like'
    ");
    
    if ($delete) {
        // Decrease likes count
        mysqli_query($connection, "
            UPDATE feed_comments 
            SET likes_count = likes_count - 1 
            WHERE id = $comment_id
        ");
        
        echo json_encode([
            "code" => 200,
            "status" => "success",
            "message" => "Comment unliked successfully.",
            "data" => [
                "comment_id" => $comment_id,
                "is_liked" => false
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            "code" => 500,
            "status" => "error",
            "message" => "Failed to unlike comment."
        ]);
    }
} else {
    // Like the comment
    $insert = mysqli_query($connection, "
        INSERT INTO feed_interactions (user_id, post_id, interaction_type) 
        VALUES ($user_id, $comment_id, 'like')
    ");
    
    if ($insert) {
        // Increase likes count
        mysqli_query($connection, "
            UPDATE feed_comments 
            SET likes_count = likes_count + 1 
            WHERE id = $comment_id
        ");
        
        echo json_encode([
            "code" => 200,
            "status" => "success",
            "message" => "Comment liked successfully.",
            "data" => [
                "comment_id" => $comment_id,
                "is_liked" => true
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            "code" => 500,
            "status" => "error",
            "message" => "Failed to like comment."
        ]);
    }
}
?>
