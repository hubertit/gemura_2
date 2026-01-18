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
$required = ['id'];
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

$category_id = (int)$data['id'];

// Check if category exists
$checkQuery = mysqli_query($connection, "SELECT id, name FROM categories WHERE id = $category_id LIMIT 1");
if (!$checkQuery || mysqli_num_rows($checkQuery) === 0) {
    http_response_code(404);
    echo json_encode([
        'code' => 404,
        'status' => 'error',
        'message' => 'Category not found.'
    ]);
    exit;
}

$category = mysqli_fetch_assoc($checkQuery);

// Check if category has products (safety check)
$productsCheckQuery = mysqli_query($connection, "
    SELECT COUNT(*) as product_count 
    FROM product_categories 
    WHERE category_id = $category_id
");
$productsCount = 0;
if ($productsCheckQuery) {
    $countRow = mysqli_fetch_assoc($productsCheckQuery);
    $productsCount = (int)$countRow['product_count'];
}

if ($productsCount > 0) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => "Cannot delete category '{$category['name']}' because it has $productsCount product(s) associated with it. Please remove or reassign the products first."
    ]);
    exit;
}

// Start transaction
mysqli_begin_transaction($connection);

try {
    // Delete the category
    $deleteQuery = mysqli_query($connection, "DELETE FROM categories WHERE id = $category_id");
    
    if (!$deleteQuery) {
        throw new Exception('Failed to delete category: ' . mysqli_error($connection));
    }
    
    if (mysqli_affected_rows($connection) === 0) {
        throw new Exception('No category was deleted.');
    }
    
    // Commit transaction
    mysqli_commit($connection);
    
    echo json_encode([
        'code' => 200,
        'status' => 'success',
        'message' => "Category '{$category['name']}' deleted successfully.",
        'data' => [
            "deleted_category_id" => $category_id,
            "deleted_category_name" => $category['name']
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
