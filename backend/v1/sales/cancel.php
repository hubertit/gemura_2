<?php
require_once("../configs/configs.php");
header('Content-Type: application/json');

$input_data = file_get_contents("php://input");
$data = json_decode($input_data, true);

// Validate token + sale_id
if (empty($data['token']) || empty($data['sale_id'])) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Missing token or sale_id."
    ]);
    exit;
}

$token   = mysqli_real_escape_string($connection, $data['token']);
$sale_id = (int)$data['sale_id'];

// Authenticate user with default account
$userQuery = mysqli_query($connection, "
    SELECT u.id, u.default_account_id AS account_id, a.name AS account_name
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

// Ensure the sale belongs to this supplier
$saleCheck = mysqli_query($connection, "
    SELECT id FROM milk_sales 
    WHERE id = $sale_id AND supplier_account_id = $supplier_account_id
    LIMIT 1
");

if (!$saleCheck || mysqli_num_rows($saleCheck) === 0) {
    http_response_code(404);
    echo json_encode([
        "code" => 404,
        "status" => "error",
        "message" => "Sale not found or not authorized."
    ]);
    exit;
}

// Update status → cancelled
$update = mysqli_query($connection, "
    UPDATE milk_sales 
    SET status = 'cancelled', updated_at = NOW() 
    WHERE id = $sale_id
");

if ($update) {
    echo json_encode([
        "code" => 200,
        "status" => "success",
        "message" => "Sale cancelled successfully."
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        "code" => 500,
        "status" => "error",
        "message" => "Failed to cancel sale."
    ]);
}
?>
