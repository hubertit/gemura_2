<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../../configs/configs.php';

try {
    // Get search parameters
    $searchQuery = isset($_GET['q']) ? mysqli_real_escape_string($connection, trim($_GET['q'])) : '';
    $categoryId = isset($_GET['category_id']) ? (int)$_GET['category_id'] : null;
    $minPrice = isset($_GET['min_price']) ? (float)$_GET['min_price'] : null;
    $maxPrice = isset($_GET['max_price']) ? (float)$_GET['max_price'] : null;
    $sellerType = isset($_GET['seller_type']) ? mysqli_real_escape_string($connection, trim($_GET['seller_type'])) : null;
    $sortBy = isset($_GET['sort_by']) ? $_GET['sort_by'] : 'newest'; // newest, oldest, price_low, price_high, rating, name
    $limit = min((int)($_GET['limit'] ?? 20), 100); // Max 100 results
    $offset = (int)($_GET['offset'] ?? 0);
    
    // Build the base query
    $sql = "SELECT DISTINCT 
                p.id,
                p.name,
                p.description,
                p.price,
                p.currency,
                p.stock_quantity,
                p.min_order_quantity,
                p.max_order_quantity,
                p.is_available,
                p.image_url,
                p.code,
                p.created_at,
                p.updated_at,
                u.id as seller_id,
                u.code as seller_code,
                u.name as seller_name,
                u.phone as seller_phone,
                u.email as seller_email,
                GROUP_CONCAT(DISTINCT c.name ORDER BY pc.is_primary DESC, c.name ASC SEPARATOR ', ') as categories,
                GROUP_CONCAT(DISTINCT c.id ORDER BY pc.is_primary DESC, c.name ASC SEPARATOR ', ') as category_ids
            FROM products p
            LEFT JOIN users u ON p.seller_id = u.id
            LEFT JOIN product_categories pc ON p.id = pc.product_id
            LEFT JOIN categories c ON pc.category_id = c.id
            WHERE p.is_available = 1";
    
    // Add search query filter
    if (!empty($searchQuery)) {
        $sql .= " AND (p.name LIKE '%$searchQuery%' OR p.description LIKE '%$searchQuery%' OR p.code LIKE '%$searchQuery%')";
    }
    
    // Add category filter
    if ($categoryId !== null && $categoryId !== '') {
        $sql .= " AND pc.category_id = $categoryId";
    }
    
    // Add price range filters
    if ($minPrice !== null && $minPrice !== '') {
        $sql .= " AND p.price >= $minPrice";
    }
    
    if ($maxPrice !== null && $maxPrice !== '') {
        $sql .= " AND p.price <= $maxPrice";
    }
    
    // Add seller type filter
    if ($sellerType !== null && $sellerType !== '') {
        $sql .= " AND u.account_type = '$sellerType'";
    }
    
    // Add GROUP BY for categories
    $sql .= " GROUP BY p.id";
    
    // Add sorting
    switch ($sortBy) {
        case 'oldest':
            $sql .= " ORDER BY p.created_at ASC";
            break;
        case 'price_low':
            $sql .= " ORDER BY p.price ASC";
            break;
        case 'price_high':
            $sql .= " ORDER BY p.price DESC";
            break;
        case 'rating':
            $sql .= " ORDER BY p.rating DESC, p.reviews_count DESC";
            break;
        case 'name':
            $sql .= " ORDER BY p.name ASC";
            break;
        case 'newest':
        default:
            $sql .= " ORDER BY p.created_at DESC";
            break;
    }
    
    // Add pagination
    $sql .= " LIMIT $limit OFFSET $offset";
    
    // Execute the query
    $result = mysqli_query($connection, $sql);
    
    if (!$result) {
        throw new Exception('Database error: ' . mysqli_error($connection));
    }
    
    // Fetch results
    $products = [];
    while ($row = mysqli_fetch_assoc($result)) {
        // Format the product data
        $product = [
            'id' => (int)$row['id'],
            'name' => $row['name'],
            'description' => $row['description'],
            'price' => (float)$row['price'],
            'currency' => $row['currency'],
            'stock_quantity' => (int)$row['stock_quantity'],
            'min_order_quantity' => (int)$row['min_order_quantity'],
            'max_order_quantity' => (int)$row['max_order_quantity'],
            'is_available' => (bool)$row['is_available'],
            'image_url' => $row['image_url'],
            'code' => $row['code'],
            'created_at' => $row['created_at'],
            'updated_at' => $row['updated_at'],
            'seller' => [
                'id' => (int)$row['seller_id'],
                'code' => $row['seller_code'],
                'name' => $row['seller_name'],
                'phone' => $row['seller_phone'],
                'email' => $row['seller_email']
            ],
            'categories' => $row['categories'] ? explode(', ', $row['categories']) : [],
            'category_ids' => $row['category_ids'] ? array_map('intval', explode(', ', $row['category_ids'])) : []
        ];
        
        $products[] = $product;
    }
    
    // Get total count for pagination
    $countSql = "SELECT COUNT(DISTINCT p.id) as total FROM products p
                  LEFT JOIN users u ON p.seller_id = u.id
                  LEFT JOIN product_categories pc ON p.id = pc.product_id
                  LEFT JOIN categories c ON pc.category_id = c.id
                  WHERE p.is_available = 1";
    
    // Add the same filters for count (excluding pagination)
    if (!empty($searchQuery)) {
        $countSql .= " AND (p.name LIKE '%$searchQuery%' OR p.description LIKE '%$searchQuery%' OR p.code LIKE '%$searchQuery%')";
    }
    if ($categoryId !== null && $categoryId !== '') {
        $countSql .= " AND pc.category_id = $categoryId";
    }
    if ($minPrice !== null && $minPrice !== '') {
        $countSql .= " AND p.price >= $minPrice";
    }
    if ($maxPrice !== null && $maxPrice !== '') {
        $countSql .= " AND p.price <= $maxPrice";
    }
    if ($sellerType !== null && $sellerType !== '') {
        $countSql .= " AND u.account_type = '$sellerType'";
    }
    
    $countResult = mysqli_query($connection, $countSql);
    
    if (!$countResult) {
        throw new Exception('Count query error: ' . mysqli_error($connection));
    }
    
    $totalCount = mysqli_fetch_assoc($countResult)['total'];
    
    // Calculate pagination info
    $totalPages = ceil($totalCount / $limit);
    $currentPage = floor($offset / $limit) + 1;
    
    // Return success response
    echo json_encode([
        'code' => 200,
        'status' => 'success',
        'message' => 'Products retrieved successfully',
        'data' => [
            'products' => $products,
            'pagination' => [
                'total' => (int)$totalCount,
                'per_page' => $limit,
                'current_page' => $currentPage,
                'total_pages' => $totalPages,
                'has_next' => $currentPage < $totalPages,
                'has_prev' => $currentPage > 1
            ],
            'filters' => [
                'search_query' => $searchQuery,
                'category_id' => $categoryId,
                'min_price' => $minPrice,
                'max_price' => $maxPrice,
                'seller_type' => $sellerType,
                'sort_by' => $sortBy
            ]
        ]
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'code' => 500,
        'status' => 'error',
        'message' => 'Internal server error',
        'error' => $e->getMessage()
    ]);
}

if (isset($result)) mysqli_free_result($result);
if (isset($countResult)) mysqli_free_result($countResult);
$connection->close();
?>
