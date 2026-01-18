<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

require_once '../../configs/connection.php';

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
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 10;
    $page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
    $offset = ($page - 1) * $limit;

    // Build base query
    $sql = "SELECT 
                o.*,
                c.name as customer_name,
                c.phone as customer_phone,
                s.name as seller_name,
                s.phone as seller_phone,
                COUNT(oi.id) as total_items,
                SUM(oi.total_price) as calculated_total
            FROM orders o
            LEFT JOIN users c ON o.customer_id = c.id
            LEFT JOIN users s ON o.seller_id = s.id
            LEFT JOIN order_items oi ON o.id = oi.order_id";

    $whereConditions = [];
    $params = [];

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

    $sql .= " GROUP BY o.id ORDER BY o.created_at DESC";

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
        // Get order items for this order
        $itemsSql = "SELECT 
                        oi.*,
                        p.name as product_name,
                        p.image_url as product_image
                     FROM order_items oi
                     LEFT JOIN products p ON oi.product_id = p.id
                     WHERE oi.order_id = {$row['id']}";
        
        $itemsResult = mysqli_query($connection, $itemsSql);
        $items = [];
        
        while ($item = mysqli_fetch_assoc($itemsResult)) {
            $items[] = [
                'id' => $item['id'],
                'product_id' => $item['product_id'],
                'product_name' => $item['product_name'],
                'product_image' => $item['product_image'],
                'quantity' => $item['quantity'],
                'unit_price' => (float)$item['unit_price'],
                'total_price' => (float)$item['total_price'],
                'currency' => $item['currency']
            ];
        }

        $orders[] = [
            'id' => (int)$row['id'],
            'order_no' => $row['order_no'],
            'customer_id' => (int)$row['customer_id'],
            'customer_name' => $row['customer_name'],
            'customer_phone' => $row['customer_phone'],
            'seller_id' => (int)$row['seller_id'],
            'seller_name' => $row['seller_name'],
            'seller_phone' => $row['seller_phone'],
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
