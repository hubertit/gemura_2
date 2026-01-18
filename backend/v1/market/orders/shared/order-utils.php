<?php
/**
 * Shared utilities for order management
 * Contains common functions used across customer, seller, and admin APIs
 */

require_once '/Applications/AMPPS/www/gemura2/api/v2/configs/connection.php';

/**
 * Get order items with product details
 */
function getOrderItems($connection, $orderId) {
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
        return [];
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
    
    return $items;
}

/**
 * Get payment details for an order
 */
function getOrderPayment($connection, $orderId) {
    $paymentSql = "SELECT * FROM payments WHERE order_id = $orderId ORDER BY payment_date DESC LIMIT 1";
    $paymentResult = mysqli_query($connection, $paymentSql);
    
    if (!$paymentResult || mysqli_num_rows($paymentResult) === 0) {
        return null;
    }
    
    $payment = mysqli_fetch_assoc($paymentResult);
    return [
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

/**
 * Get order status history
 */
function getOrderStatusHistory($connection, $orderId) {
    $historySql = "SELECT * FROM order_status_history WHERE order_id = $orderId ORDER BY changed_at DESC";
    $historyResult = mysqli_query($connection, $historySql);
    
    if (!$historyResult) {
        return [];
    }

    $statusHistory = [];
    while ($history = mysqli_fetch_assoc($historyResult)) {
        $statusHistory[] = [
            'id' => (int)$history['id'],
            'status' => $history['status'],
            'changed_by' => $history['changed_by'],
            'changed_at' => $history['changed_at'],
            'notes' => $history['notes']
        ];
    }
    
    return $statusHistory;
}

/**
 * Generate unique order number
 */
function generateOrderNumber() {
    return 'ORD' . date('Ymd') . str_pad(mt_rand(1, 9999), 4, '0', STR_PAD_LEFT);
}

/**
 * Validate order status
 */
function isValidOrderStatus($status) {
    $validStatuses = ['pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded'];
    return in_array($status, $validStatuses);
}

/**
 * Check if user can access order (customer or seller)
 */
function canAccessOrder($connection, $orderId, $userId, $userType) {
    if ($userType === 'admin') {
        return true;
    }
    
    $sql = "SELECT id FROM orders WHERE id = $orderId";
    if ($userType === 'customer') {
        $sql .= " AND customer_id = $userId";
    } elseif ($userType === 'seller') {
        $sql .= " AND seller_id = $userId";
    }
    
    $result = mysqli_query($connection, $sql);
    return $result && mysqli_num_rows($result) > 0;
}
?>
