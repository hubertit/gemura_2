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
        'message' => 'Forbidden. You can only update your own products.'
    ]);
    exit;
}

// Prepare update fields
$update_fields = [];

if (!empty($data['name'])) {
    $name = mysqli_real_escape_string($connection, trim($data['name']));
    $update_fields[] = "name = '$name'";
}

if (isset($data['description'])) {
    $description = mysqli_real_escape_string($connection, trim($data['description']));
    $update_fields[] = "description = " . ($description ? "'$description'" : "NULL");
}

if (isset($data['price']) && $data['price'] > 0) {
    $price = (float)$data['price'];
    $update_fields[] = "price = $price";
}

if (!empty($data['currency'])) {
    $currency = mysqli_real_escape_string($connection, trim($data['currency']));
    $update_fields[] = "currency = '$currency'";
}

if (!empty($data['image_url'])) {
    $image_url = mysqli_real_escape_string($connection, trim($data['image_url']));
    $update_fields[] = "image_url = '$image_url'";
}

if (isset($data['is_available'])) {
    $is_available = (bool)$data['is_available'] ? 1 : 0;
    $update_fields[] = "is_available = $is_available";
}

if (isset($data['stock_quantity']) && $data['stock_quantity'] >= 0) {
    $stock_quantity = (int)$data['stock_quantity'];
    $update_fields[] = "stock_quantity = $stock_quantity";
}

if (isset($data['min_order_quantity']) && $data['min_order_quantity'] > 0) {
    $min_order_quantity = (int)$data['min_order_quantity'];
    $update_fields[] = "min_order_quantity = $min_order_quantity";
}

if (isset($data['max_order_quantity']) && $data['max_order_quantity'] > 0) {
    $max_order_quantity = (int)$data['max_order_quantity'];
    $update_fields[] = "max_order_quantity = $max_order_quantity";
}

// Add updated_at timestamp
$update_fields[] = "updated_at = NOW()";

if (empty($update_fields)) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'No fields to update.'
    ]);
    exit;
}

// Start transaction
mysqli_begin_transaction($connection);

try {
    // Update the product
    $update_query = "UPDATE products SET " . implode(", ", $update_fields) . " WHERE id = $product_id";
    $update_result = mysqli_query($connection, $update_query);
    
    if (!$update_result) {
        throw new Exception('Failed to update product: ' . mysqli_error($connection));
    }
    
    // Update categories if provided
    if (!empty($data['category_ids']) && is_array($data['category_ids'])) {
        // Delete existing categories
        $deleteCategoriesQuery = mysqli_query($connection, "DELETE FROM product_categories WHERE product_id = $product_id");
        if (!$deleteCategoriesQuery) {
            throw new Exception('Failed to delete existing product categories: ' . mysqli_error($connection));
        }
        
        // Insert new categories
        foreach ($data['category_ids'] as $index => $category_id) {
            $is_primary = ($index === 0) ? 1 : 0;
            $category_code = "PC" . strtoupper(bin2hex(random_bytes(3)));
            
            $categoryInsertQuery = mysqli_query($connection, "
                INSERT INTO product_categories (code, product_id, category_id, is_primary, created_at)
                VALUES ('$category_code', $product_id, $category_id, $is_primary, NOW())
            ");
            
            if (!$categoryInsertQuery) {
                throw new Exception('Failed to create product category: ' . mysqli_error($connection));
            }
        }
    }
    
    // Commit transaction
    mysqli_commit($connection);
    
    // Fetch the updated product
    $fetchQuery = mysqli_query($connection, "
        SELECT 
            p.id, p.code, p.name, p.description, p.price, p.currency, p.image_url,
            p.is_available, p.stock_quantity, p.min_order_quantity, p.max_order_quantity,
            p.created_at, p.updated_at,
            GROUP_CONCAT(DISTINCT c.name ORDER BY pc.is_primary DESC, c.name ASC SEPARATOR ', ') as categories
        FROM products p
        LEFT JOIN product_categories pc ON p.id = pc.product_id
        LEFT JOIN categories c ON pc.category_id = c.id
        WHERE p.id = $product_id
        GROUP BY p.id
        LIMIT 1
    ");
    
    $updatedProduct = mysqli_fetch_assoc($fetchQuery);
    
    echo json_encode([
        'code' => 200,
        'status' => 'success',
        'message' => 'Product updated successfully.',
        'data' => [
            "id" => (int)$updatedProduct['id'],
            "code" => $updatedProduct['code'],
            "name" => $updatedProduct['name'],
            "description" => $updatedProduct['description'],
            "price" => (float)$updatedProduct['price'],
            "currency" => $updatedProduct['currency'],
            "image_url" => $updatedProduct['image_url'],
            "is_available" => (bool)$updatedProduct['is_available'],
            "stock_quantity" => (int)$updatedProduct['stock_quantity'],
            "min_order_quantity" => (int)$updatedProduct['min_order_quantity'],
            "max_order_quantity" => (int)$updatedProduct['max_order_quantity'],
            "created_at" => $updatedProduct['created_at'],
            "updated_at" => $updatedProduct['updated_at'],
            "categories" => $updatedProduct['categories'] ? explode(', ', $updatedProduct['categories']) : []
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
