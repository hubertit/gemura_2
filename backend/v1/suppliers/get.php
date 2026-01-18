<?php
require_once("../configs/configs.php");
header('Content-Type: application/json');

$input_data = file_get_contents("php://input");
$data = json_decode($input_data, true);

// Validate token
if (empty($data['token'])) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Missing token."
    ]);
    exit;
}

$token = mysqli_real_escape_string($connection, $data['token']);

// Get logged in user with default account only
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

// Fetch suppliers linked to this customer, latest first
$query = mysqli_query($connection, "
    SELECT sc.id, sc.price_per_liter, sc.average_supply_quantity, sc.relationship_status, sc.created_at,
           su.code AS supplier_user_code, su.name AS supplier_name,
           su.phone AS supplier_phone, su.email AS supplier_email,
           su.nid AS supplier_nid, su.address AS supplier_address,
           sa.code AS supplier_account_code, sa.name AS supplier_account_name,
           sa.type AS supplier_account_type, sa.status AS supplier_account_status
    FROM suppliers_customers sc
    JOIN accounts sa ON sc.supplier_account_id = sa.id
    JOIN user_accounts sua ON sua.account_id = sa.id
    JOIN users su ON su.id = sua.user_id
    WHERE sc.customer_account_id = $customer_account_id
      AND sc.relationship_status = 'active'
    ORDER BY sc.created_at DESC
");

$suppliers = [];
if ($query && mysqli_num_rows($query) > 0) {
    while ($row = mysqli_fetch_assoc($query)) {
        $suppliers[] = [
            "relationship_id" => $row['id'],
            "price_per_liter" => $row['price_per_liter'],
            "average_supply_quantity" => $row['average_supply_quantity'],
            "relationship_status" => $row['relationship_status'],
            "created_at" => $row['created_at'],
            "code" => $row['supplier_user_code'], // still keeping user code
            "name" => $row['supplier_name'],
            "phone" => $row['supplier_phone'],
            "email" => $row['supplier_email'],
            "nid" => $row['supplier_nid'],
            "address" => $row['supplier_address'],
            "account" => [
                "code" => $row['supplier_account_code'],
                "name" => $row['supplier_account_name'],
                "type" => $row['supplier_account_type'],
                "status" => $row['supplier_account_status']
            ]
        ];
    }
}

echo json_encode([
    "code" => 200,
    "status" => "success",
    "message" => "Suppliers fetched successfully.",
    "data" => $suppliers
]);
?>
