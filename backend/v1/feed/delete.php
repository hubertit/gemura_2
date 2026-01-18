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

// Get logged in user with default account only
$userQuery = mysqli_query($connection, "
    SELECT u.id, u.default_account_id AS account_id, a.name AS account_name
    FROM users u
    LEFT JOIN accounts a ON a.id = u.default_account_id
    WHERE u.token = '$token' AND u.status = 'active'
    LIMIT 1
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

// Check if user has a valid default account
if (!$user['account_id'] || !$user['account_name']) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "No valid default account found. Please set a default account."
    ]);
    exit;
}

// Check if post exists and belongs to user
$checkQuery = mysqli_query($connection, "
    SELECT * FROM feed_posts 
    WHERE id = $post_id AND user_id = $current_user_id AND status = 'active'
    LIMIT 1
");

if (!$checkQuery || mysqli_num_rows($checkQuery) === 0) {
    http_response_code(404);
    echo json_encode([
        "code" => 404,
        "status" => "error",
        "message" => "Post not found or not owned by you."
    ]);
    exit;
}

// Soft delete post (set status to 'deleted')
$update = mysqli_query($connection, "
    UPDATE feed_posts 
    SET status = 'deleted', updated_at = NOW(), updated_by = $current_user_id
    WHERE id = $post_id
");

if ($update && mysqli_affected_rows($connection) > 0) {
    echo json_encode([
        "code" => 200,
        "status" => "success",
        "message" => "Post deleted successfully."
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        "code" => 500,
        "status" => "error",
        "message" => "Failed to delete post."
    ]);
}
?>
