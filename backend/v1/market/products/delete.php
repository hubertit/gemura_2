<?php
require_once("../../configs/configs.php");
header('Content-Type: application/json');

$input_data = file_get_contents("php://input");
$data = json_decode($input_data, true);

// Validate JSON
if (json_last_error() !== JSON_ERROR_NONE) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'Invalid JSON format.'
    ]);
    exit;
}

// Required fields
$required = ['token', 'id'];
foreach ($required as $field) {
    if (empty($data[$field])) {
        http_response_code(400);
        echo json_encode([
            'code' => 400,
            'status' => 'error',
            'message' => "Missing required field: $field"
        ]);
        exit;
    }
}

$token = mysqli_real_escape_string($connection, trim($data['token']));
$product_id = (int)$data['id'];

// Validate token and get user
$userQuery = mysqli_query($connection, "
    SELECT u.id, u.default_account_id AS account_id, a.name AS account_name, u.name as user_name
    FROM users u
    LEFT JOIN accounts a ON a.id = u.default_account_id
    WHERE u.token = '$token' AND u.status = 'active'
    LIMIT 1
");

if (!$userQuery || mysqli_num_rows($userQuery) === 0) {
    http_response_code(401);
    echo json_encode([
        'code' => 401,
        'status' => 'error',
        'message' => 'Unauthorized. Invalid token.'
    ]);
    exit;
}

$user = mysqli_fetch_assoc($userQuery);
$current_user_id = $user['id'];

// Check if product exists and get ownership info
$productQuery = mysqli_query($connection, "
    SELECT p.id, p.code, p.name, p.seller_id, u.name as seller_name
    FROM products p
    LEFT JOIN users u ON p.seller_id = u.id
    WHERE p.id = $product_id
    LIMIT 1
");

if (!$productQuery || mysqli_num_rows($productQuery) === 0) {
    http_response_code(404);
    echo json_encode([
        'code' => 404,
        'status' => 'error',
        'message' => 'Product not found.'
    ]);
    exit;
}

$product = mysqli_fetch_assoc($productQuery);

// Check if user owns this product
if ($product['seller_id'] != $current_user_id) {
    http_response_code(403);
    echo json_encode([
        'code' => 403,
        'status' => 'error',
        'message' => 'Forbidden. You can only delete your own products.'
    ]);
    exit;
}

// Start transaction
mysqli_begin_transaction($connection);

try {
    // Delete product images first
    $deleteImagesQuery = mysqli_query($connection, "DELETE FROM product_images WHERE product_id = $product_id");
    if (!$deleteImagesQuery) {
        throw new Exception('Failed to delete product images: ' . mysqli_error($connection));
    }
    
    // Delete product categories
    $deleteCategoriesQuery = mysqli_query($connection, "DELETE FROM product_categories WHERE product_id = $product_id");
    if (!$deleteCategoriesQuery) {
        throw new Exception('Failed to delete product categories: ' . mysqli_error($connection));
    }
    
    // Delete the product
    $deleteProductQuery = mysqli_query($connection, "DELETE FROM products WHERE id = $product_id");
    if (!$deleteProductQuery) {
        throw new Exception('Failed to delete product: ' . mysqli_error($connection));
    }
    
    if (mysqli_affected_rows($connection) === 0) {
        throw new Exception('No product was deleted.');
    }
    
    // Commit transaction
    mysqli_commit($connection);
    
    echo json_encode([
        'code' => 200,
        'status' => 'success',
        'message' => "Product '{$product['name']}' deleted successfully.",
        'data' => [
            "deleted_product_id" => $product_id,
            "deleted_product_code" => $product['code'],
            "deleted_product_name" => $product['name'],
            "deleted_by_user_id" => $current_user_id,
            "deleted_by_user_name" => $user['user_name']
        ]
    ]);
    
} catch (Exception $e) {
    // Rollback transaction
    mysqli_rollback($connection);
    
    http_response_code(500);
    echo json_encode([
        'code' => 500,
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
}
?>
