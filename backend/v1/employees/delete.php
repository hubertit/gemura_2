<?php
require_once("../configs/configs.php");

$input_data = file_get_contents("php://input");
$data = json_decode($input_data, true);

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
if (
    empty($data['token']) ||
    empty($data['access_id'])
) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'Missing required fields.'
    ]);
    exit;
}

$token = mysqli_real_escape_string($connection, trim($data['token']));
$accessId = mysqli_real_escape_string($connection, trim($data['access_id']));

/** -------------------------------
 * 1. Validate the requesting user (manager/admin)
 */
$managerQuery = mysqli_query($connection, "
    SELECT u.id as user_id
    FROM users u 
    WHERE u.token = '$token' AND u.status = 'active' LIMIT 1
");

if (!$managerQuery || mysqli_num_rows($managerQuery) === 0) {
    http_response_code(403);
    echo json_encode([
        'code' => 403,
        'status' => 'error',
        'message' => 'Unauthorized. Invalid token.'
    ]);
    exit;
}

$manager = mysqli_fetch_assoc($managerQuery);
$managerUserId = $manager['user_id'];

/** -------------------------------
 * 2. Validate employee exists and get account info
 */
$employeeQuery = mysqli_query($connection, "
    SELECT ua.id as access_id, ua.user_id, ua.account_id, ua.role as current_role,
           u.name, u.phone, u.email
    FROM user_accounts ua
    JOIN users u ON ua.user_id = u.id
    WHERE ua.id = '$accessId' 
      AND ua.status = 'active'
      AND u.status = 'active'
    LIMIT 1
");

if (!$employeeQuery || mysqli_num_rows($employeeQuery) === 0) {
    http_response_code(404);
    echo json_encode([
        'code' => 404,
        'status' => 'error',
        'message' => 'Employee not found or not accessible.'
    ]);
    exit;
}

$employee = mysqli_fetch_assoc($employeeQuery);
$employeeAccountId = $employee['account_id'];

// Add debugging
error_log("=== EMPLOYEE DELETE DEBUG ===");
error_log("Access ID: " . $accessId);
error_log("Employee Account ID: " . $employeeAccountId);
error_log("Manager User ID: " . $managerUserId);
error_log("Employee User ID: " . $employee['user_id']);
error_log("Employee Name: " . $employee['name']);

/** -------------------------------
 * 3. Check if manager has access to the employee's account
 */
$managerRoleQuery = mysqli_query($connection, "
    SELECT role FROM user_accounts 
    WHERE user_id = $managerUserId AND account_id = $employeeAccountId AND status = 'active'
    LIMIT 1
");

if (!$managerRoleQuery || mysqli_num_rows($managerRoleQuery) === 0) {
    http_response_code(403);
    echo json_encode([
        'code' => 403,
        'status' => 'error',
        'message' => 'Unauthorized. You do not have access to this account.'
    ]);
    exit;
}

$managerRole = mysqli_fetch_assoc($managerRoleQuery)['role'];
if (!in_array($managerRole, ['admin', 'manager', 'owner'])) {
    http_response_code(403);
    echo json_encode([
        'code' => 403,
        'status' => 'error',
        'message' => 'Unauthorized. Only owners, managers and admins can revoke employee access.'
    ]);
    exit;
}

// Prevent managers from revoking admin access (only admins and owners can do this)
if ($employee['current_role'] === 'admin' && !in_array($managerRole, ['admin', 'owner'])) {
    http_response_code(403);
    echo json_encode([
        'code' => 403,
        'status' => 'error',
        'message' => 'Unauthorized. Only admins and owners can revoke admin access.'
    ]);
    exit;
}

// Prevent users from revoking their own access
if ($employee['user_id'] == $manager['user_id']) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'You cannot revoke your own access.'
    ]);
    exit;
}

/** -------------------------------
 * 3. Revoke employee access (change status to inactive)
 */
$revokeQuery = mysqli_query($connection, "
    UPDATE user_accounts 
    SET status = 'inactive', updated_at = NOW()
    WHERE id = {$employee['access_id']}
");

if (!$revokeQuery) {
    http_response_code(500);
    echo json_encode([
        'code' => 500,
        'status' => 'error',
        'message' => 'Failed to revoke employee access: ' . mysqli_error($connection)
    ]);
    exit;
}

/** -------------------------------
 * 4. Return success response
 */
echo json_encode([
    'code' => 200,
    'status' => 'success',
    'message' => 'Employee access revoked successfully.',
    'data' => [
        'employee_id' => $employee['user_id'],
        'name' => $employee['name'],
        'phone' => $employee['phone'],
        'email' => $employee['email'],
        'role' => $employee['current_role'],
        'status' => 'inactive'
    ]
]);
?>
