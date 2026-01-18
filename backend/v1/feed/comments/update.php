<?php
require_once("../../configs/configs.php");
header('Content-Type: application/json');

$input_data = file_get_contents("php://input");
$data = json_decode($input_data, true);

// Validate JSON
if (json_last_error() !== JSON_ERROR_NONE) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'Invalid JSON format.'
    ]);
    exit;
}

if (empty($data['token']) || empty($data['comment_id']) || empty($data['content'])) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'Token, comment_id and content are required.'
    ]);
    exit;
}

$token = mysqli_real_escape_string($connection, trim($data['token']));
$comment_id = (int)$data['comment_id'];
$content = trim($data['content']);

// Get current user
$userQuery = mysqli_query($connection, "
    SELECT u.id FROM users u
    WHERE u.token = '$token' AND u.status = 'active' LIMIT 1
");

if (!$userQuery || mysqli_num_rows($userQuery) === 0) {
    echo json_encode([
        'code' => 403,
        'status' => 'error',
        'message' => 'Unauthorized. Invalid token.'
    ]);
    exit;
}

$user = mysqli_fetch_assoc($userQuery);
$current_user_id = $user['id'];

// Check if comment exists and belongs to user
$checkQuery = mysqli_query($connection, "
    SELECT * FROM feed_comments 
    WHERE id = $comment_id AND user_id = $current_user_id AND status = 'active'
    LIMIT 1
");

if (!$checkQuery || mysqli_num_rows($checkQuery) === 0) {
    echo json_encode([
        'code' => 404,
        'status' => 'error',
        'message' => 'Comment not found or not owned by you.'
    ]);
    exit;
}

// Update comment
$update = mysqli_query($connection, "
    UPDATE feed_comments 
    SET content = '$content', updated_at = NOW(), updated_by = $current_user_id
    WHERE id = $comment_id
");

if ($update && mysqli_affected_rows($connection) > 0) {
    echo json_encode([
        'code' => 200,
        'status' => 'success',
        'message' => 'Comment updated successfully.',
        'data' => [
            'comment_id' => $comment_id,
            'content' => $content
        ]
    ]);
} else {
    echo json_encode([
        'code' => 500,
        'status' => 'error',
        'message' => 'Failed to update comment.'
    ]);
}
?>
