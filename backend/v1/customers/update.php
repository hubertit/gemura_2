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

if (empty($data['token']) || empty($data['relation_id']) || !isset($data['price_per_liter'])) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'Token, relation_id and price_per_liter are required.'
    ]);
    exit;
}

$token = mysqli_real_escape_string($connection, trim($data['token']));
$relation_id = (int)$data['relation_id'];
$price_per_liter = (float)$data['price_per_liter'];

/** 1. Get supplier account from token */
$supplierQ = mysqli_query($connection, "
    SELECT u.id, u.default_account_id as account_id, a.name AS account_name
    FROM users u
    LEFT JOIN accounts a ON a.id = u.default_account_id
    WHERE u.token = '$token' AND u.status = 'active' LIMIT 1
");

if (!$supplierQ || mysqli_num_rows($supplierQ) == 0) {
    echo json_encode([
        'code' => 401,
        'status' => 'error',
        'message' => 'Unauthorized. Invalid token.'
    ]);
    exit;
}

$supplier = mysqli_fetch_assoc($supplierQ);
$supplierAccountId = $supplier['account_id'];

// Check if user has a valid default account
if (!$supplierAccountId || !$supplier['account_name']) {
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'No valid default account found. Please set a default account.'
    ]);
    exit;
}

/** 2. Ensure the relationship belongs to this supplier */
$checkQ = mysqli_query($connection, "
    SELECT * FROM suppliers_customers 
    WHERE id = $relation_id 
      AND supplier_account_id = $supplierAccountId 
    LIMIT 1
");

if (!$checkQ || mysqli_num_rows($checkQ) == 0) {
    echo json_encode([
        'code' => 404,
        'status' => 'error',
        'message' => 'Relationship not found or not owned by this supplier.'
    ]);
    exit;
}

/** 3. Update price */
$update = mysqli_query($connection, "
    UPDATE suppliers_customers 
    SET price_per_liter = $price_per_liter, updated_at = NOW() 
    WHERE id = $relation_id
");

if ($update) {
    echo json_encode([
        'code' => 200,
        'status' => 'success',
        'message' => 'Price updated successfully.',
        'data' => [
            'relation_id' => $relation_id,
            'price_per_liter' => $price_per_liter
        ]
    ]);
} else {
    echo json_encode([
        'code' => 500,
        'status' => 'error',
        'message' => 'Failed to update price.'
    ]);
}
?>
