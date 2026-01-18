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
$filters = isset($data['filters']) ? $data['filters'] : [];

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

// Base query
$sql = "
    SELECT s.id, s.quantity, s.unit_price, (s.quantity * s.unit_price) AS total_amount,
           s.status, s.sale_at, s.notes, s.created_at,

           sa.code AS supplier_code, sa.name AS supplier_name, sa.type AS supplier_type, sa.status AS supplier_status,
           ca.code AS customer_code, ca.name AS customer_name, ca.type AS customer_type, ca.status AS customer_status

    FROM milk_sales s
    JOIN accounts sa ON s.supplier_account_id = sa.id
    JOIN accounts ca ON s.customer_account_id = ca.id
    WHERE s.supplier_account_id = $supplier_account_id
      AND s.status != 'deleted'
";

// Apply filters
if (!empty($filters['customer_account_code'])) {
    $customerCode = mysqli_real_escape_string($connection, $filters['customer_account_code']);
    $sql .= " AND ca.code = '$customerCode' ";
}
if (!empty($filters['status'])) {
    $status = mysqli_real_escape_string($connection, $filters['status']);
    $sql .= " AND s.status = '$status' ";
}
if (!empty($filters['date_from'])) {
    $date_from = mysqli_real_escape_string($connection, $filters['date_from']);
    $sql .= " AND DATE(s.sale_at) >= '$date_from' ";
}
if (!empty($filters['date_to'])) {
    $date_to = mysqli_real_escape_string($connection, $filters['date_to']);
    $sql .= " AND DATE(s.sale_at) <= '$date_to' ";
}
if (!empty($filters['quantity_min'])) {
    $qmin = floatval($filters['quantity_min']);
    $sql .= " AND s.quantity >= $qmin ";
}
if (!empty($filters['quantity_max'])) {
    $qmax = floatval($filters['quantity_max']);
    $sql .= " AND s.quantity <= $qmax ";
}
if (!empty($filters['price_min'])) {
    $pmin = floatval($filters['price_min']);
    $sql .= " AND s.unit_price >= $pmin ";
}
if (!empty($filters['price_max'])) {
    $pmax = floatval($filters['price_max']);
    $sql .= " AND s.unit_price <= $pmax ";
}

$sql .= " ORDER BY s.sale_at DESC ";

// Run query
$query = mysqli_query($connection, $sql);

$sales = [];
if ($query && mysqli_num_rows($query) > 0) {
    while ($row = mysqli_fetch_assoc($query)) {
        $sales[] = [
            "id" => $row['id'],
            "quantity" => $row['quantity'],
            "unit_price" => $row['unit_price'],
            "total_amount" => $row['total_amount'],
            "status" => $row['status'],
            "sale_at" => $row['sale_at'],
            "notes" => $row['notes'],
            "created_at" => $row['created_at'],
            "supplier_account" => [
                "code" => $row['supplier_code'],
                "name" => $row['supplier_name'],
                "type" => $row['supplier_type'],
                "status" => $row['supplier_status']
            ],
            "customer_account" => [
                "code" => $row['customer_code'],
                "name" => $row['customer_name'],
                "type" => $row['customer_type'],
                "status" => $row['customer_status']
            ]
        ];
    }
}

echo json_encode([
    "code" => 200,
    "status" => "success",
    "message" => "Sales fetched successfully.",
    "data" => $sales
]);
?>
