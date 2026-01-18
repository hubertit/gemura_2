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
$period = isset($data['period']) ? mysqli_real_escape_string($connection, $data['period']) : 'This Month';

// Get logged in user
$userQuery = mysqli_query($connection, "
    SELECT u.id, u.default_account_id, u.name as user_name
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

$user = mysqli_fetch_assoc($userQuery);
$userId = $user['id'];
$accountId = $user['default_account_id'];

// Check if user has a valid default account
if (!$accountId) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "No valid default account found."
    ]);
    exit;
}

// Calculate date range based on period
$dateRange = getDateRange($period);
$startDate = $dateRange['start'];
$endDate = $dateRange['end'];

// Get user's role and permissions
$roleQuery = mysqli_query($connection, "
    SELECT role, permissions FROM user_accounts 
    WHERE user_id = $userId AND account_id = $accountId AND status = 'active'
    LIMIT 1
");

$userRole = 'user';
$permissions = [];
if ($roleQuery && mysqli_num_rows($roleQuery) > 0) {
    $roleData = mysqli_fetch_assoc($roleQuery);
    $userRole = $roleData['role'];
    $permissions = $roleData['permissions'] ? json_decode($roleData['permissions'], true) : [];
}

// Initialize metrics
$metrics = [
    'totalSales' => 0.0,
    'totalCollections' => 0.0,
    'customersAdded' => 0,
    'suppliersAdded' => 0,
    'averageTransactionValue' => 0.0
];

// 1. Get Sales Data (milk_sales where user is supplier)
$salesQuery = mysqli_query($connection, "
    SELECT 
        COUNT(*) as total_sales_count,
        SUM(quantity * unit_price) as total_sales_amount,
        AVG(quantity * unit_price) as avg_transaction_value
    FROM milk_sales 
    WHERE supplier_account_id = $accountId 
      AND sale_at BETWEEN '$startDate' AND '$endDate'
      AND status = 'accepted'
");

if ($salesQuery && mysqli_num_rows($salesQuery) > 0) {
    $salesData = mysqli_fetch_assoc($salesQuery);
    $metrics['totalSales'] = floatval($salesData['total_sales_amount'] ?? 0);
    $metrics['averageTransactionValue'] = floatval($salesData['avg_transaction_value'] ?? 0);
}

// 2. Get Collections Data (milk_sales where user is customer)
$collectionsQuery = mysqli_query($connection, "
    SELECT 
        COUNT(*) as total_collections_count,
        SUM(quantity * unit_price) as total_collections_amount
    FROM milk_sales 
    WHERE customer_account_id = $accountId 
      AND sale_at BETWEEN '$startDate' AND '$endDate'
      AND status = 'accepted'
");

if ($collectionsQuery && mysqli_num_rows($collectionsQuery) > 0) {
    $collectionsData = mysqli_fetch_assoc($collectionsQuery);
    $metrics['totalCollections'] = floatval($collectionsData['total_collections_amount'] ?? 0);
}

// 3. Get Customers Added (if user has permission)
if (in_array('can_add_supplier', $permissions) || in_array($userRole, ['admin', 'owner', 'manager'])) {
    $customersQuery = mysqli_query($connection, "
        SELECT COUNT(*) as customers_added
        FROM suppliers_customers sc
        WHERE sc.supplier_account_id = $accountId
          AND sc.created_at BETWEEN '$startDate' AND '$endDate'
          AND sc.relationship_status = 'active'
    ");
    
    if ($customersQuery && mysqli_num_rows($customersQuery) > 0) {
        $customersData = mysqli_fetch_assoc($customersQuery);
        $metrics['customersAdded'] = intval($customersData['customers_added'] ?? 0);
    }
}

// 4. Get Suppliers Added (if user has permission)
if (in_array('can_add_supplier', $permissions) || in_array($userRole, ['admin', 'owner', 'manager'])) {
    $suppliersQuery = mysqli_query($connection, "
        SELECT COUNT(*) as suppliers_added
        FROM suppliers_customers sc
        WHERE sc.customer_account_id = $accountId
          AND sc.created_at BETWEEN '$startDate' AND '$endDate'
          AND sc.relationship_status = 'active'
    ");
    
    if ($suppliersQuery && mysqli_num_rows($suppliersQuery) > 0) {
        $suppliersData = mysqli_fetch_assoc($suppliersQuery);
        $metrics['suppliersAdded'] = intval($suppliersData['suppliers_added'] ?? 0);
    }
}







echo json_encode([
    "code" => 200,
    "status" => "success",
    "message" => "Report generated successfully",
    "data" => [
        "period" => $period,
        "user_role" => $userRole,
        "metrics" => $metrics
    ]
]);

// Helper function to get date range
function getDateRange($period) {
    $now = new DateTime();
    $start = new DateTime();
    $end = new DateTime();
    
    switch ($period) {
        case 'Today':
            $start->setTime(0, 0, 0);
            $end->setTime(23, 59, 59);
            break;
        case 'This Week':
            $start->modify('monday this week');
            $start->setTime(0, 0, 0);
            $end->modify('sunday this week');
            $end->setTime(23, 59, 59);
            break;
        case 'This Month':
            $start->modify('first day of this month');
            $start->setTime(0, 0, 0);
            $end->modify('last day of this month');
            $end->setTime(23, 59, 59);
            break;
        case 'Last Month':
            $start->modify('first day of last month');
            $start->setTime(0, 0, 0);
            $end->modify('last day of last month');
            $end->setTime(23, 59, 59);
            break;
        case 'This Year':
            $start->modify('first day of january this year');
            $start->setTime(0, 0, 0);
            $end->modify('last day of december this year');
            $end->setTime(23, 59, 59);
            break;
        default:
            $start->modify('first day of this month');
            $start->setTime(0, 0, 0);
            $end->modify('last day of this month');
            $end->setTime(23, 59, 59);
    }
    
    return [
        'start' => $start->format('Y-m-d H:i:s'),
        'end' => $end->format('Y-m-d H:i:s')
    ];
}
?>
