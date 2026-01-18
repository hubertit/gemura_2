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

// Get user and their accounts
$userQuery = mysqli_query($connection, "
    SELECT 
        u.id AS user_id,
        u.name AS user_name,
        u.email,
        u.phone,
        u.default_account_id
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

// Get all accounts user has access to
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
if ($accountsQuery && mysqli_num_rows($accountsQuery) > 0) {
    while ($row = mysqli_fetch_assoc($accountsQuery)) {
        $accounts[] = [
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
    }
}

echo json_encode([
    "code" => 200,
    "status" => "success",
    "message" => "User accounts fetched successfully.",
    "data" => [
        "user" => [
            "id" => intval($user['user_id']),
            "name" => $user['user_name'],
            "email" => $user['email'],
            "phone" => $user['phone'],
            "default_account_id" => $user['default_account_id'] ? intval($user['default_account_id']) : null
        ],
        "accounts" => $accounts,
        "total_accounts" => count($accounts)
    ]
]);
?>
