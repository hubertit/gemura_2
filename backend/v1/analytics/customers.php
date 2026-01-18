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

// Get customer analytics
$customersQuery = mysqli_query($connection, "
    SELECT 
        a.id,
        a.name,
        a.code,
        a.type,
        a.status,
        a.created_at,
        COUNT(s.id) as total_transactions,
        SUM(s.quantity) as total_volume,
        SUM(s.quantity * s.unit_price) as total_revenue,
        AVG(s.unit_price) as avg_unit_price,
        MIN(s.sale_at) as first_transaction,
        MAX(s.sale_at) as last_transaction,
        DATEDIFF(MAX(s.sale_at), MIN(s.sale_at)) as days_active
    FROM accounts a
    LEFT JOIN milk_sales s ON (s.customer_account_id = a.id OR s.supplier_account_id = a.id) AND s.status != 'deleted'
    WHERE a.id IN (
        SELECT DISTINCT customer_account_id FROM milk_sales WHERE $whereClause
        UNION
        SELECT DISTINCT supplier_account_id FROM milk_sales WHERE $whereClause
    )
    GROUP BY a.id, a.name, a.code, a.type, a.status, a.created_at
    ORDER BY total_revenue DESC
");

if (!$customersQuery) {
    http_response_code(500);
    echo json_encode([
        "code" => 500,
        "status" => "error",
        "message" => "Database error: " . mysqli_error($connection)
    ]);
    exit;
}

$customers = [];
while ($row = mysqli_fetch_assoc($customersQuery)) {
    $customers[] = [
        "id" => (int)$row['id'],
        "name" => $row['name'],
        "code" => $row['code'],
        "type" => $row['type'],
        "status" => $row['status'],
        "created_at" => $row['created_at'],
        "analytics" => [
            "total_transactions" => (int)$row['total_transactions'],
            "total_volume" => (float)$row['total_volume'],
            "total_revenue" => (float)$row['total_revenue'],
            "avg_unit_price" => (float)$row['avg_unit_price'],
            "first_transaction" => $row['first_transaction'],
            "last_transaction" => $row['last_transaction'],
            "days_active" => (int)$row['days_active']
        ]
    ];
}

// Get top customers summary
$topCustomersQuery = mysqli_query($connection, "
    SELECT 
        a.name,
        SUM(s.quantity * s.unit_price) as total_revenue,
        COUNT(s.id) as transaction_count
    FROM milk_sales s
    LEFT JOIN accounts a ON (a.id = s.customer_account_id OR a.id = s.supplier_account_id)
    WHERE $whereClause
    GROUP BY a.id, a.name
    ORDER BY total_revenue DESC
    LIMIT 5
");

$topCustomers = [];
if ($topCustomersQuery) {
    while ($row = mysqli_fetch_assoc($topCustomersQuery)) {
        $topCustomers[] = [
            "name" => $row['name'],
            "total_revenue" => (float)$row['total_revenue'],
            "transaction_count" => (int)$row['transaction_count']
        ];
    }
}

// Prepare response data
$responseData = [
    "customers" => $customers,
    "top_customers" => $topCustomers,
    "account_code" => $account_code,
    "date_range" => [
        "from" => "2024-01-01",
        "to" => "2027-01-31"
    ]
];

// Return success response
echo json_encode([
    "code" => 200,
    "status" => "success",
    "message" => "Customer analytics data retrieved successfully",
    "data" => $responseData
]);
?>
