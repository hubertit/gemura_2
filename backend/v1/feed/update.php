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

if (empty($data['token']) || empty($data['post_id'])) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'Token and post_id are required.'
    ]);
    exit;
}

$token = mysqli_real_escape_string($connection, trim($data['token']));
$post_id = (int)$data['post_id'];
$content = !empty($data['content']) ? trim($data['content']) : null;
$media_url = isset($data['media_url']) ? trim($data['media_url']) : null;
$hashtags = !empty($data['hashtags']) ? json_encode($data['hashtags']) : null;
$location = isset($data['location']) ? trim($data['location']) : null;

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
    echo json_encode([
        'code' => 404,
        'status' => 'error',
        'message' => 'Post not found or not owned by you.'
    ]);
    exit;
}

// Build update query dynamically
$updateFields = [];
$updateValues = [];

if ($content !== null) {
    $updateFields[] = "content = ?";
    $updateValues[] = $content;
}
if ($media_url !== null) {
    $updateFields[] = "media_url = ?";
    $updateValues[] = $media_url;
}
if ($hashtags !== null) {
    $updateFields[] = "hashtags = ?";
    $updateValues[] = $hashtags;
}
if ($location !== null) {
    $updateFields[] = "location = ?";
    $updateValues[] = $location;
}

if (empty($updateFields)) {
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'No fields to update.'
    ]);
    exit;
}

// Get current time in Africa/Kigali timezone
$kigali_time = (new DateTime('now', new DateTimeZone('Africa/Kigali')))->format('Y-m-d H:i:s');
$updateFields[] = "updated_at = '$kigali_time'";
$updateFields[] = "updated_by = ?";
$updateValues[] = $current_user_id;

$updateQuery = "UPDATE feed_posts SET " . implode(", ", $updateFields) . " WHERE id = $post_id";

$stmt = $connection->prepare($updateQuery);
if ($stmt) {
    $types = str_repeat('s', count($updateValues));
    $stmt->bind_param($types, ...$updateValues);
    
    if ($stmt->execute()) {
        echo json_encode([
            'code' => 200,
            'status' => 'success',
            'message' => 'Post updated successfully.',
            'data' => [
                'post_id' => $post_id,
                'updated_fields' => array_keys(array_filter([
                    'content' => $content,
                    'media_url' => $media_url,
                    'hashtags' => $data['hashtags'] ?? null,
                    'location' => $location
                ], function($value) { return $value !== null; }))
            ]
        ]);
    } else {
        echo json_encode([
            'code' => 500,
            'status' => 'error',
            'message' => 'Failed to update post.'
        ]);
    }
    $stmt->close();
} else {
    echo json_encode([
        'code' => 500,
        'status' => 'error',
        'message' => 'Failed to prepare update query.'
    ]);
}
?>
