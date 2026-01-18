<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: PUT');
header('Access-Control-Allow-Headers: Content-Type');

require_once '../../../configs/connection.php';
require_once '../../shared/order-utils.php';

if ($_SERVER['REQUEST_METHOD'] !== 'PUT') {
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
    if (!isset($input['order_id']) || !is_numeric($input['order_id'])) {
        throw new Exception("Order ID is required and must be numeric");
    }

    if (!isset($input['customer_id']) || !is_numeric($input['customer_id'])) {
        throw new Exception("Customer ID is required and must be numeric");
    }

    if (!isset($input['cancellation_reason']) || empty($input['cancellation_reason'])) {
        throw new Exception("Cancellation reason is required");
    }

    $orderId = (int)$input['order_id'];
    $customerId = (int)$input['customer_id'];
    $cancellationReason = $input['cancellation_reason'];

    // Start transaction
    mysqli_begin_transaction($connection);

    // Verify customer can access this order
    if (!canAccessOrder($connection, $orderId, $customerId, 'customer')) {
        throw new Exception("Access denied - Order not found or does not belong to customer");
    }

    // Check if order can be cancelled
    $checkSql = "SELECT id, status FROM orders WHERE id = $orderId AND customer_id = $customerId";
    $checkResult = mysqli_query($connection, $checkSql);
    
    if (!$checkResult) {
        throw new Exception("Database error: " . mysqli_error($connection));
    }

    if (mysqli_num_rows($checkResult) === 0) {
        throw new Exception("Order not found");
    }

    $order = mysqli_fetch_assoc($checkResult);
    $oldStatus = $order['status'];

    // Only allow cancellation of pending or confirmed orders
    if (!in_array($oldStatus, ['pending', 'confirmed'])) {
        throw new Exception("Order cannot be cancelled in current status: $oldStatus");
    }

    // Update order status to cancelled
    $updateSql = "UPDATE orders SET 
                    status = 'cancelled', 
                    cancellation_reason = '$cancellationReason',
                    updated_at = NOW() 
                   WHERE id = $orderId";
    
    $updateResult = mysqli_query($connection, $updateSql);
    
    if (!$updateResult) {
        throw new Exception("Failed to cancel order: " . mysqli_error($connection));
    }

    // Record status change in history if table exists
    $historySql = "INSERT INTO order_status_history (
        order_id, status, changed_by, changed_at, notes
    ) VALUES (
        $orderId, 'cancelled', 'customer_$customerId', NOW(), 'Cancelled by customer: $cancellationReason'
    )";

    $historyResult = mysqli_query($connection, $historySql);
    
    // Don't fail if history table doesn't exist
    if (!$historyResult) {
        error_log("Failed to record status history: " . mysqli_error($connection));
    }

    // Commit transaction
    mysqli_commit($connection);

    // Get updated order details
    $getOrderSql = "SELECT 
                        o.*,
                        s.name as seller_name,
                        s.phone as seller_phone
                     FROM orders o
                     LEFT JOIN users s ON o.seller_id = s.id
                     WHERE o.id = $orderId";

    $orderResult = mysqli_query($connection, $getOrderSql);
    
    if (!$orderResult) {
        throw new Exception("Database error: " . mysqli_error($connection));
    }

    $order = mysqli_fetch_assoc($orderResult);

    echo json_encode([
        'success' => true,
        'message' => 'Order cancelled successfully',
        'data' => [
            'id' => (int)$orderId,
            'order_no' => $order['order_no'],
            'old_status' => $oldStatus,
            'new_status' => 'cancelled',
            'customer_id' => (int)$customerId,
            'seller_id' => (int)$order['seller_id'],
            'seller_name' => $order['seller_name'],
            'seller_phone' => $order['seller_phone'],
            'total_amount' => (float)$order['total_amount'],
            'currency' => $order['currency'],
            'status' => 'cancelled',
            'shipping_address' => $order['shipping_address'],
            'shipping_notes' => $order['shipping_notes'],
            'order_date' => $order['order_date'],
            'updated_at' => date('Y-m-d H:i:s'),
            'cancellation_reason' => $cancellationReason,
            'changed_by' => "customer_$customerId",
            'notes' => "Cancelled by customer: $cancellationReason"
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
