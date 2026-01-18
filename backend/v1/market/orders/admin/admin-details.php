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

if (!isset($_GET['id']) || !is_numeric($_GET['id'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Order ID is required and must be numeric']);
    exit;
}

$orderId = (int)$_GET['id'];

try {
    // Get order details - admin has access to all orders
    $orderSql = "SELECT 
                    o.*,
                    c.name as customer_name,
                    c.phone as customer_phone,
                    c.email as customer_email,
                    s.name as seller_name,
                    s.phone as seller_phone,
                    s.email as seller_email
                 FROM orders o
                 LEFT JOIN users c ON o.customer_id = c.id
                 LEFT JOIN users s ON o.seller_id = s.id
                 WHERE o.id = $orderId";

    $orderResult = mysqli_query($connection, $orderSql);
    
    if (!$orderResult) {
        throw new Exception("Database error: " . mysqli_error($connection));
    }

    $order = mysqli_fetch_assoc($orderResult);
    
    if (!$order) {
        http_response_code(404);
        echo json_encode(['error' => 'Order not found']);
        exit;
    }

    // Get order items using shared function
    $items = getOrderItems($connection, $orderId);

    // Get payment details using shared function
    $payment = getOrderPayment($connection, $orderId);

    // Get order status history using shared function
    $statusHistory = getOrderStatusHistory($connection, $orderId);

    echo json_encode([
        'success' => true,
        'data' => [
            'id' => (int)$order['id'],
            'order_no' => $order['order_no'],
            'customer_id' => (int)$order['customer_id'],
            'customer_name' => $order['customer_name'],
            'customer_phone' => $order['customer_phone'],
            'customer_email' => $order['customer_email'],
            'seller_id' => (int)$order['seller_id'],
            'seller_name' => $order['seller_name'],
            'seller_phone' => $order['seller_phone'],
            'seller_email' => $order['seller_email'],
            'total_amount' => (float)$order['total_amount'],
            'currency' => $order['currency'],
            'status' => $order['status'],
            'shipping_address' => $order['shipping_address'],
            'shipping_notes' => $order['shipping_notes'],
            'order_date' => $order['order_date'],
            'updated_at' => $order['updated_at'],
            'cancellation_reason' => $order['cancellation_reason'],
            'items' => $items,
            'payment' => $payment,
            'status_history' => $statusHistory
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
