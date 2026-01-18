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

// Get logged in user with default account
$userQuery = mysqli_query($connection, "
    SELECT u.id AS user_id, u.default_account_id AS account_id, a.name AS account_name, a.type AS account_type
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
$account_id = $user['account_id'];
$account_type = $user['account_type'];

// Check if user has a valid default account
if (!$account_id || !$user['account_name']) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "No valid default account found. Please set a default account."
    ]);
    exit;
}

// Get requested sections (default to all if not specified)
$sections = !empty($data['sections']) ? explode(',', $data['sections']) : ['accounts', 'wallets', 'relationships', 'transactions', 'performance'];
// Override date filtering - return all data regardless of date ranges

$response_data = [];

// 1. Accounts Statistics
if (in_array('accounts', $sections)) {
    $accountsQuery = mysqli_query($connection, "
        SELECT 
            COUNT(DISTINCT a.id) as total_accounts,
            SUM(CASE WHEN a.type = 'supplier' THEN 1 ELSE 0 END) as suppliers,
            SUM(CASE WHEN a.type = 'customer' THEN 1 ELSE 0 END) as customers,
            SUM(CASE WHEN a.status = 'active' THEN 1 ELSE 0 END) as active_accounts
        FROM accounts a
        WHERE a.status != 'deleted'
    ");
    
    $accounts = mysqli_fetch_assoc($accountsQuery);
    
    $response_data['accounts'] = [
        "total" => intval($accounts['total_accounts'] ?? 0),
        "suppliers" => intval($accounts['suppliers'] ?? 0),
        "customers" => intval($accounts['customers'] ?? 0),
        "active" => intval($accounts['active_accounts'] ?? 0)
    ];
}

// 2. Wallets Statistics
if (in_array('wallets', $sections)) {
    $walletsQuery = mysqli_query($connection, "
        SELECT 
            COUNT(*) as total_wallets,
            SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) as active_wallets,
            SUM(balance) as total_balance,
            SUM(CASE WHEN is_default = 1 THEN 1 ELSE 0 END) as default_wallets
        FROM wallets
        WHERE status != 'deleted'
    ");
    
    $wallets = mysqli_fetch_assoc($walletsQuery);
    
    $response_data['wallets'] = [
        "total" => intval($wallets['total_wallets'] ?? 0),
        "active" => intval($wallets['active_wallets'] ?? 0),
        "total_balance" => floatval($wallets['total_balance'] ?? 0),
        "default_wallets" => intval($wallets['default_wallets'] ?? 0)
    ];
}

// 3. Relationships Statistics
if (in_array('relationships', $sections)) {
    $relationshipsQuery = mysqli_query($connection, "
        SELECT 
            COUNT(*) as total_relationships,
            SUM(CASE WHEN relationship_status = 'active' THEN 1 ELSE 0 END) as active_relationships
        FROM suppliers_customers
        WHERE relationship_status != 'deleted'
    ");
    
    $relationships = mysqli_fetch_assoc($relationshipsQuery);
    
    $response_data['relationships'] = [
        "total" => intval($relationships['total_relationships'] ?? 0),
        "active" => intval($relationships['active_relationships'] ?? 0)
    ];
}

// 4. Transactions Statistics
if (in_array('transactions', $sections)) {
    $transactionsQuery = mysqli_query($connection, "
        SELECT 
            COUNT(*) as total_transactions,
            SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed_transactions,
            SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) as cancelled_transactions,
            SUM(quantity) as total_volume,
            SUM(quantity * unit_price) as total_revenue
        FROM milk_sales
        WHERE status != 'deleted'
    ");
    
    $transactions = mysqli_fetch_assoc($transactionsQuery);
    
    $response_data['transactions'] = [
        "total" => intval($transactions['total_transactions'] ?? 0),
        "completed" => intval($transactions['completed_transactions'] ?? 0),
        "cancelled" => intval($transactions['cancelled_transactions'] ?? 0),
        "total_volume" => floatval($transactions['total_volume'] ?? 0),
        "total_revenue" => floatval($transactions['total_revenue'] ?? 0),
        "average_per_transaction" => $transactions['total_transactions'] > 0 ? 
            floatval($transactions['total_volume'] / $transactions['total_transactions']) : 0
    ];
}

// 5. Performance Statistics (Top Performers)
if (in_array('performance', $sections)) {
    // Top Suppliers by Volume - no date filtering
    $topSuppliersQuery = mysqli_query($connection, "
        SELECT 
            a.name,
            SUM(s.quantity) as total_volume,
            SUM(s.quantity * s.unit_price) as total_revenue
        FROM milk_sales s
        JOIN accounts a ON s.supplier_account_id = a.id
        WHERE s.status = 'completed'
        GROUP BY s.supplier_account_id, a.name
        ORDER BY total_volume DESC
        LIMIT 5
    ");
    
    $top_suppliers = [];
    if ($topSuppliersQuery && mysqli_num_rows($topSuppliersQuery) > 0) {
        while ($row = mysqli_fetch_assoc($topSuppliersQuery)) {
            $top_suppliers[] = [
                "name" => $row['name'],
                "volume" => floatval($row['total_volume']),
                "revenue" => floatval($row['total_revenue'])
            ];
        }
    }
    
    // Top Customers by Volume - no date filtering
    $topCustomersQuery = mysqli_query($connection, "
        SELECT 
            a.name,
            SUM(s.quantity) as total_volume,
            SUM(s.quantity * s.unit_price) as total_spent
        FROM milk_sales s
        JOIN accounts a ON s.customer_account_id = a.id
        WHERE s.status = 'completed'
        GROUP BY s.customer_account_id, a.name
        ORDER BY total_volume DESC
        LIMIT 5
    ");
    
    $top_customers = [];
    if ($topCustomersQuery && mysqli_num_rows($topCustomersQuery) > 0) {
        while ($row = mysqli_fetch_assoc($topCustomersQuery)) {
            $top_customers[] = [
                "name" => $row['name'],
                "volume" => floatval($row['total_volume']),
                "spent" => floatval($row['total_spent'])
            ];
        }
    }
    
    $response_data['performance'] = [
        "top_suppliers" => $top_suppliers,
        "top_customers" => $top_customers
    ];
}

// Add date range info - all data returned regardless of date ranges
$response_data['date_range'] = [
    "from" => "2024-01-01",
    "to" => "2027-01-31"
];

echo json_encode([
    "code" => 200,
    "status" => "success",
    "message" => "Statistics fetched successfully.",
    "data" => $response_data
]);
?>
