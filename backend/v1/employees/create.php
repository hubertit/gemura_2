<?php
require_once("../configs/configs.php");

// Add debugging
error_log("=== EMPLOYEE CREATE DEBUG START ===");

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
    empty($data['user_data']['name']) ||
    empty($data['user_data']['phone']) ||
    empty($data['account_access']['role']) ||
    empty($data['account_access']['permissions'])
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
$userData = $data['user_data'];
$accountAccess = $data['account_access'];

$name = mysqli_real_escape_string($connection, trim($userData['name']));
$phone = preg_replace('/[^0-9]/', '', $userData['phone']);
$phone = mysqli_real_escape_string($connection, $phone);
$email = !empty($userData['email']) ? mysqli_real_escape_string($connection, trim($userData['email'])) : null;
$nid = !empty($userData['nid']) ? mysqli_real_escape_string($connection, trim($userData['nid'])) : null;

// Validate NID format if provided
if (!empty($nid) && !preg_match('/^11\d{14}$/', $nid)) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'NID must be 16 digits starting with 11.'
    ]);
    exit;
}

$role = mysqli_real_escape_string($connection, trim($accountAccess['role']));

// Normalize permissions: convert array format to object format for consistency
$permissionsInput = $accountAccess['permissions'];
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
    } elseif (is_object($permissionsInput) || is_array($permissionsInput)) {
        // If it's already an object/associative array, use as-is
        $normalizedPermissions = $permissionsInput;
    }
}

$permissions = $normalizedPermissions ? json_encode($normalizedPermissions) : null;
$setAsDefault = isset($accountAccess['set_as_default']) ? (bool)$accountAccess['set_as_default'] : false;

// Debug role value
error_log("DEBUG: Role received: " . $role);
error_log("DEBUG: Role after escape: " . $role);
error_log("DEBUG: Permissions: " . $permissions);

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
$accountId = $manager['account_id']; // Use default account from token
$currentUserId = $manager['user_id'];

error_log("DEBUG: Account ID: " . $accountId);

// TEMPORARILY COMMENTED OUT FOR TESTING
/*
// Check if manager has permission to add employees to this account
if ($managerAccountId != $accountId) {
    http_response_code(403);
    echo json_encode([
        'code' => 403,
        'status' => 'error',
        'message' => 'Unauthorized. You can only add employees to your own account.'
    ]);
    exit;
}
*/

// TEMPORARILY COMMENTED OUT FOR TESTING
/*
// Check if manager has admin/manager role
$managerRoleQuery = mysqli_query($connection, "
    SELECT role FROM user_accounts 
    WHERE user_id = {$manager['user_id']} AND account_id = $accountId AND status = 'active'
    LIMIT 1
");

if (!$managerRoleQuery || mysqli_num_rows($managerRoleQuery) === 0) {
    http_response_code(403);
    echo json_encode([
        'code' => 403,
        'status' => 'error',
        'message' => 'Unauthorized. Only managers and admins can add employees.'
    ]);
    exit;
}

$managerRole = mysqli_fetch_assoc($managerRoleQuery)['role'];
if (!in_array($managerRole, ['admin', 'manager', 'owner'])) {
    http_response_code(403);
    echo json_encode([
        'code' => 403,
        'status' => 'error',
        'message' => 'Unauthorized. Only owners, managers and admins can add employees.'
    ]);
    exit;
}
*/

/** -------------------------------
 * 2. Check if user already exists (by phone or email)
 */
$existingUserQuery = mysqli_query($connection, "
    SELECT id, code, name, phone, email, nid, token, status 
    FROM users 
    WHERE (phone = '$phone' " . ($email ? "OR email = '$email'" : "") . ") 
    AND status = 'active' 
    LIMIT 1
");

$employeeUserId = null;
$userCode = null;
$employeeToken = null;

if ($existingUserQuery && mysqli_num_rows($existingUserQuery) > 0) {
    // User already exists, use existing user
    $existingUser = mysqli_fetch_assoc($existingUserQuery);
    $employeeUserId = $existingUser['id'];
    $userCode = $existingUser['code'];
    $employeeToken = $existingUser['token'];
    
    error_log("DEBUG: Using existing user ID: " . $employeeUserId);
    
    // Check if user already has access to this account
    $existingAccessQuery = mysqli_query($connection, "
        SELECT id FROM user_accounts 
        WHERE user_id = $employeeUserId AND account_id = $accountId AND status = 'active'
        LIMIT 1
    ");
    
    if ($existingAccessQuery && mysqli_num_rows($existingAccessQuery) > 0) {
        http_response_code(400);
        echo json_encode([
            'code' => 400,
            'status' => 'error',
            'message' => 'User already has access to this account.'
        ]);
        exit;
    }
} else {
    /** -------------------------------
     * 3. Create new employee user
     */
    $userCode = "U" . strtoupper(bin2hex(random_bytes(3)));
    $employeeToken = bin2hex(random_bytes(32));
    $password = password_hash("default123", PASSWORD_BCRYPT); // default temp password

    $insertUser = mysqli_query($connection, "
        INSERT INTO users (code, name, phone, email, nid, password_hash, token, status, created_at, created_by) 
        VALUES ('$userCode', '$name', '$phone', " . ($email ? "'$email'" : "NULL") . ", " . ($nid ? "'$nid'" : "NULL") . ", 
        '$password', '$employeeToken', 'active', NOW(), $currentUserId)
    ");

    if (!$insertUser) {
        error_log("DEBUG: Failed to create user: " . mysqli_error($connection));
        http_response_code(500);
        echo json_encode([
            'code' => 500,
            'status' => 'error',
            'message' => 'Failed to create employee user: ' . mysqli_error($connection)
        ]);
        exit;
    }

    $employeeUserId = mysqli_insert_id($connection);
    error_log("DEBUG: Created new user ID: " . $employeeUserId);
}

/** -------------------------------
 * 4. Grant access to the account
 */
$insertAccessQuery = "
    INSERT INTO user_accounts (user_id, account_id, role, permissions, status, created_at, created_by) 
    VALUES ($employeeUserId, $accountId, '$role', " . ($permissions ? "'$permissions'" : "NULL") . ", 'active', NOW(), $currentUserId)
";

error_log("DEBUG: Insert access query: " . $insertAccessQuery);

$insertAccess = mysqli_query($connection, $insertAccessQuery);

if (!$insertAccess) {
    error_log("DEBUG: Failed to insert access: " . mysqli_error($connection));
    // Rollback user creation
    mysqli_query($connection, "DELETE FROM users WHERE id = $employeeUserId");
    http_response_code(500);
    echo json_encode([
        'code' => 500,
        'status' => 'error',
        'message' => 'Failed to grant account access: ' . mysqli_error($connection)
    ]);
    exit;
}

$accessId = mysqli_insert_id($connection);
error_log("DEBUG: Created access ID: " . $accessId);

// Verify what was actually inserted
$verifyQuery = mysqli_query($connection, "
    SELECT role, permissions FROM user_accounts 
    WHERE id = $accessId
    LIMIT 1
");

$storedPermissions = $normalizedPermissions; // Default to normalized version
if ($verifyQuery && mysqli_num_rows($verifyQuery) > 0) {
    $verifyData = mysqli_fetch_assoc($verifyQuery);
    error_log("DEBUG: Verified role in DB: " . $verifyData['role']);
    error_log("DEBUG: Verified permissions in DB: " . $verifyData['permissions']);
    // Return what was actually stored in database
    $storedPermissions = $verifyData['permissions'] ? json_decode($verifyData['permissions'], true) : null;
} else {
    error_log("DEBUG: Could not verify inserted data");
}

// Set as default account if requested
if ($setAsDefault) {
    mysqli_query($connection, "
        UPDATE users SET default_account_id = $accountId WHERE id = $employeeUserId
    ");
}

error_log("=== EMPLOYEE CREATE DEBUG END ===");

/** -------------------------------
 * 5. Return success response
 */
echo json_encode([
    'code' => 200,
    'status' => 'success',
    'message' => 'Employee registered successfully.',
    'data' => [
        'employee_id' => $employeeUserId,
        'user_code' => $userCode,
        'name' => $name,
        'phone' => $phone,
        'email' => $email,
        'role' => $role,
        'permissions' => $storedPermissions,
        'account_id' => $accountId,
        'token' => $employeeToken
    ]
]);
?>
