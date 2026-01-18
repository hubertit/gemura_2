<?php
require_once("../../configs/configs.php");
header('Content-Type: application/json');

// Get query parameters
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 5;

// Fetch featured products (top products by creation date, availability, and stock)
$query = "
    SELECT DISTINCT 
        p.id, p.code, p.name, p.description, p.price, p.currency, p.image_url,
        p.is_available, p.stock_quantity, p.min_order_quantity, p.max_order_quantity,
        p.created_at, p.updated_at,
        u.id as seller_id, u.code as seller_code, u.name as seller_name,
        u.phone as seller_phone, u.email as seller_email,
        GROUP_CONCAT(DISTINCT c.name ORDER BY pc.is_primary DESC, c.name ASC SEPARATOR ', ') as categories,
        GROUP_CONCAT(DISTINCT c.id ORDER BY pc.is_primary DESC, c.name ASC SEPARATOR ', ') as category_ids
    FROM products p
    LEFT JOIN users u ON p.seller_id = u.id
    LEFT JOIN product_categories pc ON p.id = pc.product_id
    LEFT JOIN categories c ON pc.category_id = c.id
    WHERE p.is_available = 1 
    AND p.stock_quantity > 0
    GROUP BY p.id
    ORDER BY p.created_at DESC, p.stock_quantity DESC
    LIMIT $limit
";

$result = mysqli_query($connection, $query);

if (!$result) {
    http_response_code(500);
    echo json_encode([
        'code' => 500,
        'status' => 'error',
        'message' => 'Database error: ' . mysqli_error($connection)
    ]);
    exit;
}

$products = [];
while ($row = mysqli_fetch_assoc($result)) {
    $products[] = [
        "id" => (int)$row['id'],
        "code" => $row['code'],
        "name" => $row['name'],
        "description" => $row['description'],
        "price" => (float)$row['price'],
        "currency" => $row['currency'],
        "image_url" => $row['image_url'],
        "is_available" => (bool)$row['is_available'],
        "stock_quantity" => (int)$row['stock_quantity'],
        "min_order_quantity" => (int)$row['min_order_quantity'],
        "max_order_quantity" => (int)$row['max_order_quantity'],
        "created_at" => $row['created_at'],
        "updated_at" => $row['updated_at'],
        "seller_id" => (int)$row['seller_id'],
        "seller" => [
            "id" => (int)$row['seller_id'],
            "code" => $row['seller_code'],
            "name" => $row['seller_name'],
            "phone" => $row['seller_phone'],
            "email" => $row['seller_email']
        ],
        "categories" => $row['categories'] ? explode(', ', $row['categories']) : [],
        "category_ids" => $row['category_ids'] ? array_map('intval', explode(', ', $row['category_ids'])) : []
    ];
}

echo json_encode([
    "code" => 200,
    "status" => "success",
    "message" => "Featured products fetched successfully.",
    "data" => [
        "products" => $products,
        "total" => count($products)
    ]
]);
?>
