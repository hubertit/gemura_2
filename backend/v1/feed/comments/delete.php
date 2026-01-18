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
$current_user_id = $user['id'];

// Check if comment exists and belongs to user
$checkQuery = mysqli_query($connection, "
    SELECT post_id FROM feed_comments 
    WHERE id = $comment_id AND user_id = $current_user_id AND status = 'active'
    LIMIT 1
");

if (!$checkQuery || mysqli_num_rows($checkQuery) === 0) {
    http_response_code(404);
    echo json_encode([
        "code" => 404,
        "status" => "error",
        "message" => "Comment not found or not owned by you."
    ]);
    exit;
}

$comment = mysqli_fetch_assoc($checkQuery);
$post_id = $comment['post_id'];

// Soft delete comment (set status to 'deleted')
$update = mysqli_query($connection, "
    UPDATE feed_comments 
    SET status = 'deleted', updated_at = NOW(), updated_by = $current_user_id
    WHERE id = $comment_id
");

if ($update && mysqli_affected_rows($connection) > 0) {
    // Decrease post comments count
    mysqli_query($connection, "
        UPDATE feed_posts 
        SET comments_count = comments_count - 1 
        WHERE id = $post_id
    ");
    
    echo json_encode([
        "code" => 200,
        "status" => "success",
        "message" => "Comment deleted successfully."
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        "code" => 500,
        "status" => "error",
        "message" => "Failed to delete comment."
    ]);
}
?>
