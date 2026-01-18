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
    empty($data['access_id']) ||
    empty($data['role']) ||
    empty($data['permissions'])
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
$role = mysqli_real_escape_string($connection, trim($data['role']));

// Normalize permissions: convert array format to object format for consistency
$permissionsInput = $data['permissions'];
$normalizedPermissions = null;

if (!empty($permissionsInput)) {
    if (is_array($permissionsInput)) {
        // If it's an array of permission strings, convert to object format
        // e.g., ["view_sales", "create_sales"] -> {"view_sales": true, "create_sales": true}
        $normalizedPermissions = [];
        foreach ($permissionsInput as $perm) {
            if (is_string($perm)) {
                $normalizedPermissions[$perm] = true;
            } elseif (is_array($perm) && isset($perm[0])) {
                // Handle nested arrays
                $normalizedPermissions[$perm[0]] = true;
            }
        }
    } elseif (is_object($permissionsInput) || (is_array($permissionsInput) && !isset($permissionsInput[0]))) {
        // If it's already an object/associative array, use as-is
        $normalizedPermissions = $permissionsInput;
    }
}

$permissions = $normalizedPermissions ? json_encode($normalizedPermissions) : null;

/** -------------------------------
 * 1. Validate the requesting user (manager/admin)
 */
$managerQuery = mysqli_query($connection, "
    SELECT u.id as user_id, u.default_account_id as account_id, a.name AS account_name
    FROM users u 
    LEFT JOIN accounts a ON a.id = u.default_account_id 
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
$managerAccountId = $manager['account_id'];

// Check if manager has admin/manager role
$managerRoleQuery = mysqli_query($connection, "
    SELECT role FROM user_accounts 
    WHERE user_id = {$manager['user_id']} AND account_id = $managerAccountId AND status = 'active'
    LIMIT 1
");

if (!$managerRoleQuery || mysqli_num_rows($managerRoleQuery) === 0) {
    http_response_code(403);
    echo json_encode([
        'code' => 403,
        'status' => 'error',
        'message' => 'Unauthorized. Only managers and admins can update employee access.'
    ]);
    exit;
}

$managerRole = mysqli_fetch_assoc($managerRoleQuery)['role'];
if (!in_array($managerRole, ['admin', 'manager', 'owner'])) {
    http_response_code(403);
    echo json_encode([
        'code' => 403,
        'status' => 'error',
        'message' => 'Unauthorized. Only owners, managers and admins can update employee access.'
    ]);
    exit;
}

/** -------------------------------
 * 2. Validate employee exists and belongs to the same account
 */
$employeeQuery = mysqli_query($connection, "
    SELECT ua.id as access_id, ua.user_id, ua.account_id, ua.role as current_role,
           u.name, u.phone, u.email
    FROM user_accounts ua
    JOIN users u ON ua.user_id = u.id
    WHERE ua.id = '$accessId' 
      AND ua.account_id = $managerAccountId 
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

// Prevent managers from updating admin roles (only admins and owners can do this)
if ($employee['current_role'] === 'admin' && !in_array($managerRole, ['admin', 'owner'])) {
    http_response_code(403);
    echo json_encode([
        'code' => 403,
        'status' => 'error',
        'message' => 'Unauthorized. Only admins and owners can update admin roles.'
    ]);
    exit;
}

// Prevent users from updating their own role
if ($employee['user_id'] == $manager['user_id']) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'You cannot update your own role.'
    ]);
    exit;
}

/** -------------------------------
 * 3. Update employee access
 */
$updateQuery = mysqli_query($connection, "
    UPDATE user_accounts 
    SET role = '$role', permissions = " . ($permissions ? "'$permissions'" : "NULL") . ", updated_at = NOW()
    WHERE id = {$employee['access_id']}
");

if (!$updateQuery) {
    http_response_code(500);
    echo json_encode([
        'code' => 500,
        'status' => 'error',
        'message' => 'Failed to update employee access: ' . mysqli_error($connection)
    ]);
    exit;
}

// Fetch what was actually stored in database
$storedPermissions = $normalizedPermissions; // Default to normalized version
$verifyQuery = mysqli_query($connection, "
    SELECT permissions FROM user_accounts 
    WHERE id = {$employee['access_id']}
    LIMIT 1
");

if ($verifyQuery && mysqli_num_rows($verifyQuery) > 0) {
    $verifyData = mysqli_fetch_assoc($verifyQuery);
    // Return what was actually stored in database
    $storedPermissions = $verifyData['permissions'] ? json_decode($verifyData['permissions'], true) : null;
}

/** -------------------------------
 * 4. Return success response
 */
echo json_encode([
    'code' => 200,
    'status' => 'success',
    'message' => 'Employee access updated successfully.',
    'data' => [
        'employee_id' => $employee['user_id'],
        'name' => $employee['name'],
        'phone' => $employee['phone'],
        'email' => $employee['email'],
        'old_role' => $employee['current_role'],
        'new_role' => $role,
        'permissions' => $storedPermissions
    ]
]);
?>
