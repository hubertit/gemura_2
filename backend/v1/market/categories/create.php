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
$required = ['name', 'code'];
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

// Sanitize and prepare variables
$code = mysqli_real_escape_string($connection, trim($data['code']));
$name = mysqli_real_escape_string($connection, trim($data['name']));
$description = !empty($data['description']) ? mysqli_real_escape_string($connection, trim($data['description'])) : null;
$icon = !empty($data['icon']) ? mysqli_real_escape_string($connection, trim($data['icon'])) : null;
$color = !empty($data['color']) ? mysqli_real_escape_string($connection, trim($data['color'])) : '#4CAF50';
$sort_order = !empty($data['sort_order']) ? (int)$data['sort_order'] : 0;

// Check if code already exists
$checkQuery = mysqli_query($connection, "SELECT id FROM categories WHERE code = '$code' LIMIT 1");
if ($checkQuery && mysqli_num_rows($checkQuery) > 0) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'Category code already exists.'
    ]);
    exit;
}

// Check if name already exists
$checkNameQuery = mysqli_query($connection, "SELECT id FROM categories WHERE name = '$name' LIMIT 1");
if ($checkNameQuery && mysqli_num_rows($checkNameQuery) > 0) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'Category name already exists.'
    ]);
    exit;
}

// Insert new category
$insertQuery = mysqli_query($connection, "
    INSERT INTO categories (code, name, description, icon, color, sort_order, is_active, created_at, updated_at)
    VALUES ('$code', '$name', " . ($description ? "'$description'" : "NULL") . ", " . ($icon ? "'$icon'" : "NULL") . ", 
            '$color', $sort_order, 1, NOW(), NOW())
");

if (!$insertQuery) {
    http_response_code(500);
    echo json_encode([
        'code' => 500,
        'status' => 'error',
        'message' => 'Failed to create category: ' . mysqli_error($connection)
    ]);
    exit;
}

$category_id = mysqli_insert_id($connection);

// Fetch the created category
$fetchQuery = mysqli_query($connection, "
    SELECT id, code, name, description, icon, color, sort_order, is_active, created_at, updated_at
    FROM categories 
    WHERE id = $category_id
    LIMIT 1
");

$category = mysqli_fetch_assoc($fetchQuery);

echo json_encode([
    'code' => 201,
    'status' => 'success',
    'message' => 'Category created successfully.',
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
