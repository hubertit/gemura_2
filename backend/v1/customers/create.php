<?php
require_once("../configs/configs.php");
header('Content-Type: application/json');

$input_data = file_get_contents("php://input");
$data = json_decode($input_data, true);

// Validate JSON
if (json_last_error() !== JSON_ERROR_NONE) {
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'Invalid JSON format.'
    ]);
    exit;
}

// Validate required fields
if (empty($data['token']) || empty($data['name']) || empty($data['phone']) || empty($data['price_per_liter'])) {
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'Token, name, phone and price_per_liter are required.'
    ]);
    exit;
}

$token   = trim($data['token']);
$name    = trim($data['name']);
$phone   = trim($data['phone']);
$email   = !empty($data['email']) ? trim($data['email']) : null;
$address = !empty($data['address']) ? trim($data['address']) : null;
$price   = (float)$data['price_per_liter'];

// --- Identify actor account (supplier) from token ---
$stmt = $connection->prepare("
    SELECT u.id, u.default_account_id AS account_id, a.name AS account_name
    FROM users u
    LEFT JOIN accounts a ON a.id = u.default_account_id
    WHERE u.token = ? AND u.status = 'active' LIMIT 1
");
$stmt->bind_param("s", $token);
$stmt->execute();
$res = $stmt->get_result();
if ($res->num_rows === 0) {
    echo json_encode([
        'code' => 403,
        'status' => 'error',
        'message' => 'Unauthorized. Invalid token.'
    ]);
    exit;
}
$user = $res->fetch_assoc();
$supplier_account_id = $user['account_id'];
$currentUserId = $user['id'];
$stmt->close();

// Check if user has a valid default account
if (!$supplier_account_id || !$user['account_name']) {
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'No valid default account found. Please set a default account.'
    ]);
    exit;
}

// --- Get or create customer ---
$customer_account_id = null;
$stmt = $connection->prepare("
    SELECT a.id AS account_id
    FROM users u
    JOIN user_accounts ua ON ua.user_id = u.id
    JOIN accounts a ON ua.account_id = a.id
    WHERE u.phone = ? LIMIT 1
");
$stmt->bind_param("s", $phone);
$stmt->execute();
$cust_res = $stmt->get_result();

if ($cust_res->num_rows > 0) {
    // Customer exists
    $cust = $cust_res->fetch_assoc();
    $customer_account_id = $cust['account_id'];
} else {
    // Create new user + account
    $user_code    = "USR_" . strtoupper(bin2hex(random_bytes(3)));
    $account_code = "ACC_" . strtoupper(bin2hex(random_bytes(3)));

    // Insert user
    $stmt = $connection->prepare("
        INSERT INTO users (code, name, phone, email, address, password_hash, status, created_by)
        VALUES (?, ?, ?, ?, ?, '', 'active', ?)
    ");
    $stmt->bind_param("sssssi", $user_code, $name, $phone, $email, $address, $currentUserId);
    if (!$stmt->execute()) {
        echo json_encode([
            'code' => 500,
            'status' => 'error',
            'message' => 'Failed to create user for customer.'
        ]);
        exit;
    }
    $user_id = $stmt->insert_id;
    $stmt->close();

    // Insert account
    $stmt = $connection->prepare("
        INSERT INTO accounts (code, name, type, status, created_by)
        VALUES (?, ?, 'customer', 'active', ?)
    ");
    $stmt->bind_param("ssi", $account_code, $name, $currentUserId);
    if (!$stmt->execute()) {
        echo json_encode([
            'code' => 500,
            'status' => 'error',
            'message' => 'Failed to create customer account.'
        ]);
        exit;
    }
    $customer_account_id = $stmt->insert_id;
    $stmt->close();

    // Link user to account
    $role = "customer";
    $stmt = $connection->prepare("
        INSERT INTO user_accounts (user_id, account_id, role, created_by)
        VALUES (?, ?, ?, ?)
    ");
    $stmt->bind_param("iisi", $user_id, $customer_account_id, $role, $currentUserId);
    $stmt->execute();
    $stmt->close();
}

// --- Insert or update supplier-customer relationship ---
$stmt = $connection->prepare("
    INSERT INTO suppliers_customers (supplier_account_id, customer_account_id, price_per_liter, relationship_status, created_by)
    VALUES (?, ?, ?, 'active', ?)
    ON DUPLICATE KEY UPDATE price_per_liter = VALUES(price_per_liter), relationship_status = 'active', updated_by = ?
");
$stmt->bind_param("iidii", $supplier_account_id, $customer_account_id, $price, $currentUserId, $currentUserId);
if ($stmt->execute()) {
    echo json_encode([
        'code' => 201,
        'status' => 'success',
        'message' => 'Customer added/updated successfully.',
        'data' => [
            'name'    => $name,
            'phone'   => $phone,
            'email'   => $email,
            'address' => $address,
            'price_per_liter' => $price
        ]
    ]);
} else {
    echo json_encode([
        'code' => 500,
        'status' => 'error',
        'message' => 'Failed to add customer.'
    ]);
}
$stmt->close();
?>
