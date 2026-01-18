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
$checkQuery = mysqli_query($connection, "SELECT id FROM categories WHERE id = $category_id LIMIT 1");
if (!$checkQuery || mysqli_num_rows($checkQuery) === 0) {
    http_response_code(404);
    echo json_encode([
        'code' => 404,
        'status' => 'error',
        'message' => 'Category not found.'
    ]);
    exit;
}

// Prepare update fields
$update_fields = [];
$params = [];

if (!empty($data['name'])) {
    $name = mysqli_real_escape_string($connection, trim($data['name']));
    
    // Check if name already exists for other categories
    $nameCheckQuery = mysqli_query($connection, "SELECT id FROM categories WHERE name = '$name' AND id != $category_id LIMIT 1");
    if ($nameCheckQuery && mysqli_num_rows($nameCheckQuery) > 0) {
        http_response_code(400);
        echo json_encode([
            'code' => 400,
            'status' => 'error',
            'message' => 'Category name already exists.'
        ]);
        exit;
    }
    
    $update_fields[] = "name = '$name'";
}

if (!empty($data['code'])) {
    $code = mysqli_real_escape_string($connection, trim($data['code']));
    
    // Check if code already exists for other categories
    $codeCheckQuery = mysqli_query($connection, "SELECT id FROM categories WHERE code = '$code' AND id != $category_id LIMIT 1");
    if ($codeCheckQuery && mysqli_num_rows($codeCheckQuery) > 0) {
        http_response_code(400);
        echo json_encode([
            'code' => 400,
            'status' => 'error',
            'message' => 'Category code already exists.'
        ]);
        exit;
    }
    
    $update_fields[] = "code = '$code'";
}

if (isset($data['description'])) {
    $description = mysqli_real_escape_string($connection, trim($data['description']));
    $update_fields[] = "description = " . ($description ? "'$description'" : "NULL");
}

if (!empty($data['icon'])) {
    $icon = mysqli_real_escape_string($connection, trim($data['icon']));
    $update_fields[] = "icon = '$icon'";
}

if (!empty($data['color'])) {
    $color = mysqli_real_escape_string($connection, trim($data['color']));
    $update_fields[] = "color = '$color'";
}

if (isset($data['sort_order'])) {
    $sort_order = (int)$data['sort_order'];
    $update_fields[] = "sort_order = $sort_order";
}

if (isset($data['is_active'])) {
    $is_active = (bool)$data['is_active'] ? 1 : 0;
    $update_fields[] = "is_active = $is_active";
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

// Build and execute update query
$update_query = "UPDATE categories SET " . implode(", ", $update_fields) . " WHERE id = $category_id";
$update_result = mysqli_query($connection, $update_query);

if (!$update_result) {
    http_response_code(500);
    echo json_encode([
        'code' => 500,
        'status' => 'error',
        'message' => 'Failed to update category: ' . mysqli_error($connection)
    ]);
    exit;
}

// Fetch the updated category
$fetchQuery = mysqli_query($connection, "
    SELECT id, code, name, description, icon, color, sort_order, is_active, created_at, updated_at
    FROM categories 
    WHERE id = $category_id
    LIMIT 1
");

$category = mysqli_fetch_assoc($fetchQuery);

echo json_encode([
    'code' => 200,
    'status' => 'success',
    'message' => 'Category updated successfully.',
    'data' => [
        "id" => (int)$category['id'],
        "code" => $category['code'],
        "name" => $category['name'],
        "description" => $category['description'],
        "icon" => $category['icon'],
        "color" => $category['color'],
        "sort_order" => (int)$category['sort_order'],
        "is_active" => (bool)$category['is_active'],
        "created_at" => $category['created_at'],
        "updated_at" => $category['updated_at']
    ]
]);
?>
