<?php
require_once("../configs/configs.php");
header('Content-Type: application/json');

// Add debugging
error_log("=== NOTIFICATIONS UPDATE DEBUG START ===");

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
$newStatus = isset($data['status']) ? $data['status'] : null;
$accountId = isset($data['account_id']) ? intval($data['account_id']) : $defaultAccountId;

// Validate status if provided
if ($newStatus && !in_array($newStatus, ['unread', 'read', 'archived', 'deleted'])) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Invalid status value"
    ]);
    exit;
}

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

// Update notification status
if ($newStatus) {
    $newStatus = mysqli_real_escape_string($connection, $newStatus);
    $updateQuery = "UPDATE notifications SET status = '$newStatus', updated_at = CURRENT_TIMESTAMP, updated_by = $userId WHERE id = $notificationId";
    
    error_log("DEBUG: Update Query: " . $updateQuery);
    
    if (mysqli_query($connection, $updateQuery)) {
        // Get updated notification
        $selectQuery = "SELECT id, user_id, account_id, title, message, type, category, action_url, action_data, expires_at, created_at, updated_at, status 
                       FROM notifications WHERE id = $notificationId";
        $result = mysqli_query($connection, $selectQuery);
        $updatedNotification = mysqli_fetch_assoc($result);
        
        // Decode JSON action_data
        if ($updatedNotification['action_data']) {
            $updatedNotification['action_data'] = json_decode($updatedNotification['action_data'], true);
        }
        
        echo json_encode([
            "code" => 200,
            "status" => "success",
            "message" => "Notification updated successfully",
            "data" => $updatedNotification
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            "code" => 500,
            "status" => "error",
            "message" => "Failed to update notification: " . mysqli_error($connection)
        ]);
    }
} else {
    // Return current notification data
    $selectQuery = "SELECT id, user_id, account_id, title, message, type, category, action_url, action_data, expires_at, created_at, updated_at, status 
                   FROM notifications WHERE id = $notificationId";
    $result = mysqli_query($connection, $selectQuery);
    $notificationData = mysqli_fetch_assoc($result);
    
    // Decode JSON action_data
    if ($notificationData['action_data']) {
        $notificationData['action_data'] = json_decode($notificationData['action_data'], true);
    }
    
    echo json_encode([
        "code" => 200,
        "status" => "success",
        "data" => $notificationData
    ]);
}

error_log("=== NOTIFICATIONS UPDATE DEBUG END ===");
?>
