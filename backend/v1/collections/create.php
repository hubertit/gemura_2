<?php
require_once("../configs/configs.php");
header('Content-Type: application/json');

$input_data = file_get_contents("php://input");
$data = json_decode($input_data, true);

// Validate required fields
if (empty($data['token']) || empty($data['supplier_account_code']) || empty($data['quantity']) || empty($data['status']) || empty($data['collection_at'])) {

    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Missing required fields."
    ]);
    exit;
}

$token = mysqli_real_escape_string($connection, $data['token']);
$supplier_account_code = mysqli_real_escape_string($connection, $data['supplier_account_code']);
$quantity = floatval($data['quantity']);
$status = mysqli_real_escape_string($connection, $data['status']);
$collection_at = mysqli_real_escape_string($connection, $data['collection_at']);
$notes = !empty($data['notes']) ? mysqli_real_escape_string($connection, $data['notes']) : null;

// Get logged in user with default account only
$userQuery = mysqli_query($connection, "
    SELECT u.id AS user_id, u.default_account_id AS account_id, a.name AS account_name
    FROM users u
    LEFT JOIN accounts a ON a.id = u.default_account_id
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
$customer_account_id = $user['account_id'];
$recorded_by = $user['user_id'];

// Check if user has a valid default account
if (!$customer_account_id || !$user['account_name']) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "No valid default account found. Please set a default account."
    ]);
    exit;
}

// Get supplier account ID from code
$supplierQuery = mysqli_query($connection, "
    SELECT id, code, name, type, status
    FROM accounts
    WHERE code = '$supplier_account_code'
    LIMIT 1
");

if (!$supplierQuery || mysqli_num_rows($supplierQuery) === 0) {
    http_response_code(404);
    echo json_encode([
        "code" => 404,
        "status" => "error",
        "message" => "Supplier account not found."
    ]);
    exit;
}

$supplier = mysqli_fetch_assoc($supplierQuery);
$supplier_account_id = $supplier['id'];

// Get default unit price from suppliers_customers relationship
$priceQuery = mysqli_query($connection, "
    SELECT price_per_liter
    FROM suppliers_customers
    WHERE supplier_account_id = $supplier_account_id 
      AND customer_account_id = $customer_account_id
      AND relationship_status = 'active'
    LIMIT 1
");

if ($priceQuery && mysqli_num_rows($priceQuery) > 0) {
    $priceRow = mysqli_fetch_assoc($priceQuery);
    $unit_price = $priceRow['price_per_liter'];
} else {
    $unit_price = 0.00; // fallback if no relationship pricing
}

// Insert milk collection (using milk_sales table with collection perspective)
$insertQuery = "
    INSERT INTO milk_sales (
        supplier_account_id,
        customer_account_id,
        quantity,
        unit_price,
        status,
        sale_at,
        notes,
        recorded_by
    )
    VALUES (
        $supplier_account_id,
        $customer_account_id,
        $quantity,
        $unit_price,
        '$status',
        '$collection_at',
        " . ($notes ? "'$notes'" : "NULL") . ",
        $recorded_by
    )
";

if (mysqli_query($connection, $insertQuery)) {
    echo json_encode([
        "code" => 200,
        "status" => "success",
        "message" => "Milk collection recorded successfully.",
        "data" => [
            "collection_id" => mysqli_insert_id($connection),
            "supplier_account_code" => $supplier_account_code,
            "customer_account_id" => $customer_account_id,
            "quantity" => $quantity,
            "unit_price" => $unit_price,
            "total_amount" => $quantity * $unit_price,
            "status" => $status,
            "collection_at" => $collection_at
        ]
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        "code" => 500,
        "status" => "error",
        "message" => "Failed to record milk collection.",
        "db_error" => mysqli_error($connection),
        "sql" => $insertQuery
    ]);
}
?>
