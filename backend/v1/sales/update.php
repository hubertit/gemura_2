<?php
require_once("../configs/configs.php");
header('Content-Type: application/json');

$input_data = file_get_contents("php://input");
$data = json_decode($input_data, true);

// Validate input
if (empty($data['token']) || empty($data['sale_id'])) {
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Missing required fields (token, sale_id)."
    ]);
    exit;
}

$token   = mysqli_real_escape_string($connection, $data['token']);
$sale_id = intval($data['sale_id']);

// Authenticate user with default account
$userQuery = mysqli_query($connection, "
    SELECT u.id, u.default_account_id AS account_id, a.name AS account_name
    FROM users u
    LEFT JOIN accounts a ON a.id = u.default_account_id
    WHERE u.token = '$token' AND u.status = 'active'
    LIMIT 1
");

if (!$userQuery || mysqli_num_rows($userQuery) === 0) {
    echo json_encode([
        "code" => 403,
        "status" => "error",
        "message" => "Unauthorized. Invalid token."
    ]);
    exit;
}

$user = mysqli_fetch_assoc($userQuery);
$supplier_account_id = $user['account_id'];
$currentUserId = $user['id'];

// Check if user has a valid default account
if (!$supplier_account_id || !$user['account_name']) {
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "No valid default account found. Please set a default account."
    ]);
    exit;
}

// Validate sale belongs to supplier
$checkSale = mysqli_query($connection, "
    SELECT id FROM milk_sales
    WHERE id = $sale_id AND supplier_account_id = $supplier_account_id
    LIMIT 1
");

if (!$checkSale || mysqli_num_rows($checkSale) === 0) {
    echo json_encode([
        "code" => 404,
        "status" => "error",
        "message" => "Sale not found or not owned by this supplier."
    ]);
    exit;
}

// Prepare update values
$customer_code = !empty($data['customer_account_code']) ? mysqli_real_escape_string($connection, $data['customer_account_code']) : null;
$quantity      = isset($data['quantity']) ? floatval($data['quantity']) : null;
$status        = !empty($data['status']) ? mysqli_real_escape_string($connection, $data['status']) : null;
$sale_at       = !empty($data['sale_at']) ? mysqli_real_escape_string($connection, $data['sale_at']) : null;
$notes         = !empty($data['notes']) ? mysqli_real_escape_string($connection, $data['notes']) : null;

// If customer account code provided, fetch ID
$customer_account_id = null;
if ($customer_code) {
    $res = mysqli_query($connection, "SELECT id FROM accounts WHERE code = '$customer_code' LIMIT 1");
    if ($res && mysqli_num_rows($res) > 0) {
        $row = mysqli_fetch_assoc($res);
        $customer_account_id = $row['id'];
    }
}

// Build update query
$updateFields = [];
if ($customer_account_id) $updateFields[] = "customer_account_id = $customer_account_id";
if ($quantity !== null)   $updateFields[] = "quantity = $quantity";
if ($status)              $updateFields[] = "status = '$status'";
if ($sale_at)             $updateFields[] = "sale_at = '$sale_at'";
if ($notes)               $updateFields[] = "notes = '$notes'";
$updateFields[] = "updated_by = $currentUserId";

if (empty($updateFields)) {
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "No fields to update."
    ]);
    exit;
}

$updateQuery = "UPDATE milk_sales SET " . implode(", ", $updateFields) . " WHERE id = $sale_id";
$updated = mysqli_query($connection, $updateQuery);

if ($updated) {
    echo json_encode([
        "code" => 200,
        "status" => "success",
        "message" => "Sale updated successfully."
    ]);
} else {
    echo json_encode([
        "code" => 500,
        "status" => "error",
        "message" => "Failed to update sale.",
        "db_error" => mysqli_error($connection)
    ]);
}
?>
