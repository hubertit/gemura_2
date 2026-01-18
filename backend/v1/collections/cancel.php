<?php
require_once("../configs/configs.php");
header('Content-Type: application/json');

$input_data = file_get_contents("php://input");
$data = json_decode($input_data, true);

// Validate token + collection_id
if (empty($data['token']) || empty($data['collection_id'])) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Missing token or collection_id."
    ]);
    exit;
}

$token = mysqli_real_escape_string($connection, $data['token']);
$collection_id = (int)$data['collection_id'];

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
           s.supplier_account_id, s.customer_account_id,
           sa.code AS supplier_code, sa.name AS supplier_name,
           ca.code AS customer_code, ca.name AS customer_name
    FROM milk_sales s
    JOIN accounts sa ON s.supplier_account_id = sa.id
    JOIN accounts ca ON s.customer_account_id = ca.id
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

// Update status → cancelled
$update = mysqli_query($connection, "
    UPDATE milk_sales 
    SET status = 'cancelled', updated_at = NOW() 
    WHERE id = $collection_id
");

if ($update) {
    echo json_encode([
        "code" => 200,
        "status" => "success",
        "message" => "Collection cancelled successfully."
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        "code" => 500,
        "status" => "error",
        "message" => "Failed to cancel collection."
    ]);
}
?>
