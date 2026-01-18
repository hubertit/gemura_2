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

if (!$userQuery || mysqli_num_rows($userQuery) == 0) {
    http_response_code(401);
    echo json_encode([
        "code" => 401,
        "status" => "error",
        "message" => "Unauthorized. Invalid token."
    ]);
    exit;
}

$user = mysqli_fetch_assoc($userQuery);
$userId = $user['id'];

// Get liked posts for the user
$likedPostsQuery = mysqli_query($connection, "
    SELECT 
        p.id,
        p.user_id,
        p.content,
        p.media_url,
        p.hashtags,
        p.location,
        p.likes_count,
        p.shares_count,
        p.bookmarks_count,
        p.created_at,
        p.updated_at,
        u.name AS user_name,
        u.account_type,
        u.kyc_status,
        1 AS is_liked,
        CASE WHEN ub.id IS NOT NULL THEN 1 ELSE 0 END AS is_bookmarked,
        (SELECT COUNT(*) FROM feed_comments WHERE post_id = p.id AND status = 'active') AS comments_count
    FROM feed_interactions fi
    INNER JOIN feed_posts p ON p.id = fi.post_id
    INNER JOIN users u ON u.id = p.user_id
    LEFT JOIN user_bookmarks ub ON ub.post_id = p.id AND ub.user_id = '$userId'
    WHERE fi.user_id = '$userId' 
    AND fi.interaction_type = 'like'
    AND p.status = 'active'
    AND u.status = 'active'
    ORDER BY fi.created_at DESC
    LIMIT $limit OFFSET $offset
");

if (!$likedPostsQuery) {
    http_response_code(500);
    echo json_encode([
        "code" => 500,
        "status" => "error",
        "message" => "Database error: " . mysqli_error($connection)
    ]);
    exit;
}

$likedPosts = [];
while ($post = mysqli_fetch_assoc($likedPostsQuery)) {
    // Parse hashtags if they exist
    $hashtags = [];
    if (!empty($post['hashtags'])) {
        $hashtags = json_decode($post['hashtags'], true) ?? [];
    }
    
    $likedPosts[] = [
        'id' => $post['id'],
        'user_id' => $post['user_id'],
        'user_name' => $post['user_name'] ?? null,
        'user_avatar' => null, // No avatar field in users table
        'account_type' => $post['account_type'] ?? null,
        'kyc_status' => $post['kyc_status'] ?? null,
        'content' => $post['content'],
        'media_url' => $post['media_url'],
        'hashtags' => $hashtags,
        'location' => $post['location'],
        'likes_count' => $post['likes_count'],
        'comments_count' => $post['comments_count'],
        'shares_count' => $post['shares_count'],
        'bookmarks_count' => $post['bookmarks_count'],
        'created_at' => $post['created_at'],
        'updated_at' => $post['updated_at'],
        'is_liked' => (bool)$post['is_liked'],
        'is_bookmarked' => (bool)$post['is_bookmarked']
    ];
}

// Get total count for pagination
$countQuery = mysqli_query($connection, "
    SELECT COUNT(*) as total
    FROM feed_interactions fi
    INNER JOIN feed_posts p ON p.id = fi.post_id
    INNER JOIN users u ON u.id = p.user_id
    WHERE fi.user_id = '$userId' 
    AND fi.interaction_type = 'like'
    AND p.status = 'active'
    AND u.status = 'active'
");

$totalCount = 0;
if ($countQuery) {
    $countResult = mysqli_fetch_assoc($countQuery);
    $totalCount = $countResult['total'];
}

http_response_code(200);
echo json_encode([
    "code" => 200,
    "status" => "success",
    "message" => "Liked posts retrieved successfully.",
    "data" => $likedPosts,
    "pagination" => [
        "total" => $totalCount,
        "limit" => $limit,
        "offset" => $offset,
        "has_more" => ($offset + $limit) < $totalCount
    ]
]);
?>
