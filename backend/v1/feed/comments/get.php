<?php
require_once("../../configs/configs.php");
header('Content-Type: application/json');

$input_data = file_get_contents("php://input");
$data = json_decode($input_data, true);

// Validate token
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
$post_id = (int)$data['post_id'];
$limit = !empty($data['limit']) ? (int)$data['limit'] : 20;
$offset = !empty($data['offset']) ? (int)$data['offset'] : 0;

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

// Get comments for the post
$query = mysqli_query($connection, "
    SELECT c.*, 
           u.name as user_name,
           0 as is_liked
    FROM feed_comments c
    JOIN users u ON c.user_id = u.id
    WHERE c.post_id = $post_id 
        AND c.status = 'active'
        AND u.status = 'active'
    ORDER BY c.created_at ASC
    LIMIT $limit OFFSET $offset
");

$comments = [];
if ($query && mysqli_num_rows($query) > 0) {
    while ($row = mysqli_fetch_assoc($query)) {
        $comments[] = [
            "id" => $row['id'],
            "post_id" => $row['post_id'],
            "user_id" => $row['user_id'],
            "user_name" => $row['user_name'],
            "user_avatar" => $row['user_avatar'] ?? null,
            "account_type" => $row['account_type'] ?? null,
            "kyc_status" => $row['kyc_status'] ?? null,
            "content" => $row['content'],
            "parent_comment_id" => $row['parent_comment_id'],
            "likes_count" => $row['likes_count'],
            "is_liked" => (bool)$row['is_liked'],
            "status" => $row['status'],
            "created_at" => $row['created_at'],
            "updated_at" => $row['updated_at']
        ];
    }
}

echo json_encode([
    "code" => 200,
    "status" => "success",
    "message" => "Comments fetched successfully.",
    "data" => $comments
]);
?>
