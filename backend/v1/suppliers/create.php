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
    empty($data['name']) ||
    empty($data['phone']) ||
    empty($data['price_per_liter'])
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
$name = mysqli_real_escape_string($connection, trim($data['name']));
$phone = preg_replace('/[^0-9]/', '', $data['phone']);
$phone = mysqli_real_escape_string($connection, $phone);
$email = !empty($data['email']) ? mysqli_real_escape_string($connection, trim($data['email'])) : null;
$nid = !empty($data['nid']) ? mysqli_real_escape_string($connection, trim($data['nid'])) : null;
$address = !empty($data['address']) ? mysqli_real_escape_string($connection, trim($data['address'])) : null;
$price_per_liter = (float)$data['price_per_liter'];

/** -------------------------------
 * 1. Find or create customer (by token)
 */
$customerQ = mysqli_query($connection, "
    SELECT u.id as user_id, u.default_account_id as account_id, a.name AS account_name
    FROM users u 
    LEFT JOIN accounts a ON a.id = u.default_account_id 
    WHERE u.token = '$token' AND u.status = 'active' LIMIT 1
");

if (!$customerQ || mysqli_num_rows($customerQ) == 0) {
    http_response_code(401);
    echo json_encode([
        'code' => 401,
        'status' => 'error',
        'message' => 'Unauthorized. Invalid token.'
    ]);
    exit;
}

$customer = mysqli_fetch_assoc($customerQ);
$customerAccountId = $customer['account_id'];
$currentUserId = $customer['user_id'];

/** -------------------------------
 * Helper function: create user + account + wallet
 */
function createUserWithAccountAndWallet($connection, $name, $phone, $email, $nid, $address, $currentUserId) {
    $userCode = "U" . strtoupper(bin2hex(random_bytes(3)));
    $accountCode = "A" . strtoupper(bin2hex(random_bytes(3)));
    $walletCode = "W" . strtoupper(bin2hex(random_bytes(3)));
    $token = bin2hex(random_bytes(32));
    $password = password_hash("default123", PASSWORD_BCRYPT); // default temp password

    // insert user
    $insertUser = mysqli_query($connection, "
        INSERT INTO users (code, name, phone, email, nid, address, password_hash, token, status, created_at, created_by) 
        VALUES ('$userCode', '$name', '$phone', " . ($email ? "'$email'" : "NULL") . ", " . ($nid ? "'$nid'" : "NULL") . ",
        " . ($address ? "'$address'" : "NULL") . ", '$password', '$token', 'active', NOW(), $currentUserId)
    ");

    if (!$insertUser) return null;
    $userId = mysqli_insert_id($connection);

    // create account
    $insertAccount = mysqli_query($connection, "
        INSERT INTO accounts (code, name, type, status, created_at, created_by) 
        VALUES ('$accountCode', '$name', 'tenant', 'active', NOW(), $currentUserId)
    ");
    if (!$insertAccount) return null;
    $accountId = mysqli_insert_id($connection);

    // link user to account
    mysqli_query($connection, "
        INSERT INTO user_accounts (user_id, account_id, role, status, created_at, created_by) 
        VALUES ($userId, $accountId, 'supplier', 'active', NOW(), $currentUserId)
    ");

    // create wallet
    mysqli_query($connection, "
        INSERT INTO wallets (code, account_id, name, is_saving, is_joint, is_default, balance, status, created_at, created_by) 
        VALUES ('$walletCode', $accountId, 'Default Wallet', 0, 0, 1, 0.00, 'active', NOW(), $currentUserId)
    ");

    return [
        'user_id' => $userId,
        'account_id' => $accountId,
        'user_code' => $userCode,
        'account_code' => $accountCode,
        'wallet_code' => $walletCode,
        'token' => $token
    ];
}

// Check if user has a valid default account
if (!$customerAccountId || !$customer['account_name']) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'No valid default account found. Please set a default account.'
    ]);
    exit;
}

/** -------------------------------
 * 2. Find or create supplier (by phone/email/nid)
 */
$supplierQ = mysqli_query($connection, "
    SELECT u.id as user_id, a.id as account_id 
    FROM users u 
    JOIN user_accounts ua ON ua.user_id = u.id 
    JOIN accounts a ON a.id = ua.account_id 
    WHERE u.phone = '$phone' " . 
    ($email ? "OR u.email = '$email'" : "") . 
    ($nid ? "OR u.nid = '$nid'" : "") . " LIMIT 1
");

if ($supplierQ && mysqli_num_rows($supplierQ) > 0) {
    $supplier = mysqli_fetch_assoc($supplierQ);
    $supplierAccountId = $supplier['account_id'];
} else {
    // create new supplier
    $supplier = createUserWithAccountAndWallet($connection, $name, $phone, $email, $nid, $address, $currentUserId);
    if (!$supplier) {
        echo json_encode([
            'code' => 500,
            'status' => 'error',
            'message' => 'Failed to register supplier.'
        ]);
        exit;
    }
    $supplierAccountId = $supplier['account_id'];
}

/** -------------------------------
 * 3. Create or update relationship
 */
$relationQ = mysqli_query($connection, "
    SELECT id FROM suppliers_customers 
    WHERE supplier_account_id = $supplierAccountId AND customer_account_id = $customerAccountId LIMIT 1
");

if ($relationQ && mysqli_num_rows($relationQ) > 0) {
    // update price
    $relation = mysqli_fetch_assoc($relationQ);
    mysqli_query($connection, "UPDATE suppliers_customers SET price_per_liter = $price_per_liter, updated_at = NOW(), updated_by = $currentUserId WHERE id = " . $relation['id']);
} else {
    // insert relationship
    mysqli_query($connection, "
        INSERT INTO suppliers_customers (supplier_account_id, customer_account_id, price_per_liter, relationship_status, created_at, created_by) 
        VALUES ($supplierAccountId, $customerAccountId, $price_per_liter, 'active', NOW(), $currentUserId)
    ");
}

/** -------------------------------
 * Success response
 */
echo json_encode([
    'code' => 201,
    'status' => 'success',
    'message' => 'Supplier registered and linked successfully.',
    'data' => [
        'customer_account_id' => $customerAccountId,
        'supplier_account_id' => $supplierAccountId,
        'price_per_liter' => $price_per_liter
    ]
]);
