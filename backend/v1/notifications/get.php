<?php
require_once("../configs/configs.php");
header('Content-Type: application/json');

// Add debugging
error_log("=== NOTIFICATIONS GET DEBUG START ===");

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

// Get account_id from request, default to user's default account if not provided
$requestedAccountId = isset($data['account_id']) ? intval($data['account_id']) : $user['default_account_id'];

error_log("DEBUG: Requested Account ID: " . $requestedAccountId);
error_log("DEBUG: User ID: " . $userId);

// Check if user has access to the requested account
$userRoleQuery = mysqli_query($connection, "
    SELECT role FROM user_accounts 
    WHERE user_id = $userId AND account_id = $requestedAccountId AND status = 'active'
    LIMIT 1
");

if (!$userRoleQuery || mysqli_num_rows($userRoleQuery) === 0) {
    http_response_code(403);
    echo json_encode([
        "code" => 403,
        "status" => "error",
        "message" => "Unauthorized. No access to this account."
    ]);
    exit;
}

$userRole = mysqli_fetch_assoc($userRoleQuery)['role'];
error_log("DEBUG: User role: " . $userRole);

// Get query parameters for filtering
$status = isset($data['status']) ? $data['status'] : null;
$type = isset($data['type']) ? $data['type'] : null;
$category = isset($data['category']) ? $data['category'] : null;
$limit = isset($data['limit']) ? (int)$data['limit'] : 50;
$offset = isset($data['offset']) ? (int)$data['offset'] : 0;

// Build the query
$whereConditions = ["user_id = $userId", "account_id = $requestedAccountId", "status != 'deleted'"];

if ($status) {
    $status = mysqli_real_escape_string($connection, $status);
    $whereConditions[] = "status = '$status'";
}

if ($type) {
    $type = mysqli_real_escape_string($connection, $type);
    $whereConditions[] = "type = '$type'";
}

if ($category) {
    $category = mysqli_real_escape_string($connection, $category);
    $whereConditions[] = "category = '$category'";
}

$whereClause = implode(" AND ", $whereConditions);
$query = "SELECT id, user_id, account_id, title, message, type, category, action_url, action_data, expires_at, created_at, updated_at, status 
          FROM notifications 
          WHERE $whereClause
          ORDER BY created_at DESC LIMIT $limit OFFSET $offset";

error_log("DEBUG: Query: " . $query);

$result = mysqli_query($connection, $query);

$notifications = [];
if ($result && mysqli_num_rows($result) > 0) {
    while ($row = mysqli_fetch_assoc($result)) {
        // Decode JSON action_data
        if ($row['action_data']) {
            $row['action_data'] = json_decode($row['action_data'], true);
        }
        $notifications[] = $row;
    }
}

// Get total count for pagination
$countWhereConditions = ["user_id = $userId", "account_id = $requestedAccountId", "status != 'deleted'"];

if ($status) {
    $countWhereConditions[] = "status = '$status'";
}

if ($type) {
    $countWhereConditions[] = "type = '$type'";
}

if ($category) {
    $countWhereConditions[] = "category = '$category'";
}

$countWhereClause = implode(" AND ", $countWhereConditions);
$countQuery = "SELECT COUNT(*) as total FROM notifications WHERE $countWhereClause";

$countResult = mysqli_query($connection, $countQuery);
$totalCount = 0;
if ($countResult) {
    $totalCount = mysqli_fetch_assoc($countResult)['total'];
}

// Get unread count
$unreadQuery = "SELECT COUNT(*) as unread_count FROM notifications WHERE user_id = $userId AND account_id = $requestedAccountId AND status = 'unread'";
$unreadResult = mysqli_query($connection, $unreadQuery);
$unreadCount = 0;
if ($unreadResult) {
    $unreadCount = mysqli_fetch_assoc($unreadResult)['unread_count'];
}

echo json_encode([
    "code" => 200,
    "status" => "success",
    "message" => "Notifications retrieved successfully",
    "data" => [
        'notifications' => $notifications,
        'total_count' => (int)$totalCount,
        'unread_count' => (int)$unreadCount,
        'limit' => $limit,
        'offset' => $offset
    ]
]);

error_log("=== NOTIFICATIONS GET DEBUG END ===");
?>
