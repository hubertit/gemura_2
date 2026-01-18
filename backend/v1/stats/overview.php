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

// Get logged in user and their default account
$userQuery = mysqli_query($connection, "
    SELECT 
        u.id AS user_id,
        u.default_account_id,
        a.id AS account_id,
        a.type AS account_type
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

// Check if user has a default account
if (!$user['default_account_id'] || !$user['account_id']) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "No default account set. Please select an account first."
    ]);
    exit;
}

$account_id = $user['account_id'];
$account_type = $user['account_type'];

// Override date filtering - return all data regardless of date ranges
// Initialize response data
$response_data = [];

// Get collections data (customer perspective) - no date filtering
$collectionsWhereClause = "s.customer_account_id = $account_id AND s.status != 'deleted'";

$collectionsQuery = mysqli_query($connection, "
    SELECT 
        SUM(s.quantity) as total_quantity,
        SUM(s.quantity * s.unit_price) as total_value,
        COUNT(*) as total_transactions
    FROM milk_sales s
    WHERE $collectionsWhereClause
");

$collections = mysqli_fetch_assoc($collectionsQuery);

// Get sales data (supplier perspective) - no date filtering
$salesWhereClause = "s.supplier_account_id = $account_id AND s.status != 'deleted'";

$salesQuery = mysqli_query($connection, "
    SELECT 
        SUM(s.quantity) as total_quantity,
        SUM(s.quantity * s.unit_price) as total_value,
        COUNT(*) as total_transactions
    FROM milk_sales s
    WHERE $salesWhereClause
");

$sales = mysqli_fetch_assoc($salesQuery);

// Get suppliers count (active and inactive)
$suppliersQuery = mysqli_query($connection, "
    SELECT 
        SUM(CASE WHEN sc.relationship_status = 'active' THEN 1 ELSE 0 END) as active_suppliers,
        SUM(CASE WHEN sc.relationship_status = 'inactive' THEN 1 ELSE 0 END) as inactive_suppliers
    FROM suppliers_customers sc
    WHERE sc.customer_account_id = $account_id
");

$suppliers = mysqli_fetch_assoc($suppliersQuery);

// Get customers count (active and inactive)
$customersQuery = mysqli_query($connection, "
    SELECT 
        SUM(CASE WHEN sc.relationship_status = 'active' THEN 1 ELSE 0 END) as active_customers,
        SUM(CASE WHEN sc.relationship_status = 'inactive' THEN 1 ELSE 0 END) as inactive_customers
    FROM suppliers_customers sc
    WHERE sc.supplier_account_id = $account_id
");

$customers = mysqli_fetch_assoc($customersQuery);

$response_data['summary'] = [
    "collection" => [
        "liters" => floatval($collections['total_quantity'] ?? 0),
        "value" => floatval($collections['total_value'] ?? 0),
        "transactions" => intval($collections['total_transactions'] ?? 0)
    ],
    "sales" => [
        "liters" => floatval($sales['total_quantity'] ?? 0),
        "value" => floatval($sales['total_value'] ?? 0),
        "transactions" => intval($sales['total_transactions'] ?? 0)
    ],
    "suppliers" => [
        "active" => intval($suppliers['active_suppliers'] ?? 0),
        "inactive" => intval($suppliers['inactive_suppliers'] ?? 0)
    ],
    "customers" => [
        "active" => intval($customers['active_customers'] ?? 0),
        "inactive" => intval($customers['inactive_customers'] ?? 0)
    ]
];

// Generate daily breakdown - no date filtering, return all data
$breakdownQuery = mysqli_query($connection, "
    SELECT 
        DATE(s.sale_at) as date,
        SUM(CASE WHEN s.supplier_account_id = $account_id THEN s.quantity ELSE 0 END) as sales_quantity,
        SUM(CASE WHEN s.supplier_account_id = $account_id THEN s.quantity * s.unit_price ELSE 0 END) as sales_value,
        SUM(CASE WHEN s.customer_account_id = $account_id THEN s.quantity ELSE 0 END) as collection_quantity,
        SUM(CASE WHEN s.customer_account_id = $account_id THEN s.quantity * s.unit_price ELSE 0 END) as collection_value
    FROM milk_sales s
    WHERE (s.supplier_account_id = $account_id OR s.customer_account_id = $account_id)
      AND s.status != 'deleted'
    GROUP BY DATE(s.sale_at)
    ORDER BY date ASC
");

$breakdown = [];
if ($breakdownQuery && mysqli_num_rows($breakdownQuery) > 0) {
    while ($row = mysqli_fetch_assoc($breakdownQuery)) {
        $date = new DateTime($row['date']);
        $breakdown[] = [
            "label" => $date->format('D'), // Mon, Tue, Wed, etc.
            "date" => $row['date'],
            "collection" => [
                "liters" => floatval($row['collection_quantity'] ?? 0),
                "value" => floatval($row['collection_value'] ?? 0)
            ],
            "sales" => [
                "liters" => floatval($row['sales_quantity'] ?? 0),
                "value" => floatval($row['sales_value'] ?? 0)
            ]
        ];
    }
}

$response_data['breakdown_type'] = 'daily';
$response_data['chart_period'] = 'last_7_days';

$response_data['breakdown'] = $breakdown;

// Get recent transactions (last 10 sales and collections)
$recentTransactionsQuery = mysqli_query($connection, "
    SELECT 
        s.id,
        s.quantity,
        s.unit_price,
        (s.quantity * s.unit_price) as total_amount,
        s.status,
        s.sale_at,
        s.notes,
        s.created_at,
        
        -- Supplier account info
        sa.code AS supplier_code,
        sa.name AS supplier_name,
        sa.type AS supplier_type,
        sa.status AS supplier_status,
        
        -- Customer account info
        ca.code AS customer_code,
        ca.name AS customer_name,
        ca.type AS customer_type,
        ca.status AS customer_status,
        
        -- Transaction type
        CASE 
            WHEN s.supplier_account_id = $account_id THEN 'sale'
            WHEN s.customer_account_id = $account_id THEN 'collection'
            ELSE 'unknown'
        END as transaction_type
        
    FROM milk_sales s
    JOIN accounts sa ON s.supplier_account_id = sa.id
    JOIN accounts ca ON s.customer_account_id = ca.id
    WHERE (s.supplier_account_id = $account_id OR s.customer_account_id = $account_id)
      AND s.status != 'deleted'
    ORDER BY s.sale_at DESC
    LIMIT 10
");

$recent_transactions = [];
if ($recentTransactionsQuery && mysqli_num_rows($recentTransactionsQuery) > 0) {
    while ($row = mysqli_fetch_assoc($recentTransactionsQuery)) {
        $transaction = [
            "id" => $row['id'],
            "quantity" => floatval($row['quantity']),
            "unit_price" => floatval($row['unit_price']),
            "total_amount" => floatval($row['total_amount']),
            "status" => $row['status'],
            "transaction_at" => $row['sale_at'],
            "notes" => $row['notes'],
            "created_at" => $row['created_at'],
            "type" => $row['transaction_type'], // 'sale' or 'collection'
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
        
        $recent_transactions[] = $transaction;
    }
}

$response_data['recent_transactions'] = $recent_transactions;
$response_data['date_range'] = [
    "from" => "2024-01-01",
    "to" => "2027-01-31"
];

echo json_encode([
    "code" => 200,
    "status" => "success",
    "message" => "Overview data fetched successfully.",
    "data" => $response_data
]);
?>
