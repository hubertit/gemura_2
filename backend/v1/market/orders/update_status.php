<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: PUT');
header('Access-Control-Allow-Headers: Content-Type');

require_once '../../configs/connection.php';

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

    if (!isset($input['status']) || empty($input['status'])) {
        throw new Exception("Status is required");
    }

    $orderId = (int)$input['order_id'];
    $newStatus = $input['status'];
    $changedBy = $input['changed_by'] ?? 'system';
    $notes = $input['notes'] ?? '';

    // Valid status values
    $validStatuses = ['pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded'];
    if (!in_array($newStatus, $validStatuses)) {
        throw new Exception("Invalid status. Must be one of: " . implode(', ', $validStatuses));
    }

    // Start transaction
    mysqli_begin_transaction($connection);

    // Check if order exists
    $checkSql = "SELECT id, status FROM orders WHERE id = $orderId";
    $checkResult = mysqli_query($connection, $checkSql);
    
    if (!$checkResult) {
        throw new Exception("Database error: " . mysqli_error($connection));
    }

    if (mysqli_num_rows($checkResult) === 0) {
        throw new Exception("Order not found");
    }

    $order = mysqli_fetch_assoc($checkResult);
    $oldStatus = $order['status'];

    // Update order status
    $updateSql = "UPDATE orders SET status = '$newStatus', updated_at = NOW() WHERE id = $orderId";
    $updateResult = mysqli_query($connection, $updateSql);
    
    if (!$updateResult) {
        throw new Exception("Failed to update order status: " . mysqli_error($connection));
    }

    // Record status change in history
    $historySql = "INSERT INTO order_status_history (
        order_id, status, changed_by, changed_at, notes
    ) VALUES (
        $orderId, '$newStatus', '$changedBy', NOW(), '$notes'
    )";

    $historyResult = mysqli_query($connection, $historySql);
    
    // Don't fail if history table doesn't exist
    if (!$historyResult) {
        // Log the error but don't throw exception
        error_log("Failed to record status history: " . mysqli_error($connection));
    }

    // Commit transaction
    mysqli_commit($connection);

    // Get updated order details
    $getOrderSql = "SELECT 
                        o.*,
                        c.name as customer_name,
                        c.phone as customer_phone,
                        s.name as seller_name,
                        s.phone as seller_phone
                     FROM orders o
                     LEFT JOIN users c ON o.customer_id = c.id
                     LEFT JOIN users s ON o.seller_id = s.id
                     WHERE o.id = $orderId";

    $orderResult = mysqli_query($connection, $getOrderSql);
    
    if (!$orderResult) {
        throw new Exception("Database error: " . mysqli_error($connection));
    }

    $order = mysqli_fetch_assoc($orderResult);

    echo json_encode([
        'success' => true,
        'message' => 'Order status updated successfully',
        'data' => [
            'id' => (int)$orderId,
            'order_no' => $order['order_no'],
            'old_status' => $oldStatus,
            'new_status' => $newStatus,
            'customer_id' => (int)$order['customer_id'],
            'customer_name' => $order['customer_name'],
            'customer_phone' => $order['customer_phone'],
            'seller_id' => (int)$order['seller_id'],
            'seller_name' => $order['seller_name'],
            'seller_phone' => $order['seller_phone'],
            'total_amount' => (float)$order['total_amount'],
            'currency' => $order['currency'],
            'status' => $newStatus,
            'shipping_address' => $order['shipping_address'],
            'shipping_notes' => $order['shipping_notes'],
            'order_date' => $order['order_date'],
            'updated_at' => date('Y-m-d H:i:s'),
            'cancellation_reason' => $order['cancellation_reason'],
            'changed_by' => $changedBy,
            'notes' => $notes
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
