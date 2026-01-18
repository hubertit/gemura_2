<?php
require_once("../../configs/configs.php");
header('Content-Type: application/json');

// Get query parameters
$page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 20;
$category_id = isset($_GET['category_id']) ? (int)$_GET['category_id'] : null;
$search = isset($_GET['search']) ? mysqli_real_escape_string($connection, trim($_GET['search'])) : null;
$min_price = isset($_GET['min_price']) ? (float)$_GET['min_price'] : null;
$max_price = isset($_GET['max_price']) ? (float)$_GET['max_price'] : null;
$sort_by = isset($_GET['sort_by']) ? $_GET['sort_by'] : 'created_at';
$sort_order = isset($_GET['sort_order']) ? $_GET['sort_order'] : 'DESC';

// Validate sort_by to prevent SQL injection
$allowed_sort_fields = ['name', 'price', 'created_at', 'stock_quantity'];
if (!in_array($sort_by, $allowed_sort_fields)) {
    $sort_by = 'created_at';
}

// Validate sort_order
$sort_order = strtoupper($sort_order) === 'ASC' ? 'ASC' : 'DESC';

// Calculate offset
$offset = ($page - 1) * $limit;

// Build WHERE clause
$where_conditions = ["p.is_available = 1"];
$params = [];

if ($category_id) {
    $where_conditions[] = "pc.category_id = $category_id";
}

if ($search) {
    $where_conditions[] = "(p.name LIKE '%$search%' OR p.description LIKE '%$search%')";
}

if ($min_price !== null) {
    $where_conditions[] = "p.price >= $min_price";
}

if ($max_price !== null) {
    $where_conditions[] = "p.price <= $max_price";
}

$where_clause = implode(" AND ", $where_conditions);

// Build the main query
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
    WHERE $where_clause
    GROUP BY p.id
    ORDER BY p.$sort_by $sort_order
    LIMIT $limit OFFSET $offset
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

// Get total count for pagination
$count_query = "
    SELECT COUNT(DISTINCT p.id) as total
    FROM products p
    LEFT JOIN product_categories pc ON p.id = pc.product_id
    WHERE $where_clause
";

$count_result = mysqli_query($connection, $count_query);
$total_count = 0;
if ($count_result) {
    $count_row = mysqli_fetch_assoc($count_result);
    $total_count = (int)$count_row['total'];
}

$total_pages = ceil($total_count / $limit);

echo json_encode([
    "code" => 200,
    "status" => "success",
    "message" => "Products fetched successfully.",
    "data" => [
        "products" => $products,
        "pagination" => [
            "current_page" => $page,
            "per_page" => $limit,
            "total_items" => $total_count,
            "total_pages" => $total_pages,
            "has_next" => $page < $total_pages,
            "has_prev" => $page > 1
        ]
    ]
]);
?>
