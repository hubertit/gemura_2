<?php
require_once("../configs/configs.php");
header('Content-Type: application/json');

$input_data = file_get_contents("php://input");
$data = json_decode($input_data, true);

// Validate input
if (empty($data['token']) || empty($data['relationship_id'])) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Token and relationship_id are required."
    ]);
    exit;
}

$token = mysqli_real_escape_string($connection, $data['token']);
$relationship_id = intval($data['relationship_id']);

// Get logged-in supplier with default account
$userQuery = mysqli_query($connection, "
    SELECT u.id, u.default_account_id AS account_id, a.name AS account_name
    FROM users u
    LEFT JOIN accounts a ON a.id = u.default_account_id
    WHERE u.token = '$token' AND u.status = 'active' LIMIT 1
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

// Update relationship_status
$update = mysqli_query($connection, "
    UPDATE suppliers_customers 
    SET relationship_status = 'inactive', updated_at = NOW()
    WHERE id = $relationship_id 
      AND supplier_account_id = $supplier_account_id
");

if ($update && mysqli_affected_rows($connection) > 0) {
    echo json_encode([
        "code" => 200,
        "status" => "success",
        "message" => "Customer relationship deactivated successfully."
    ]);
} else {
    http_response_code(404);
    echo json_encode([
        "code" => 404,
        "status" => "error",
        "message" => "Customer relationship not found or already inactive."
    ]);
}
?>
