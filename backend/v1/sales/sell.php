<?php
require_once("../configs/configs.php");
header('Content-Type: application/json');

$input_data = file_get_contents("php://input");
$data = json_decode($input_data, true);

// Validate required fields
if (empty($data['token']) || empty($data['customer_account_code']) || empty($data['quantity']) || empty($data['status']) || empty($data['sale_at'])) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Missing required fields."
    ]);
    exit;
}

$token = mysqli_real_escape_string($connection, $data['token']);
$customer_account_code = mysqli_real_escape_string($connection, $data['customer_account_code']);
$quantity = floatval($data['quantity']);
$status = mysqli_real_escape_string($connection, $data['status']);
$sale_at = mysqli_real_escape_string($connection, $data['sale_at']);
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
$supplier_account_id = $user['account_id'];
$recorded_by = $user['user_id'];

// Check if user has a valid default account
if (!$supplier_account_id || !$user['account_name']) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "No valid default account found. Please set a default account."
    ]);
    exit;
}

// Get customer account ID from code
$customerQuery = mysqli_query($connection, "
    SELECT id, code, name, type, status
    FROM accounts
    WHERE code = '$customer_account_code'
    LIMIT 1
");

if (!$customerQuery || mysqli_num_rows($customerQuery) === 0) {
    http_response_code(404);
    echo json_encode([
        "code" => 404,
        "status" => "error",
        "message" => "Customer account not found."
    ]);
    exit;
}

$customer = mysqli_fetch_assoc($customerQuery);
$customer_account_id = $customer['id'];

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

// Insert milk sale
$insertQuery = "
    INSERT INTO milk_sales (
        supplier_account_id,
        customer_account_id,
        quantity,
        unit_price,
        status,
        sale_at,
        notes,
        recorded_by,
        created_by
    )
    VALUES (
        $supplier_account_id,
        $customer_account_id,
        $quantity,
        $unit_price,
        '$status',
        '$sale_at',
        " . ($notes ? "'$notes'" : "NULL") . ",
        $recorded_by,
        $recorded_by
    )
";

if (mysqli_query($connection, $insertQuery)) {
    echo json_encode([
        "code" => 200,
        "status" => "success",
        "message" => "Milk sale recorded successfully."
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        "code" => 500,
        "status" => "error",
        "message" => "Failed to record milk sale.",
        "db_error" => mysqli_error($connection), // DEBUG: shows actual DB error
        "sql" => $insertQuery                   // DEBUG: shows full SQL
    ]);
}
?>
