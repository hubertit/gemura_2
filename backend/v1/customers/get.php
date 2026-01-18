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

// Fetch active customers linked to this supplier
$query = mysqli_query($connection, "
    SELECT sc.id, sc.price_per_liter, sc.average_supply_quantity, sc.relationship_status, sc.created_at,
           cu.code AS customer_user_code, cu.name AS customer_name, cu.phone AS customer_phone, 
           cu.email AS customer_email, cu.nid AS customer_nid, cu.address AS customer_address,
           ca.code AS customer_account_code, ca.name AS customer_account_name, 
           ca.type AS customer_account_type, ca.status AS customer_account_status
    FROM suppliers_customers sc
    JOIN accounts ca ON sc.customer_account_id = ca.id
    JOIN user_accounts cua ON cua.account_id = ca.id
    JOIN users cu ON cu.id = cua.user_id
    WHERE sc.supplier_account_id = $supplier_account_id
      AND sc.relationship_status = 'active'
    ORDER BY sc.created_at DESC
");

$customers = [];
if ($query && mysqli_num_rows($query) > 0) {
    while ($row = mysqli_fetch_assoc($query)) {
        $customers[] = [
            "relationship_id" => $row['id'],
            "price_per_liter" => $row['price_per_liter'],
            "average_supply_quantity" => $row['average_supply_quantity'],
            "relationship_status" => $row['relationship_status'],
            "created_at" => $row['created_at'],
            "code" => $row['customer_user_code'], // still keeping user code for reference
            "name" => $row['customer_name'],
            "phone" => $row['customer_phone'],
            "email" => $row['customer_email'],
            "nid" => $row['customer_nid'],
            "address" => $row['customer_address'],
            "account" => [
                "code" => $row['customer_account_code'],
                "name" => $row['customer_account_name'],
                "type" => $row['customer_account_type'],
                "status" => $row['customer_account_status']
            ]
        ];
    }
}

echo json_encode([
    "code" => 200,
    "status" => "success",
    "message" => "Customers fetched successfully.",
    "data" => $customers
]);
?>
