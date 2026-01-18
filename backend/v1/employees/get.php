<?php
require_once("../configs/configs.php");
header('Content-Type: application/json');

// Add debugging
error_log("=== EMPLOYEE GET DEBUG START ===");

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

error_log("DEBUG: User ID: " . $userId);
error_log("DEBUG: Default Account ID: " . $defaultAccountId);

// Check if user has access to their default account
$userRoleQuery = mysqli_query($connection, "
    SELECT role FROM user_accounts 
    WHERE user_id = $userId AND account_id = $defaultAccountId AND status = 'active'
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

// Fetch employees for the default account, latest first
$query = mysqli_query($connection, "
    SELECT ua.id as access_id, ua.role, ua.permissions, ua.status as access_status, ua.created_at as access_created_at,
           u.id as user_id, u.code as user_code, u.name, u.phone, u.email, u.nid, u.address,
           u.status as user_status, u.created_at as user_created_at
    FROM user_accounts ua
    JOIN users u ON ua.user_id = u.id
    WHERE ua.account_id = $defaultAccountId 
      AND ua.status = 'active'
      AND u.status = 'active'
    ORDER BY ua.created_at DESC
");

error_log("DEBUG: Query executed for account ID: " . $defaultAccountId);

$employees = [];
if ($query && mysqli_num_rows($query) > 0) {
    while ($row = mysqli_fetch_assoc($query)) {
        $permissions = json_decode($row['permissions'], true);
        if (!is_array($permissions)) {
            $permissions = [];
        }
        
        error_log("DEBUG: Employee " . $row['name'] . " - Role from DB: '" . $row['role'] . "'");
        error_log("DEBUG: Employee " . $row['name'] . " - Access ID: " . $row['access_id']);
        
        $employees[] = [
            "access_id" => $row['access_id'],
            "user_id" => $row['user_id'],
            "code" => $row['user_code'],
            "name" => $row['name'],
            "phone" => $row['phone'],
            "email" => $row['email'],
            "nid" => $row['nid'],
            "address" => $row['address'],
            "role" => $row['role'],
            "permissions" => $permissions,
            "status" => $row['access_status'],
            "user_status" => $row['user_status'],
            "created_at" => $row['access_created_at'],
            "user_created_at" => $row['user_created_at']
        ];
    }
}

error_log("DEBUG: Total employees found: " . count($employees));
error_log("=== EMPLOYEE GET DEBUG END ===");

echo json_encode([
    "code" => 200,
    "status" => "success",
    "message" => "Employees fetched successfully.",
    "data" => $employees
]);
?>
