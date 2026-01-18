<?php
require_once("../../configs/configs.php");
header('Content-Type: application/json');

$input_data = file_get_contents("php://input");
$data = json_decode($input_data, true);

// Validate input
if (empty($data['id'])) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Missing product ID."
    ]);
    exit;
}

$product_id = (int)$data['id'];

// Fetch product by ID with all details
$query = "
    SELECT 
        p.id, p.code, p.name, p.description, p.price, p.currency, p.image_url,
        p.is_available, p.stock_quantity, p.min_order_quantity, p.max_order_quantity,
        p.created_at, p.updated_at,
        u.id as seller_id, u.code as seller_code, u.name as seller_name,
        u.phone as seller_phone, u.email as seller_email, u.address as seller_address,
        GROUP_CONCAT(DISTINCT c.name ORDER BY pc.is_primary DESC, c.name ASC SEPARATOR ', ') as categories,
        GROUP_CONCAT(DISTINCT c.id ORDER BY pc.is_primary DESC, c.name ASC SEPARATOR ', ') as category_ids,
        GROUP_CONCAT(DISTINCT c.code ORDER BY pc.is_primary DESC, c.name ASC SEPARATOR ', ') as category_codes
    FROM products p
    LEFT JOIN users u ON p.seller_id = u.id
    LEFT JOIN product_categories pc ON p.id = pc.product_id
    LEFT JOIN categories c ON pc.category_id = c.id
    WHERE p.id = $product_id
    GROUP BY p.id
    LIMIT 1
";

$result = mysqli_query($connection, $query);

if (!$result || mysqli_num_rows($result) === 0) {
    http_response_code(404);
    echo json_encode([
        "code" => 404,
        "status" => "error",
        "message" => "Product not found."
    ]);
    exit;
}

$product = mysqli_fetch_assoc($result);

// Get product images
$images_query = "
    SELECT id, code, image_url, alt_text, is_primary, sort_order
    FROM product_images 
    WHERE product_id = $product_id 
    ORDER BY is_primary DESC, sort_order ASC
";

$images_result = mysqli_query($connection, $images_query);
$images = [];

if ($images_result) {
    while ($image_row = mysqli_fetch_assoc($images_result)) {
        $images[] = [
            "id" => (int)$image_row['id'],
            "code" => $image_row['code'],
            "image_url" => $image_row['image_url'],
            "alt_text" => $image_row['alt_text'],
            "is_primary" => (bool)$image_row['is_primary'],
            "sort_order" => (int)$image_row['sort_order']
        ];
    }
}

// Get related products (same category)
$related_query = "
    SELECT DISTINCT 
        p.id, p.code, p.name, p.price, p.currency, p.image_url, p.is_available
    FROM products p
    JOIN product_categories pc1 ON p.id = pc1.product_id
    JOIN product_categories pc2 ON pc1.category_id = pc2.category_id
    WHERE pc2.product_id = $product_id 
    AND p.id != $product_id 
    AND p.is_available = 1
    LIMIT 6
";

$related_result = mysqli_query($connection, $related_query);
$related_products = [];

if ($related_result) {
    while ($related_row = mysqli_fetch_assoc($related_result)) {
        $related_products[] = [
            "id" => (int)$related_row['id'],
            "code" => $related_row['code'],
            "name" => $related_row['name'],
            "price" => (float)$related_row['price'],
            "currency" => $related_row['currency'],
            "image_url" => $related_row['image_url'],
            "is_available" => (bool)$related_row['is_available']
        ];
    }
}

echo json_encode([
    "code" => 200,
    "status" => "success",
    "message" => "Product fetched successfully.",
    "data" => [
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
        "seller" => [
            "id" => (int)$product['seller_id'],
            "code" => $product['seller_code'],
            "name" => $product['seller_name'],
            "phone" => $product['seller_phone'],
            "email" => $product['seller_email'],
            "address" => $product['seller_address']
        ],
        "categories" => $product['categories'] ? explode(', ', $product['categories']) : [],
        "category_ids" => $product['category_ids'] ? array_map('intval', explode(', ', $product['category_ids'])) : [],
        "category_codes" => $product['category_codes'] ? explode(', ', $product['category_codes']) : [],
        "images" => $images,
        "related_products" => $related_products
    ]
]);
?>
