<?php
require_once("../configs/configs.php");
header('Content-Type: application/json');

$input_data = file_get_contents("php://input");
$data = json_decode($input_data, true);

// Validate token
if (empty($data['token'])) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Missing token."
    ]);
    exit;
}

$token = mysqli_real_escape_string($connection, $data['token']);
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

// Get user's bookmarked posts
$query = mysqli_query($connection, "
    SELECT p.*, 
           u.name as user_name,
           b.created_at as bookmarked_at,
           0 as is_liked,
           1 as is_bookmarked
    FROM user_bookmarks b
    JOIN feed_posts p ON b.post_id = p.id
    JOIN users u ON p.user_id = u.id
    WHERE b.user_id = $current_user_id 
        AND p.status = 'active'
        AND u.status = 'active'
    ORDER BY b.created_at DESC
    LIMIT $limit OFFSET $offset
");

$posts = [];
if ($query && mysqli_num_rows($query) > 0) {
    while ($row = mysqli_fetch_assoc($query)) {
        $posts[] = [
            "id" => $row['id'],
            "user_id" => $row['user_id'],
            "user_name" => $row['user_name'],
            "user_avatar" => $row['user_avatar'] ?? null,
            "account_type" => $row['account_type'] ?? null,
            "kyc_status" => $row['kyc_status'] ?? null,
            "content" => $row['content'],
            "media_url" => $row['media_url'],
            "hashtags" => $row['hashtags'] ? json_decode($row['hashtags'], true) : [],
            "location" => $row['location'],
            "likes_count" => $row['likes_count'],
            "shares_count" => $row['shares_count'],
            "bookmarks_count" => $row['bookmarks_count'],
            "is_liked" => (bool)$row['is_liked'],
            "is_bookmarked" => true,
            "bookmarked_at" => $row['bookmarked_at'],
            "status" => $row['status'],
            "created_at" => $row['created_at'],
            "updated_at" => $row['updated_at']
        ];
    }
}

echo json_encode([
    "code" => 200,
    "status" => "success",
    "message" => "Bookmarked posts fetched successfully.",
    "data" => $posts
]);
?>
