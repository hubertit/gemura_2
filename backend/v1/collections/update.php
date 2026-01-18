<?php
require_once("../configs/configs.php");
header('Content-Type: application/json');

$input_data = file_get_contents("php://input");
$data = json_decode($input_data, true);

// Validate required fields
if (empty($data['token']) || empty($data['collection_id'])) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Token and collection_id are required."
    ]);
    exit;
}

$token = mysqli_real_escape_string($connection, $data['token']);
$collection_id = intval($data['collection_id']);

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

// Check if collection exists and belongs to this customer
$collectionQuery = mysqli_query($connection, "
    SELECT s.id, s.quantity, s.unit_price, s.status, s.sale_at, s.notes,
           s.supplier_account_id, s.customer_account_id
    FROM milk_sales s
    WHERE s.id = $collection_id 
      AND s.customer_account_id = $customer_account_id
      AND s.status != 'deleted'
    LIMIT 1
");

if (!$collectionQuery || mysqli_num_rows($collectionQuery) === 0) {
    http_response_code(404);
    echo json_encode([
        "code" => 404,
        "status" => "error",
        "message" => "Collection not found or access denied."
    ]);
    exit;
}

$collection = mysqli_fetch_assoc($collectionQuery);

// Build update fields
$updateFields = [];
$updateValues = [];

// Quantity update
if (isset($data['quantity']) && is_numeric($data['quantity'])) {
    $quantity = floatval($data['quantity']);
    if ($quantity > 0) {
        $updateFields[] = "quantity = ?";
        $updateValues[] = $quantity;
    }
}

// Status update
if (!empty($data['status'])) {
    $status = mysqli_real_escape_string($connection, $data['status']);
    $updateFields[] = "status = '$status'";
}

// Collection date update
if (!empty($data['collection_at'])) {
    $collection_at = mysqli_real_escape_string($connection, $data['collection_at']);
    $updateFields[] = "sale_at = '$collection_at'";
}

// Notes update
if (isset($data['notes'])) {
    $notes = mysqli_real_escape_string($connection, $data['notes']);
    $updateFields[] = "notes = '$notes'";
}

// Unit price update (optional - recalculate total)
if (isset($data['unit_price']) && is_numeric($data['unit_price'])) {
    $unit_price = floatval($data['unit_price']);
    if ($unit_price >= 0) {
        $updateFields[] = "unit_price = ?";
        $updateValues[] = $unit_price;
    }
}

// Check if there are fields to update
if (empty($updateFields)) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "No valid fields to update."
    ]);
    exit;
}

// Add updated_at timestamp
$updateFields[] = "updated_at = NOW()";

// Build and execute update query
$updateQuery = "UPDATE milk_sales SET " . implode(", ", $updateFields) . " WHERE id = $collection_id";

// Prepare statement if we have parameterized values
if (!empty($updateValues)) {
    $stmt = $connection->prepare($updateQuery);
    
    // Bind parameters
    $types = str_repeat('d', count($updateValues)); // 'd' for double/float
    $stmt->bind_param($types, ...$updateValues);
    
    $success = $stmt->execute();
    $stmt->close();
} else {
    $success = mysqli_query($connection, $updateQuery);
}

if ($success) {
    // Fetch updated collection data
    $updatedQuery = mysqli_query($connection, "
        SELECT s.id, s.quantity, s.unit_price, (s.quantity * s.unit_price) AS total_amount,
               s.status, s.sale_at, s.notes, s.created_at, s.updated_at,
               sa.code AS supplier_code, sa.name AS supplier_name,
               ca.code AS customer_code, ca.name AS customer_name
        FROM milk_sales s
        JOIN accounts sa ON s.supplier_account_id = sa.id
        JOIN accounts ca ON s.customer_account_id = ca.id
        WHERE s.id = $collection_id
    ");
    
    $updatedCollection = mysqli_fetch_assoc($updatedQuery);
    
    echo json_encode([
        "code" => 200,
        "status" => "success",
        "message" => "Collection updated successfully.",
        "data" => [
            "id" => $updatedCollection['id'],
            "quantity" => $updatedCollection['quantity'],
            "unit_price" => $updatedCollection['unit_price'],
            "total_amount" => $updatedCollection['total_amount'],
            "status" => $updatedCollection['status'],
            "collection_at" => $updatedCollection['sale_at'],
            "notes" => $updatedCollection['notes'],
            "created_at" => $updatedCollection['created_at'],
            "updated_at" => $updatedCollection['updated_at'],
            "supplier_account" => [
                "code" => $updatedCollection['supplier_code'],
                "name" => $updatedCollection['supplier_name']
            ],
            "customer_account" => [
                "code" => $updatedCollection['customer_code'],
                "name" => $updatedCollection['customer_name']
            ]
        ]
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        "code" => 500,
        "status" => "error",
        "message" => "Failed to update collection.",
        "db_error" => mysqli_error($connection)
    ]);
}
?>
