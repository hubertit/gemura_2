<?php
require_once("../configs/configs.php");
header('Content-Type: application/json');

$input_data = file_get_contents("php://input");
$data = json_decode($input_data, true);

$token = mysqli_real_escape_string($connection, trim($data['token']));

// Get logged in user with default account only
$userQuery = mysqli_query($connection, "
    SELECT u.id, u.default_account_id AS account_id, a.name AS account_name
    FROM users u
    LEFT JOIN accounts a ON a.id = u.default_account_id
    WHERE u.token = '$token' AND u.status = 'active'
    LIMIT 1
");

$user = mysqli_fetch_assoc($userQuery);
$current_user_id = $user['id'];

// Check if posts exist
$postsQuery = mysqli_query($connection, "
    SELECT COUNT(*) as total FROM feed_posts WHERE status = 'active'
");

$postsCount = mysqli_fetch_assoc($postsQuery);

// Get all posts
$allPostsQuery = mysqli_query($connection, "
    SELECT p.*, u.name as user_name
    FROM feed_posts p
    JOIN users u ON p.user_id = u.id
    WHERE p.status = 'active' 
    ORDER BY p.created_at DESC
");

$posts = [];
if ($allPostsQuery && mysqli_num_rows($allPostsQuery) > 0) {
    while ($row = mysqli_fetch_assoc($allPostsQuery)) {
        $posts[] = $row;
    }
}

echo json_encode([
    "code" => 200,
    "status" => "success",
    "message" => "Debug info.",
    "data" => [
        "user_id" => $current_user_id,
        "total_posts" => $postsCount['total'],
        "posts" => $posts,
        "user_query_result" => $user
    ]
]);
?>
