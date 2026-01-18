<?php
require_once("../configs/configs.php");
header('Content-Type: application/json');

// Add debugging
error_log("=== NOTIFICATIONS DELETE DEBUG START ===");

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
if (!isset($data['notification_id'])) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Notification ID is required"
    ]);
    exit;
}

$notificationId = (int)$data['notification_id'];
$accountId = isset($data['account_id']) ? intval($data['account_id']) : $defaultAccountId;

// Check if notification exists and belongs to user
$notificationQuery = mysqli_query($connection, "
    SELECT id, user_id, account_id, status 
    FROM notifications 
    WHERE id = $notificationId AND user_id = $userId AND account_id = $accountId AND status != 'deleted'
    LIMIT 1
");

if (!$notificationQuery || mysqli_num_rows($notificationQuery) === 0) {
    http_response_code(404);
    echo json_encode([
        "code" => 404,
        "status" => "error",
        "message" => "Notification not found or not accessible"
    ]);
    exit;
}

$notification = mysqli_fetch_assoc($notificationQuery);

// Soft delete notification (change status to 'deleted')
$deleteQuery = "UPDATE notifications SET status = 'deleted', updated_at = CURRENT_TIMESTAMP WHERE id = $notificationId";

error_log("DEBUG: Delete Query: " . $deleteQuery);

if (mysqli_query($connection, $deleteQuery)) {
    echo json_encode([
        "code" => 200,
        "status" => "success",
        "message" => "Notification deleted successfully"
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        "code" => 500,
        "status" => "error",
        "message" => "Failed to delete notification: " . mysqli_error($connection)
    ]);
}

error_log("=== NOTIFICATIONS DELETE DEBUG END ===");
?>
