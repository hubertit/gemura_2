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

if (!isset($_GET['id']) || !is_numeric($_GET['id'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Order ID is required and must be numeric']);
    exit;
}

$orderId = (int)$_GET['id'];

try {
    // Get order details
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

    // Get order items
    $itemsSql = "SELECT 
                    oi.*,
                    p.name as product_name,
                    p.description as product_description,
                    p.image_url as product_image,
                    p.price as product_price
                 FROM order_items oi
                 LEFT JOIN products p ON oi.product_id = p.id
                 WHERE oi.order_id = $orderId";

    $itemsResult = mysqli_query($connection, $itemsSql);
    
    if (!$itemsResult) {
        throw new Exception("Database error: " . mysqli_error($connection));
    }

    $items = [];
    while ($item = mysqli_fetch_assoc($itemsResult)) {
        $items[] = [
            'id' => (int)$item['id'],
            'product_id' => (int)$item['product_id'],
            'product_name' => $item['product_name'],
            'product_description' => $item['product_description'],
            'product_image' => $item['product_image'],
            'product_price' => (float)$item['product_price'],
            'quantity' => (int)$item['quantity'],
            'unit_price' => (float)$item['unit_price'],
            'total_price' => (float)$item['total_price'],
            'currency' => $item['currency']
        ];
    }

    // Get payment details if any
    $payment = null;
    $paymentSql = "SELECT * FROM payments WHERE order_id = $orderId ORDER BY payment_date DESC LIMIT 1";
    $paymentResult = mysqli_query($connection, $paymentSql);
    
    if ($paymentResult && mysqli_num_rows($paymentResult) > 0) {
        $payment = mysqli_fetch_assoc($paymentResult);
        $payment = [
            'id' => (int)$payment['id'],
            'payment_reference' => $payment['payment_reference'],
            'amount' => (float)$payment['amount'],
            'currency' => $payment['currency'],
            'payment_method' => $payment['payment_method'],
            'payment_provider' => $payment['payment_provider'],
            'status' => $payment['status'],
            'transaction_id' => $payment['transaction_id'],
            'payment_date' => $payment['payment_date'],
            'completed_at' => $payment['completed_at'],
            'failure_reason' => $payment['failure_reason'],
            'refund_reason' => $payment['refund_reason'],
            'refund_amount' => $payment['refund_amount'] ? (float)$payment['refund_amount'] : null,
            'refund_date' => $payment['refund_date']
        ];
    }

    // Get order status history
    $statusHistory = [];
    $historySql = "SELECT * FROM order_status_history WHERE order_id = $orderId ORDER BY changed_at DESC";
    $historyResult = mysqli_query($connection, $historySql);
    
    if ($historyResult) {
        while ($history = mysqli_fetch_assoc($historyResult)) {
            $statusHistory[] = [
                'id' => (int)$history['id'],
                'status' => $history['status'],
                'changed_by' => $history['changed_by'],
                'changed_at' => $history['changed_at'],
                'notes' => $history['notes']
            ];
        }
    }

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
