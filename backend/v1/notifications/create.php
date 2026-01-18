<?php
require_once("../configs/configs.php");
header('Content-Type: application/json');

// Add debugging
error_log("=== NOTIFICATIONS CREATE DEBUG START ===");

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        "code" => 405,
        "status" => "error",
        "message" => "Method not allowed"
    ]);
    exit;
}

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

// Get logged in user
$userQuery = mysqli_query($connection, "
    SELECT u.id, u.default_account_id
    FROM users u
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
$userId = $user['id'];
$defaultAccountId = $user['default_account_id'];

// Validate required fields
if (!isset($data['title']) || !isset($data['message'])) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Title and message are required"
    ]);
    exit;
}

// Extract data
$title = mysqli_real_escape_string($connection, trim($data['title']));
$message = mysqli_real_escape_string($connection, trim($data['message']));
$type = isset($data['type']) ? mysqli_real_escape_string($connection, $data['type']) : 'info';
$category = isset($data['category']) ? mysqli_real_escape_string($connection, $data['category']) : 'general';
$actionUrl = isset($data['action_url']) ? mysqli_real_escape_string($connection, $data['action_url']) : null;
$actionData = isset($data['action_data']) ? mysqli_real_escape_string($connection, json_encode($data['action_data'])) : null;
$expiresAt = isset($data['expires_at']) ? mysqli_real_escape_string($connection, $data['expires_at']) : null;
$targetUserId = isset($data['user_id']) ? intval($data['user_id']) : $userId;
$targetAccountId = isset($data['account_id']) ? intval($data['account_id']) : $defaultAccountId;

// Validate title and message
if (empty($title) || strlen($title) > 255) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Title must be between 1 and 255 characters"
    ]);
    exit;
}

if (empty($message)) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Message cannot be empty"
    ]);
    exit;
}

// Validate type
$validTypes = ['info', 'success', 'warning', 'error', 'collection', 'sale', 'supplier', 'customer', 'payment', 'system'];
if (!in_array($type, $validTypes)) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Invalid notification type"
    ]);
    exit;
}

// Validate category
$validCategories = ['general', 'business', 'financial', 'reminder', 'alert', 'update'];
if (!in_array($category, $validCategories)) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Invalid notification category"
    ]);
    exit;
}

// Check if user has permission to create notifications for target user/account
if ($targetUserId !== $userId) {
    // Only allow if user is admin/owner
    $roleQuery = mysqli_query($connection, "
        SELECT role FROM user_accounts 
        WHERE user_id = $userId AND account_id = $targetAccountId AND status = 'active'
        LIMIT 1
    ");
    
    if (!$roleQuery || mysqli_num_rows($roleQuery) === 0 || !in_array(mysqli_fetch_assoc($roleQuery)['role'], ['admin', 'owner'])) {
        http_response_code(403);
        echo json_encode([
            "code" => 403,
            "status" => "error",
            "message" => "Insufficient permissions to create notifications for other users"
        ]);
        exit;
    }
}

// Check if target user has access to the target account
$targetQuery = mysqli_query($connection, "
    SELECT id FROM user_accounts 
    WHERE user_id = $targetUserId AND account_id = $targetAccountId AND status = 'active'
    LIMIT 1
");

if (!$targetQuery || mysqli_num_rows($targetQuery) === 0) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Target user does not have access to the specified account"
    ]);
    exit;
}

// Create notification
$insertQuery = "INSERT INTO notifications (user_id, account_id, title, message, type, category, action_url, action_data, expires_at, status, created_by) 
                VALUES ($targetUserId, $targetAccountId, '$title', '$message', '$type', '$category', " . 
                ($actionUrl ? "'$actionUrl'" : "NULL") . ", " . 
                ($actionData ? "'$actionData'" : "NULL") . ", " . 
                ($expiresAt ? "'$expiresAt'" : "NULL") . ", 'unread', $userId)";

error_log("DEBUG: Insert Query: " . $insertQuery);

if (mysqli_query($connection, $insertQuery)) {
    $notificationId = mysqli_insert_id($connection);
    
    // Get the created notification
    $selectQuery = "SELECT id, user_id, account_id, title, message, type, category, action_url, action_data, expires_at, created_at, updated_at, status 
                    FROM notifications WHERE id = $notificationId";
    $result = mysqli_query($connection, $selectQuery);
    $notification = mysqli_fetch_assoc($result);
    
    // Decode JSON action_data
    if ($notification['action_data']) {
        $notification['action_data'] = json_decode($notification['action_data'], true);
    }
    
    echo json_encode([
        "code" => 200,
        "status" => "success",
        "message" => "Notification created successfully",
        "data" => $notification
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        "code" => 500,
        "status" => "error",
        "message" => "Failed to create notification: " . mysqli_error($connection)
    ]);
}

error_log("=== NOTIFICATIONS CREATE DEBUG END ===");
?>
