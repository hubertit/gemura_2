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

// Get aggregated metrics
$metricsQuery = mysqli_query($connection, "
    SELECT 
        COUNT(*) as total_transactions,
        SUM(s.quantity) as total_volume,
        SUM(s.quantity * s.unit_price) as total_revenue,
        AVG(s.unit_price) as avg_unit_price,
        MIN(s.sale_at) as first_transaction,
        MAX(s.sale_at) as last_transaction,
        COUNT(DISTINCT s.supplier_account_id) + COUNT(DISTINCT s.customer_account_id) as unique_partners
    FROM milk_sales s
    WHERE $whereClause
");

if (!$metricsQuery) {
    http_response_code(500);
    echo json_encode([
        "code" => 500,
        "status" => "error",
        "message" => "Database error: " . mysqli_error($connection)
    ]);
    exit;
}

$metrics = mysqli_fetch_assoc($metricsQuery);

// Get monthly trends - no date filtering, return all data
$monthlyTrends = [];
$trendsQuery = mysqli_query($connection, "
    SELECT 
        DATE_FORMAT(s.sale_at, '%Y-%m') as month,
        COUNT(*) as transactions,
        SUM(s.quantity) as volume,
        SUM(s.quantity * s.unit_price) as revenue,
        AVG(s.unit_price) as avg_price
    FROM milk_sales s
    WHERE $whereClause
    GROUP BY DATE_FORMAT(s.sale_at, '%Y-%m')
    ORDER BY month ASC
");

if ($trendsQuery) {
    while ($row = mysqli_fetch_assoc($trendsQuery)) {
        $monthlyTrends[] = [
            "month" => $row['month'],
            "transactions" => (int)$row['transactions'],
            "volume" => (float)$row['volume'],
            "revenue" => (float)$row['revenue'],
            "avg_price" => (float)$row['avg_price']
        ];
    }
}

// Prepare response data
$responseData = [
    "summary" => [
        "total_transactions" => (int)$metrics['total_transactions'],
        "total_volume" => (float)$metrics['total_volume'],
        "total_revenue" => (float)$metrics['total_revenue'],
        "avg_unit_price" => (float)$metrics['avg_unit_price'],
        "unique_partners" => (int)$metrics['unique_partners'],
        "first_transaction" => $metrics['first_transaction'],
        "last_transaction" => $metrics['last_transaction']
    ],
    "monthly_trends" => $monthlyTrends,
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
    "message" => "Metrics data retrieved successfully",
    "data" => $responseData
]);
?>
