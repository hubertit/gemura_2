<?php
require_once("../configs/configs.php");
header('Content-Type: application/json');

$input_data = file_get_contents("php://input");
$data = json_decode($input_data, true);

// Validate required fields
if (empty($data['token']) || empty($data['user_data']) || empty($data['account_access'])) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Token, user_data, and account_access are required."
    ]);
    exit;
}

$token = mysqli_real_escape_string($connection, $data['token']);

// Validate admin permissions
$adminQuery = mysqli_query($connection, "
    SELECT u.id AS user_id, ua.account_id, ua.role, ua.permissions
    FROM users u
    JOIN user_accounts ua ON ua.user_id = u.id
    WHERE u.token = '$token' 
      AND u.status = 'active'
      AND ua.status = 'active'
    LIMIT 1
");

if (!$adminQuery || mysqli_num_rows($adminQuery) === 0) {
    http_response_code(403);
    echo json_encode([
        "code" => 403,
        "status" => "error",
        "message" => "Unauthorized. Invalid token."
    ]);
    exit;
}

$admin = mysqli_fetch_assoc($adminQuery);
$currentUserId = $admin['user_id'];

// Check if admin has permission to register users
$adminPermissions = $admin['permissions'] ? json_decode($admin['permissions'], true) : [];
if (!in_array('register_users', $adminPermissions) && $admin['role'] !== 'admin') {
    http_response_code(403);
    echo json_encode([
        "code" => 403,
        "status" => "error",
        "message" => "Insufficient permissions to register users."
    ]);
    exit;
}

$userData = $data['user_data'];
$accountAccess = $data['account_access'];

// Validate user data
if (empty($userData['name']) || empty($userData['phone']) || empty($userData['email'])) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Name, phone, and email are required for user registration."
    ]);
    exit;
}

// Validate account access
if (empty($accountAccess['account_id']) || empty($accountAccess['role'])) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Account ID and role are required for account access."
    ]);
    exit;
}

// Check if account exists and admin has access to it
$accountQuery = mysqli_query($connection, "
    SELECT a.id, a.name, a.code
    FROM accounts a
    JOIN user_accounts ua ON ua.account_id = a.id
    WHERE a.id = {$accountAccess['account_id']}
      AND ua.user_id = {$admin['user_id']}
      AND a.status != 'deleted'
    LIMIT 1
");

if (!$accountQuery || mysqli_num_rows($accountQuery) === 0) {
    http_response_code(403);
    echo json_encode([
        "code" => 403,
        "status" => "error",
        "message" => "Account not found or access denied."
    ]);
    exit;
}

$account = mysqli_fetch_assoc($accountQuery);

// Check if user already exists (by email or phone)
$existingUserQuery = mysqli_query($connection, "
    SELECT id FROM users 
    WHERE email = '" . mysqli_real_escape_string($connection, $userData['email']) . "'
       OR phone = '" . mysqli_real_escape_string($connection, $userData['phone']) . "'
    LIMIT 1
");

if ($existingUserQuery && mysqli_num_rows($existingUserQuery) > 0) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "User already exists with this email or phone."
    ]);
    exit;
}

// Generate user code and token
$userCode = "U" . strtoupper(bin2hex(random_bytes(3)));
$userToken = bin2hex(random_bytes(32));

// Generate default password (user can change later)
$defaultPassword = !empty($userData['password']) ? $userData['password'] : "default123";
$passwordHash = password_hash($defaultPassword, PASSWORD_BCRYPT);

// Insert new user
$insertUserQuery = "
    INSERT INTO users (
        code, name, phone, email, nid, address, 
        password_hash, token, status, created_at, created_by
    ) VALUES (
        '$userCode',
        '" . mysqli_real_escape_string($connection, $userData['name']) . "',
        '" . mysqli_real_escape_string($connection, $userData['phone']) . "',
        '" . mysqli_real_escape_string($connection, $userData['email']) . "',
        " . (!empty($userData['nid']) ? "'" . mysqli_real_escape_string($connection, $userData['nid']) . "'" : "NULL") . ",
        " . (!empty($userData['address']) ? "'" . mysqli_real_escape_string($connection, $userData['address']) . "'" : "NULL") . ",
        '$passwordHash',
        '$userToken',
        'active',
        NOW(),
        $currentUserId
    )
";

if (!mysqli_query($connection, $insertUserQuery)) {
    http_response_code(500);
    echo json_encode([
        "code" => 500,
        "status" => "error",
        "message" => "Failed to create user.",
        "db_error" => mysqli_error($connection)
    ]);
    exit;
}

$newUserId = mysqli_insert_id($connection);

// Grant account access
$permissions = !empty($accountAccess['permissions']) ? json_encode($accountAccess['permissions']) : null;
$insertAccessQuery = "
    INSERT INTO user_accounts (
        user_id, account_id, role, permissions, status, created_at, created_by
    ) VALUES (
        $newUserId,
        {$accountAccess['account_id']},
        '" . mysqli_real_escape_string($connection, $accountAccess['role']) . "',
        " . ($permissions ? "'$permissions'" : "NULL") . ",
        'active',
        NOW(),
        $currentUserId
    )
";

if (!mysqli_query($connection, $insertAccessQuery)) {
    // Rollback user creation if access grant fails
    mysqli_query($connection, "DELETE FROM users WHERE id = $newUserId");
    
    http_response_code(500);
    echo json_encode([
        "code" => 500,
        "status" => "error",
        "message" => "Failed to grant account access.",
        "db_error" => mysqli_error($connection)
    ]);
    exit;
}

// Set as default account if specified
if (!empty($accountAccess['set_as_default']) && $accountAccess['set_as_default']) {
    mysqli_query($connection, "
        UPDATE users 
        SET default_account_id = {$accountAccess['account_id']} 
        WHERE id = $newUserId
    ");
}

echo json_encode([
    "code" => 201,
    "status" => "success",
    "message" => "User registered successfully with account access.",
    "data" => [
        "user" => [
            "id" => $newUserId,
            "code" => $userCode,
            "name" => $userData['name'],
            "email" => $userData['email'],
            "phone" => $userData['phone'],
            "token" => $userToken
        ],
        "account_access" => [
            "account_id" => intval($accountAccess['account_id']),
            "account_name" => $account['name'],
            "account_code" => $account['code'],
            "role" => $accountAccess['role'],
            "permissions" => $accountAccess['permissions'] ?? [],
            "is_default" => !empty($accountAccess['set_as_default']) && $accountAccess['set_as_default']
        ],
        "login_credentials" => [
            "email" => $userData['email'],
            "password" => $defaultPassword
        ]
    ]
]);
?>
