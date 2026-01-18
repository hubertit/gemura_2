<?php
require_once("../../configs/configs.php");
header('Content-Type: application/json');

$input_data = file_get_contents("php://input");
$data = json_decode($input_data, true);

// Validate JSON
if (json_last_error() !== JSON_ERROR_NONE) {
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'Invalid JSON format.'
    ]);
    exit;
}

// Validate required fields
if (empty($data['token']) || empty($data['post_id']) || empty($data['content'])) {
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'Token, post_id and content are required.'
    ]);
    exit;
}

$token = trim($data['token']);
$post_id = (int)$data['post_id'];
$content = trim($data['content']);
$parent_comment_id = !empty($data['parent_comment_id']) ? (int)$data['parent_comment_id'] : null;

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
$user_id = $user['id'];

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

// If parent comment is provided, check if it exists
if ($parent_comment_id) {
    $parentQuery = mysqli_query($connection, "
        SELECT id FROM feed_comments 
        WHERE id = $parent_comment_id AND post_id = $post_id AND status = 'active'
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
}

// Insert comment
$content = mysqli_real_escape_string($connection, $content);

// Get current time in Africa/Kigali timezone
$kigali_time = (new DateTime('now', new DateTimeZone('Africa/Kigali')))->format('Y-m-d H:i:s');

$insertQuery = "
    INSERT INTO feed_comments (post_id, user_id, content, parent_comment_id, created_by, created_at, updated_at)
    VALUES (
        $post_id,
        $user_id,
        '$content',
        " . ($parent_comment_id ? $parent_comment_id : "NULL") . ",
        $user_id,
        '$kigali_time',
        '$kigali_time'
    )
";

if (mysqli_query($connection, $insertQuery)) {
    $comment_id = mysqli_insert_id($connection);
    
    // Update post comments count
    mysqli_query($connection, "
        UPDATE feed_posts 
        SET comments_count = comments_count + 1 
        WHERE id = $post_id
    ");
    
    echo json_encode([
        "code" => 201,
        "status" => "success",
        "message" => "Comment created successfully.",
        "data" => [
            "comment_id" => $comment_id,
            "post_id" => $post_id,
            "user_id" => $user_id,
            "content" => $content,
            "parent_comment_id" => $parent_comment_id,
            "likes_count" => 0,
            "is_liked" => false,
            "created_at" => $kigali_time
        ]
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        "code" => 500,
        "status" => "error",
        "message" => "Failed to create comment.",
        "db_error" => mysqli_error($connection),
        "sql" => $insertQuery
    ]);
}
?>
