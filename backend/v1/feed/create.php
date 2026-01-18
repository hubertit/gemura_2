<?php
require_once("../configs/configs.php");
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

// Validate required fields
if (empty($data['token']) || empty($data['content'])) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'Token and content are required.'
    ]);
    exit;
}

$token = mysqli_real_escape_string($connection, trim($data['token']));
$content = mysqli_real_escape_string($connection, trim($data['content']));
$media_url = !empty($data['media_url']) ? mysqli_real_escape_string($connection, trim($data['media_url'])) : null;
$hashtags = !empty($data['hashtags']) ? mysqli_real_escape_string($connection, json_encode($data['hashtags'])) : null;
$location = !empty($data['location']) ? mysqli_real_escape_string($connection, trim($data['location'])) : null;

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

// Insert post
// Get current time in Africa/Kigali timezone
$kigali_time = (new DateTime('now', new DateTimeZone('Africa/Kigali')))->format('Y-m-d H:i:s');

$insertQuery = "
    INSERT INTO feed_posts (user_id, content, media_url, hashtags, location, created_by, created_at, updated_at)
    VALUES (
        $user_id,
        '$content',
        " . ($media_url ? "'$media_url'" : "NULL") . ",
        " . ($hashtags ? "'$hashtags'" : "NULL") . ",
        " . ($location ? "'$location'" : "NULL") . ",
        $user_id,
        '$kigali_time',
        '$kigali_time'
    )
";

if (mysqli_query($connection, $insertQuery)) {
    $post_id = mysqli_insert_id($connection);
    echo json_encode([
        "code" => 201,
        "status" => "success",
        "message" => "Post created successfully.",
        "data" => [
            "post_id" => $post_id,
            "user_id" => $user_id,
            "content" => $content,
            "media_url" => $media_url,
            "hashtags" => $data['hashtags'] ?? [],
            "location" => $location,
            "likes_count" => 0,
            "shares_count" => 0,
            "bookmarks_count" => 0,
            "created_at" => $kigali_time
        ]
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        "code" => 500,
        "status" => "error",
        "message" => "Failed to create post.",
        "db_error" => mysqli_error($connection),
        "sql" => $insertQuery
    ]);
}
?>
