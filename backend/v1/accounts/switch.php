<?php
require_once("../configs/configs.php");
header('Content-Type: application/json');

$input_data = file_get_contents("php://input");
$data = json_decode($input_data, true);

// Validate required fields
if (empty($data['token']) || empty($data['account_id'])) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Token and account_id are required."
    ]);
    exit;
}

$token = mysqli_real_escape_string($connection, $data['token']);
$account_id = intval($data['account_id']);

// Get user
$userQuery = mysqli_query($connection, "
    SELECT u.id AS user_id, u.name AS user_name
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
$user_id = $user['user_id'];

// Check if user has access to this account
$accessQuery = mysqli_query($connection, "
    SELECT ua.account_id, a.name AS account_name, a.code AS account_code, ua.role
    FROM user_accounts ua
    JOIN accounts a ON a.id = ua.account_id
    WHERE ua.user_id = $user_id 
      AND ua.account_id = $account_id
      AND ua.status = 'active'
      AND a.status != 'deleted'
    LIMIT 1
");

if (!$accessQuery || mysqli_num_rows($accessQuery) === 0) {
    http_response_code(403);
    echo json_encode([
        "code" => 403,
        "status" => "error",
        "message" => "Access denied. You don't have permission to access this account."
    ]);
    exit;
}

$account = mysqli_fetch_assoc($accessQuery);

// Update user's default account
$updateQuery = mysqli_query($connection, "
    UPDATE users 
    SET default_account_id = $account_id, updated_at = NOW()
    WHERE id = $user_id
");

if (!$updateQuery) {
    http_response_code(500);
    echo json_encode([
        "code" => 500,
        "status" => "error",
        "message" => "Failed to switch default account.",
        "db_error" => mysqli_error($connection)
    ]);
    exit;
}

// Get updated user data with same structure as get profile
$userQuery = mysqli_query($connection, "
    SELECT 
        u.id AS user_id,
        u.name AS user_name,
        u.email,
        u.phone,
        u.default_account_id,
        u.status,
        u.token
    FROM users u
    WHERE u.id = $user_id
    LIMIT 1
");

if (!$userQuery || mysqli_num_rows($userQuery) === 0) {
    http_response_code(500);
    echo json_encode([
        "code" => 500,
        "status" => "error",
        "message" => "Failed to retrieve updated user data."
    ]);
    exit;
}

$user = mysqli_fetch_assoc($userQuery);

// Get all accounts user has access to (same as get profile)
$accountsQuery = mysqli_query($connection, "
    SELECT 
        a.id AS account_id,
        a.code AS account_code,
        a.name AS account_name,
        a.type AS account_type,
        a.status AS account_status,
        a.created_at AS account_created_at,
        ua.role,
        ua.permissions,
        ua.status AS user_account_status,
        ua.created_at AS access_granted_at,
        CASE WHEN u.default_account_id = a.id THEN 1 ELSE 0 END as is_default
    FROM user_accounts ua
    JOIN accounts a ON a.id = ua.account_id
    JOIN users u ON u.id = ua.user_id
    WHERE ua.user_id = $user_id
      AND ua.status = 'active'
      AND a.status != 'deleted'
    ORDER BY ua.created_at DESC
");

$accounts = [];
$defaultAccount = null;

if ($accountsQuery && mysqli_num_rows($accountsQuery) > 0) {
    while ($row = mysqli_fetch_assoc($accountsQuery)) {
        $account = [
            "account_id" => intval($row['account_id']),
            "account_code" => $row['account_code'],
            "account_name" => $row['account_name'],
            "account_type" => $row['account_type'],
            "account_status" => $row['account_status'],
            "account_created_at" => $row['account_created_at'],
            "role" => $row['role'],
            "permissions" => $row['permissions'] ? json_decode($row['permissions'], true) : null,
            "user_account_status" => $row['user_account_status'],
            "access_granted_at" => $row['access_granted_at'],
            "is_default" => (bool)$row['is_default']
        ];
        
        $accounts[] = $account;
        
        // Set default account
        if ($row['is_default']) {
            $defaultAccount = [
                'id' => intval($row['account_id']),
                'code' => $row['account_code'],
                'name' => $row['account_name'],
                'type' => $row['account_type']
            ];
        }
    }
}

// Calculate profile completion percentage (same as get profile)
$profileFields = [
    'user_name', 'email', 'phone', 'province', 'district', 'sector', 
    'cell', 'village', 'id_number', 'id_front', 'id_back', 'selfie'
];

$completedFields = 0;
foreach ($profileFields as $field) {
    if (!empty($user[$field])) {
        $completedFields++;
    }
}

$profileCompletion = round(($completedFields / count($profileFields)) * 100);

// Return same structure as get profile
echo json_encode([
    "code" => 200,
    "status" => "success",
    "message" => "Default account switched successfully",
    "data" => [
        "user" => [
            "id" => intval($user['user_id']),
            "name" => $user['user_name'],
            "email" => $user['email'],
            "phone" => $user['phone'],
            "status" => $user['status'],
            "token" => $user['token']
        ],
        "account" => $defaultAccount,
        "accounts" => $accounts,
        "total_accounts" => count($accounts),
        "profile_completion" => $profileCompletion
    ]
]);
?>
