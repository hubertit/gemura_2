<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

require_once '../../../configs/connection.php';
require_once '../../shared/order-utils.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true);

if (!$input) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid JSON input']);
    exit;
}

try {
    // Validate required fields
    $requiredFields = ['customer_id', 'seller_id', 'total_amount', 'currency', 'shipping_address', 'items'];
    foreach ($requiredFields as $field) {
        if (!isset($input[$field]) || empty($input[$field])) {
            throw new Exception("Missing required field: $field");
        }
    }

    if (!is_array($input['items']) || empty($input['items'])) {
        throw new Exception("Items must be a non-empty array");
    }

    // Validate items structure
    foreach ($input['items'] as $item) {
        if (!isset($item['product_id']) || !isset($item['quantity']) || !isset($item['unit_price'])) {
            throw new Exception("Each item must have product_id, quantity, and unit_price");
        }
    }

    // Start transaction
    mysqli_begin_transaction($connection);

    // Generate order number using shared function
    $orderNo = generateOrderNumber();

    // Create order
    $orderSql = "INSERT INTO orders (
        order_no, customer_id, seller_id, total_amount, currency, 
        status, shipping_address, shipping_notes, created_at, updated_at
    ) VALUES (
        '$orderNo', {$input['customer_id']}, {$input['seller_id']}, 
        {$input['total_amount']}, '{$input['currency']}', 
        'pending', '{$input['shipping_address']}', 
        '" . ($input['shipping_notes'] ?? '') . "', 
        NOW(), NOW()
    )";

    $orderResult = mysqli_query($connection, $orderSql);
    if (!$orderResult) {
        throw new Exception("Failed to create order: " . mysqli_error($connection));
    }

    $orderId = mysqli_insert_id($connection);

    // Create order items
    foreach ($input['items'] as $item) {
        $totalPrice = $item['quantity'] * $item['unit_price'];
        
        $itemSql = "INSERT INTO order_items (
            order_id, product_id, quantity, unit_price, total_price, currency
        ) VALUES (
            $orderId, {$item['product_id']}, {$item['quantity']}, 
            {$item['unit_price']}, $totalPrice, '{$input['currency']}'
        )";

        $itemResult = mysqli_query($connection, $itemSql);
        if (!$itemResult) {
            throw new Exception("Failed to create order item: " . mysqli_error($connection));
        }
    }

    // Commit transaction
    mysqli_commit($connection);

    // Get the created order with details
    $getOrderSql = "SELECT 
                        o.*,
                        s.name as seller_name,
                        s.phone as seller_phone
                     FROM orders o
                     LEFT JOIN users s ON o.seller_id = s.id
                     WHERE o.id = $orderId";

    $orderResult = mysqli_query($connection, $getOrderSql);
    $order = mysqli_fetch_assoc($orderResult);

    // Get order items using shared function
    $items = getOrderItems($connection, $orderId);

    echo json_encode([
        'success' => true,
        'message' => 'Order placed successfully',
        'data' => [
            'id' => (int)$orderId,
            'order_no' => $orderNo,
            'customer_id' => (int)$input['customer_id'],
            'seller_id' => (int)$input['seller_id'],
            'seller_name' => $order['seller_name'],
            'seller_phone' => $order['seller_phone'],
            'total_amount' => (float)$input['total_amount'],
            'currency' => $input['currency'],
            'status' => 'pending',
            'shipping_address' => $input['shipping_address'],
            'shipping_notes' => $input['shipping_notes'] ?? '',
            'created_at' => date('Y-m-d H:i:s'),
            'items' => $items
        ]
    ]);

} catch (Exception $e) {
    // Rollback transaction on error
    if (mysqli_ping($connection)) {
        mysqli_rollback($connection);
    }
    
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}

mysqli_close($connection);
?>
