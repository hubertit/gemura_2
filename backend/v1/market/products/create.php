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
$required = ['token', 'name', 'price', 'category_ids'];
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

// Validate token and get user
$token = mysqli_real_escape_string($connection, trim($data['token']));

// Get logged in user with default account
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
$seller_id = $user['id'];

// Check if user has a valid default account
if (!$user['account_id'] || !$user['account_name']) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'No valid default account found. Please set a default account.'
    ]);
    exit;
}

// Generate unique product code if not provided
if (empty($data['code'])) {
    $code = "PROD" . strtoupper(bin2hex(random_bytes(4)));
} else {
    $code = mysqli_real_escape_string($connection, trim($data['code']));
}

$name = mysqli_real_escape_string($connection, trim($data['name']));
$description = !empty($data['description']) ? mysqli_real_escape_string($connection, trim($data['description'])) : null;
$price = (float)$data['price'];
$currency = !empty($data['currency']) ? mysqli_real_escape_string($connection, trim($data['currency'])) : 'RWF';
$image_url = !empty($data['image_url']) ? mysqli_real_escape_string($connection, trim($data['image_url'])) : null;
$stock_quantity = !empty($data['stock_quantity']) ? (int)$data['stock_quantity'] : 0;
$min_order_quantity = !empty($data['min_order_quantity']) ? (int)$data['min_order_quantity'] : 1;
$max_order_quantity = !empty($data['max_order_quantity']) ? (int)$data['max_order_quantity'] : 100;
$category_ids = is_array($data['category_ids']) ? $data['category_ids'] : [$data['category_ids']];

// Validate price
if ($price <= 0) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'Price must be greater than 0.'
    ]);
    exit;
}

// Check if product code already exists
$checkQuery = mysqli_query($connection, "SELECT id FROM products WHERE code = '$code' LIMIT 1");
if ($checkQuery && mysqli_num_rows($checkQuery) > 0) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'Product code already exists.'
    ]);
    exit;
}

// Validate categories exist
$category_ids_str = implode(',', array_map('intval', $category_ids));
$categoriesQuery = mysqli_query($connection, "SELECT id FROM categories WHERE id IN ($category_ids_str) AND is_active = 1");
if (!$categoriesQuery || mysqli_num_rows($categoriesQuery) !== count($category_ids)) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'One or more categories are invalid or inactive.'
    ]);
    exit;
}

// Start transaction
mysqli_begin_transaction($connection);

try {
    // Insert product
    $insertQuery = mysqli_query($connection, "
        INSERT INTO products (code, name, description, price, currency, image_url, stock_quantity, 
                            min_order_quantity, max_order_quantity, seller_id, is_available, created_at, updated_at)
        VALUES ('$code', '$name', " . ($description ? "'$description'" : "NULL") . ", $price, '$currency', 
                " . ($image_url ? "'$image_url'" : "NULL") . ", $stock_quantity, $min_order_quantity, 
                $max_order_quantity, $seller_id, 1, NOW(), NOW())
    ");

    if (!$insertQuery) {
        throw new Exception('Failed to create product: ' . mysqli_error($connection));
    }

    $product_id = mysqli_insert_id($connection);

    // Insert product categories
    foreach ($category_ids as $index => $category_id) {
        $is_primary = ($index === 0) ? 1 : 0; // First category is primary
        $category_code = "PC" . strtoupper(bin2hex(random_bytes(3)));
        
        $categoryInsertQuery = mysqli_query($connection, "
            INSERT INTO product_categories (code, product_id, category_id, is_primary, created_at)
            VALUES ('$category_code', $product_id, $category_id, $is_primary, NOW())
        ");

        if (!$categoryInsertQuery) {
            throw new Exception('Failed to create product category: ' . mysqli_error($connection));
        }
    }

    // Insert primary image if provided
    if ($image_url) {
        $image_code = "IMG" . strtoupper(bin2hex(random_bytes(3)));
        $imageInsertQuery = mysqli_query($connection, "
            INSERT INTO product_images (code, product_id, image_url, alt_text, is_primary, sort_order, created_at)
            VALUES ('$image_code', $product_id, '$image_url', '$name', 1, 1, NOW())
        ");

        if (!$imageInsertQuery) {
            throw new Exception('Failed to create product image: ' . mysqli_error($connection));
        }
    }

    // Commit transaction
    mysqli_commit($connection);

    // Fetch the created product
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

    $product = mysqli_fetch_assoc($fetchQuery);

    echo json_encode([
        'code' => 201,
        'status' => 'success',
        'message' => 'Product created successfully.',
        'data' => [
            "id" => (int)$product['id'],
            "code" => $product['code'],
            "name" => $product['name'],
            "description" => $product['description'],
            "price" => (float)$product['price'],
            "currency" => $product['currency'],
            "image_url" => $product['image_url'],
            "is_available" => (bool)$product['is_available'],
            "stock_quantity" => (int)$product['stock_quantity'],
            "min_order_quantity" => (int)$product['min_order_quantity'],
            "max_order_quantity" => (int)$product['max_order_quantity'],
            "created_at" => $product['created_at'],
            "updated_at" => $product['updated_at'],
            "categories" => $product['categories'] ? explode(', ', $product['categories']) : []
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
