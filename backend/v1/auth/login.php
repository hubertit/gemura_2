<?php
require_once("../configs/configs.php");

header('Content-Type: application/json');

$input_data = file_get_contents("php://input");
$data = json_decode($input_data, true);

// Validate JSON
if (json_last_error() !== JSON_ERROR_NONE) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'Invalid JSON format.'
    ]);
    exit;
}

// Validate input
if (empty($data['identifier']) || empty($data['password'])) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'Email/phone and password are required.'
    ]);
    exit;
}

$identifier = trim($data['identifier']);
$password = trim($data['password']);

// Determine if identifier is email or phone
if (filter_var($identifier, FILTER_VALIDATE_EMAIL)) {
    $field = "email";
    $value = strtolower($identifier);
} else {
    $value = preg_replace('/[^0-9]/', '', $identifier);
    $field = "phone";
}

// Fetch user
$stmt = $connection->prepare("SELECT * FROM users WHERE $field = ? LIMIT 1");
$stmt->bind_param("s", $value);
$stmt->execute();
$result = $stmt->get_result();
if ($result->num_rows === 0) {
    http_response_code(401);
    echo json_encode([
        'code' => 401,
        'status' => 'error',
        'message' => 'Invalid credentials.'
    ]);
    exit;
}
$user = $result->fetch_assoc();
$stmt->close();

// Verify password
if (!password_verify($password, $user['password_hash'])) {
    http_response_code(401);
    echo json_encode([
        'code' => 401,
        'status' => 'error',
        'message' => 'Invalid credentials.'
    ]);
    exit;
}

// Get all accounts user has access to (same structure as get profile)
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
    WHERE ua.user_id = {$user['id']}
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
    'name', 'email', 'phone', 'province', 'district', 'sector', 
    'cell', 'village', 'id_number', 'id_front_photo_url', 'id_back_photo_url', 'selfie_photo_url'
];

$completedFields = 0;
foreach ($profileFields as $field) {
    if (!empty($user[$field])) {
        $completedFields++;
    }
}

$profileCompletion = round(($completedFields / count($profileFields)) * 100);

// Update last login info
$ip = $_SERVER['REMOTE_ADDR'] ?? null;
$device = $_SERVER['HTTP_USER_AGENT'] ?? null;
$update_stmt = $connection->prepare("
    UPDATE users SET last_login = NOW(), last_login_ip = ?, last_login_device = ? WHERE id = ?
");
$update_stmt->bind_param("ssi", $ip, $device, $user['id']);
$update_stmt->execute();
$update_stmt->close();

// Response (same structure as get profile)
echo json_encode([
    'code' => 200,
    'status' => 'success',
    'message' => 'Login successful.',
    'data' => [
        'user' => [
            'id' => intval($user['id']),
            'name' => $user['name'],
            'email' => $user['email'],
            'phone' => $user['phone'],
            'account_type' => $user['account_type'] ?? 'mcc',
            'status' => $user['status'],
            'token' => $user['token']
        ],
        'account' => $defaultAccount,
        'accounts' => $accounts,
        'total_accounts' => count($accounts),
        'profile_completion' => $profileCompletion
    ]
]);
?>
