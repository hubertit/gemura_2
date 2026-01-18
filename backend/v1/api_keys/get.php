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

// Check if user has permission to view API keys (admin, owner, or manager)
// Get user's highest role across all accounts
$userRoleQuery = mysqli_query($connection, "
    SELECT role FROM user_accounts 
    WHERE user_id = $userId AND status = 'active'
    ORDER BY FIELD(role, 'owner', 'admin', 'manager', 'collector', 'supplier', 'customer')
    LIMIT 1
");

if (!$userRoleQuery || mysqli_num_rows($userRoleQuery) === 0) {
    http_response_code(403);
    echo json_encode([
        "code" => 403,
        "status" => "error",
        "message" => "Unauthorized. No active account access found."
    ]);
    exit;
}

$userRole = mysqli_fetch_assoc($userRoleQuery)['role'];

// Check if user has permission to view API keys (admin, owner, or manager)
if (!in_array($userRole, ['admin', 'owner', 'manager'])) {
    http_response_code(403);
    echo json_encode([
        "code" => 403,
        "status" => "error",
        "message" => "Unauthorized. Only admins, owners, and managers can view API keys."
    ]);
    exit;
}

// Fetch all API keys (universal across the app)
$query = mysqli_query($connection, "
    SELECT id, key_name, key_type, key_value, is_active, created_at, updated_at
    FROM api_keys 
    WHERE status = 'active'
    ORDER BY created_at DESC
");

$apiKeys = [];
if ($query && mysqli_num_rows($query) > 0) {
    while ($row = mysqli_fetch_assoc($query)) {
        // Mask the key value for security (show only first 4 and last 4 characters)
        $keyValue = $row['key_value'];
        $maskedValue = '';
        if (strlen($keyValue) > 8) {
            $maskedValue = substr($keyValue, 0, 4) . str_repeat('*', strlen($keyValue) - 8) . substr($keyValue, -4);
        } else {
            $maskedValue = str_repeat('*', strlen($keyValue));
        }
        
        $apiKeys[] = [
            "id" => intval($row['id']),
            "key_name" => $row['key_name'],
            "key_type" => $row['key_type'],
            "key_value" => $maskedValue,
            "is_active" => (bool)$row['is_active'],
            "created_at" => $row['created_at'],
            "updated_at" => $row['updated_at']
        ];
    }
}

echo json_encode([
    "code" => 200,
    "status" => "success",
    "message" => "API keys fetched successfully.",
    "data" => [
        "api_keys" => $apiKeys,
        "total_keys" => count($apiKeys)
    ]
]);
?>
