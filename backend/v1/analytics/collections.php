<?php
require_once("../configs/configs.php");

// Get parameters from GET request
$token = isset($_GET['token']) ? mysqli_real_escape_string($connection, $_GET['token']) : '';
$date_from = isset($_GET['date_from']) ? mysqli_real_escape_string($connection, $_GET['date_from']) : '';
$date_to = isset($_GET['date_to']) ? mysqli_real_escape_string($connection, $_GET['date_to']) : '';
$account_code = isset($_GET['account_code']) ? mysqli_real_escape_string($connection, $_GET['account_code']) : '';

// Validate token
if (empty($token)) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Missing token parameter."
    ]);
    exit;
}

// Validate token (just check if it's valid, don't restrict by user account)
$userQuery = mysqli_query($connection, "
    SELECT u.id AS user_id
    FROM users u
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

// Override date filtering - return all data regardless of date ranges
// Build WHERE clause - start with basic filter
$whereClause = "s.status != 'deleted'";

// Add account code filtering if provided
if (!empty($account_code)) {
    $whereClause .= " AND (s.customer_account_id IN (SELECT id FROM accounts WHERE code = '$account_code') OR s.supplier_account_id IN (SELECT id FROM accounts WHERE code = '$account_code'))";
}

// Date filtering removed - return all data

// Get collections data
       $collectionsQuery = mysqli_query($connection, "
           SELECT
               s.id,
               s.supplier_account_id,
               s.customer_account_id,
               sup.name as supplier_name,
               sup.code as supplier_code,
               c.name as customer_name,
               c.code as customer_code,
               s.quantity,
               s.unit_price,
               (s.quantity * s.unit_price) as total_price,
               s.sale_at,
               s.status,
               s.notes,
               s.recorded_by,
               s.created_at,
               s.updated_at
           FROM milk_sales s
           LEFT JOIN accounts sup ON sup.id = s.supplier_account_id
           LEFT JOIN accounts c ON c.id = s.customer_account_id
           WHERE $whereClause
           ORDER BY s.sale_at DESC
       ");

if (!$collectionsQuery) {
    http_response_code(500);
    echo json_encode([
        "code" => 500,
        "status" => "error",
        "message" => "Database error: " . mysqli_error($connection)
    ]);
    exit;
}

$collections = [];
while ($row = mysqli_fetch_assoc($collectionsQuery)) {
           $collections[] = [
           "id" => $row['id'],
           "supplier_account_id" => (int)$row['supplier_account_id'],
           "customer_account_id" => (int)$row['customer_account_id'],
           "supplier_name" => $row['supplier_name'],
           "supplier_code" => $row['supplier_code'],
           "customer_name" => $row['customer_name'],
           "customer_code" => $row['customer_code'],
           "quantity" => (float)$row['quantity'],
           "unit_price" => (float)$row['unit_price'],
           "total_price" => (float)$row['total_price'],
           "sale_at" => $row['sale_at'],
           "status" => $row['status'],
           "notes" => $row['notes'],
           "recorded_by" => (int)$row['recorded_by'],
           "created_at" => $row['created_at'],
           "updated_at" => $row['updated_at']
       ];
}

// Return success response
echo json_encode([
    "code" => 200,
    "status" => "success",
    "message" => "Collections data retrieved successfully",
    "data" => $collections,
    "date_range" => [
        "from" => "2024-01-01",
        "to" => "2027-01-31"
    ]
]);
?>
