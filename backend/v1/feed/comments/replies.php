<?php
require_once("../../configs/configs.php");
header('Content-Type: application/json');

$input_data = file_get_contents("php://input");
$data = json_decode($input_data, true);

// Validate token
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
$comment_id = (int)$data['comment_id'];
$limit = !empty($data['limit']) ? (int)$data['limit'] : 20;
$offset = !empty($data['offset']) ? (int)$data['offset'] : 0;

// Get current user
$userQuery = mysqli_query($connection, "
    SELECT u.id FROM users u
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

$currentUser = mysqli_fetch_assoc($userQuery);
$current_user_id = $currentUser['id'];

// Check if parent comment exists
$parentQuery = mysqli_query($connection, "
    SELECT id FROM feed_comments 
    WHERE id = $comment_id AND status = 'active'
    LIMIT 1
");

if (!$parentQuery || mysqli_num_rows($parentQuery) === 0) {
    http_response_code(404);
    echo json_encode([
        "code" => 404,
        "status" => "error",
        "message" => "Parent comment not found."
    ]);
    exit;
}

// Get replies for the comment
$query = mysqli_query($connection, "
    SELECT c.*, 
           u.name as user_name, u.profile_picture as user_avatar, u.account_type, u.kyc_status,
           CASE WHEN li.id IS NOT NULL THEN 1 ELSE 0 END as is_liked
    FROM feed_comments c
    JOIN users u ON c.user_id = u.id
    LEFT JOIN feed_interactions li ON c.id = li.post_id 
        AND li.user_id = $current_user_id AND li.interaction_type = 'like'
    WHERE c.parent_comment_id = $comment_id 
        AND c.status = 'active' 
        AND u.status = 'active'
    ORDER BY c.created_at ASC
    LIMIT $limit OFFSET $offset
");

$replies = [];
if ($query && mysqli_num_rows($query) > 0) {
    while ($row = mysqli_fetch_assoc($query)) {
        $replies[] = [
            "id" => $row['id'],
            "post_id" => $row['post_id'],
            "user_id" => $row['user_id'],
            "user_name" => $row['user_name'],
            "user_avatar" => $row['user_avatar'],
            "account_type" => $row['account_type'],
            "kyc_status" => $row['kyc_status'],
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
    "message" => "Comment replies fetched successfully.",
    "data" => $replies
]);
?>
