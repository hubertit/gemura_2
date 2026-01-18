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
        "message" => "Missing category ID."
    ]);
    exit;
}

$category_id = (int)$data['id'];

// Fetch category by ID
$query = mysqli_query($connection, "
    SELECT id, code, name, description, icon, color, sort_order, is_active, created_at, updated_at
    FROM categories 
    WHERE id = $category_id
    LIMIT 1
");

if (!$query || mysqli_num_rows($query) === 0) {
    http_response_code(404);
    echo json_encode([
        "code" => 404,
        "status" => "error",
        "message" => "Category not found."
    ]);
    exit;
}

$category = mysqli_fetch_assoc($query);

echo json_encode([
    "code" => 200,
    "status" => "success",
    "message" => "Category fetched successfully.",
    "data" => [
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
