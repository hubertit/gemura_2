<?php
require_once("../configs/configs.php");
header('Content-Type: application/json');

$input_data = file_get_contents("php://input");
$data = json_decode($input_data, true);

// Validate input
if (empty($data['token']) || empty($data['post_id'])) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Token and post_id are required."
    ]);
    exit;
}

$token = mysqli_real_escape_string($connection, $data['token']);
$post_id = intval($data['post_id']);

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

// Check if post exists
$postQuery = mysqli_query($connection, "
    SELECT id FROM feed_posts 
    WHERE id = $post_id AND status = 'active'
    LIMIT 1
");

if (!$postQuery || mysqli_num_rows($postQuery) === 0) {
    http_response_code(404);
    echo json_encode([
        "code" => 404,
        "status" => "error",
        "message" => "Post not found."
    ]);
    exit;
}

// Check if already bookmarked
$bookmarkQuery = mysqli_query($connection, "
    SELECT id FROM user_bookmarks 
    WHERE user_id = $user_id AND post_id = $post_id
    LIMIT 1
");

if (mysqli_num_rows($bookmarkQuery) > 0) {
    // Remove bookmark
    $delete = mysqli_query($connection, "
        DELETE FROM user_bookmarks 
        WHERE user_id = $user_id AND post_id = $post_id
    ");
    
    if ($delete) {
        // Decrease bookmarks count
        mysqli_query($connection, "
            UPDATE feed_posts 
            SET bookmarks_count = bookmarks_count - 1 
            WHERE id = $post_id
        ");
        
        echo json_encode([
            "code" => 200,
            "status" => "success",
            "message" => "Post bookmark removed successfully.",
            "data" => [
                "post_id" => $post_id,
                "is_bookmarked" => false
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            "code" => 500,
            "status" => "error",
            "message" => "Failed to remove bookmark."
        ]);
    }
} else {
    // Add bookmark
    $insert = mysqli_query($connection, "
        INSERT INTO user_bookmarks (user_id, post_id) 
        VALUES ($user_id, $post_id)
    ");
    
    if ($insert) {
        // Increase bookmarks count
        mysqli_query($connection, "
            UPDATE feed_posts 
            SET bookmarks_count = bookmarks_count + 1 
            WHERE id = $post_id
        ");
        
        echo json_encode([
            "code" => 200,
            "status" => "success",
            "message" => "Post bookmarked successfully.",
            "data" => [
                "post_id" => $post_id,
                "is_bookmarked" => true
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            "code" => 500,
            "status" => "error",
            "message" => "Failed to bookmark post."
        ]);
    }
}
?>
