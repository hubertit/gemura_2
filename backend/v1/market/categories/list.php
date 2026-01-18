<?php
require_once("../../configs/configs.php");
header('Content-Type: application/json');

// Fetch all active categories, ordered by sort_order
$query = mysqli_query($connection, "
    SELECT id, code, name, description, icon, color, sort_order, created_at, updated_at
    FROM categories 
    WHERE is_active = 1
    ORDER BY sort_order ASC, name ASC
");

$categories = [];
if ($query && mysqli_num_rows($query) > 0) {
    while ($row = mysqli_fetch_assoc($query)) {
        $categories[] = [
            "id" => (int)$row['id'],
            "code" => $row['code'],
            "name" => $row['name'],
            "description" => $row['description'],
            "icon" => $row['icon'],
            "color" => $row['color'],
            "sort_order" => (int)$row['sort_order'],
            "created_at" => $row['created_at'],
            "updated_at" => $row['updated_at']
        ];
    }
}

echo json_encode([
    "code" => 200,
    "status" => "success",
    "message" => "Categories fetched successfully.",
    "data" => $categories
]);
?>
