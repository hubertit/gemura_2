<?php
require_once("../configs/configs.php");

header('Content-Type: application/json');

// Read input
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

if (empty($data['token'])) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'Token is required.'
    ]);
    exit;
}

$token = trim($data['token']);

// Get user with default account by token
$stmt = $connection->prepare("
    SELECT u.id, u.default_account_id, a.name AS account_name
    FROM users u
    LEFT JOIN accounts a ON a.id = u.default_account_id
    WHERE u.token = ? AND u.status = 'active'
    LIMIT 1
");
$stmt->bind_param("s", $token);
$stmt->execute();
$user_res = $stmt->get_result();
if ($user_res->num_rows === 0) {
    http_response_code(401);
    echo json_encode([
        'code' => 401,
        'status' => 'error',
        'message' => 'Invalid or expired token.'
    ]);
    exit;
}
$user = $user_res->fetch_assoc();
$user_id = $user['id'];
$default_account_id = $user['default_account_id'];
$stmt->close();

// Check if user has a valid default account
if (!$default_account_id || !$user['account_name']) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'No valid default account found. Please set a default account.'
    ]);
    exit;
}

// Fetch wallets for the default account only
$wallets = [];
$stmt = $connection->prepare("
    SELECT w.code, w.type, w.is_joint, w.is_default, w.balance, w.currency, w.status,
           a.code AS account_code, a.name AS account_name, a.type AS account_type
    FROM wallets w
    JOIN accounts a ON w.account_id = a.id
    WHERE w.account_id = ?
");
$stmt->bind_param("i", $default_account_id);
$stmt->execute();
$result = $stmt->get_result();
while ($row = $result->fetch_assoc()) {
    $wallets[] = [
        'wallet_code' => $row['code'],
        'type' => $row['type'],
        'is_joint' => (bool)$row['is_joint'],
        'is_default' => (bool)$row['is_default'],
        'balance' => (float)$row['balance'],
        'currency' => $row['currency'],
        'status' => $row['status'],
        'account' => [
            'code' => $row['account_code'],
            'name' => $row['account_name'],
            'type' => $row['account_type']
        ]
    ];
}
$stmt->close();

if (empty($wallets)) {
    echo json_encode([
        'code' => 404,
        'status' => 'error',
        'message' => 'No wallets found for this account.'
    ]);
    exit;
}

echo json_encode([
    'code' => 200,
    'status' => 'success',
    'message' => 'Wallets retrieved successfully.',
    'data' => $wallets
]);
?>
