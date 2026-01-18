<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

require_once '../../shared/order-utils.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

try {
    // Get query parameters
    $customerId = isset($_GET['customer_id']) ? (int)$_GET['customer_id'] : null;
    $sellerId = isset($_GET['seller_id']) ? (int)$_GET['seller_id'] : null;
    $status = isset($_GET['status']) ? $_GET['status'] : null;
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 20;
    $page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
    $offset = ($page - 1) * $limit;

    // Build base query - admin can see all orders
    $sql = "SELECT 
                o.*,
                c.name as customer_name,
                c.phone as customer_phone,
                c.email as customer_email,
                s.name as seller_name,
                s.phone as seller_phone,
                s.email as seller_email,
                COUNT(oi.id) as total_items,
                SUM(oi.total_price) as calculated_total
            FROM orders o
            LEFT JOIN users c ON o.customer_id = c.id
            LEFT JOIN users s ON o.seller_id = s.id
            LEFT JOIN order_items oi ON o.id = oi.order_id";

    $whereConditions = [];

    if ($customerId) {
        $whereConditions[] = "o.customer_id = $customerId";
    }

    if ($sellerId) {
        $whereConditions[] = "o.seller_id = $sellerId";
    }

    if ($status) {
        $whereConditions[] = "o.status = '$status'";
    }

    if (!empty($whereConditions)) {
        $sql .= " WHERE " . implode(' AND ', $whereConditions);
    }

    $sql .= " GROUP BY o.id ORDER BY o.order_date DESC";

    // Get total count for pagination
    $countSql = "SELECT COUNT(DISTINCT o.id) as total FROM orders o";
    if (!empty($whereConditions)) {
        $countSql .= " WHERE " . implode(' AND ', $whereConditions);
    }
    
    $countResult = mysqli_query($connection, $countSql);
    $totalOrders = mysqli_fetch_assoc($countResult)['total'];

    // Add pagination
    $sql .= " LIMIT $limit OFFSET $offset";

    $result = mysqli_query($connection, $sql);

    if (!$result) {
        throw new Exception("Database error: " . mysqli_error($connection));
    }

    $orders = [];
    while ($row = mysqli_fetch_assoc($result)) {
        // Get order items using shared function
        $items = getOrderItems($connection, $row['id']);

        $orders[] = [
            'id' => (int)$row['id'],
            'order_no' => $row['order_no'],
            'customer_id' => (int)$row['customer_id'],
            'customer_name' => $row['customer_name'],
            'customer_phone' => $row['customer_phone'],
            'customer_email' => $row['customer_email'],
            'seller_id' => (int)$row['seller_id'],
            'seller_name' => $row['seller_name'],
            'seller_phone' => $row['seller_phone'],
            'seller_email' => $row['seller_email'],
            'total_amount' => (float)$row['total_amount'],
            'currency' => $row['currency'],
            'status' => $row['status'],
            'shipping_address' => $row['shipping_address'],
            'shipping_notes' => $row['shipping_notes'],
            'order_date' => $row['order_date'],
            'updated_at' => $row['updated_at'],
            'cancellation_reason' => $row['cancellation_reason'],
            'total_items' => (int)$row['total_items'],
            'calculated_total' => (float)$row['calculated_total'],
            'items' => $items
        ];
    }

    $totalPages = ceil($totalOrders / $limit);
    $hasNext = $page < $totalPages;
    $hasPrev = $page > 1;

    echo json_encode([
        'success' => true,
        'data' => [
            'orders' => $orders,
            'pagination' => [
                'current_page' => $page,
                'total_pages' => $totalPages,
                'total_orders' => $totalOrders,
                'limit' => $limit,
                'has_next' => $hasNext,
                'has_prev' => $hasPrev
            ]
        ]
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}

mysqli_close($connection);
?>
