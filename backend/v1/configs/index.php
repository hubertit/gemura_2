<?php
header('Content-Type: application/json');
require("connection.php");
//require("token.php");
require("validate.data.php");

// Conversion rate from USD to ZMW
$conversionRate = 0.017; // Example conversion rate

// Define the target store ID
$newStoreId = 2; // Change to your target store ID

// Fetch existing product details from the original store
$originalStoreId = 1; // Change to your source store ID
$result = mysqli_query($connection, "SELECT * FROM products WHERE store_id = $originalStoreId");



// Loop through each product and insert into the new store with converted prices and new store_id
while ($product = mysqli_fetch_assoc($result)) {
    // Convert prices from USD to ZMW
    $newPrice = $product['product_price'] * $conversionRate;
    $newDiscountPrice = $product['product_discount_price'] * $conversionRate;

    // Insert the product into the new store
    $query = mysqli_query($connection, "INSERT INTO `products` 
    (`product_id`, `product_sku`, `product_name`, `product_description`, `product_image`, `product_price`, `product_discount_price`, `product_status`, `store_id`) 
    VALUES (NULL, '{$product['product_sku']}', '{$product['product_name']}', '{$product['product_description']}', '{$product['product_image']}', '$newPrice', '$newDiscountPrice', '{$product['product_status']}', '$newStoreId')");

    if (!$query) {
        die("Error inserting product: " . mysqli_error($connection));
    }

    // Get the inserted product ID
    $newProductId = mysqli_insert_id($connection);

    // Duplicate the product categories
    $categoriesResult = mysqli_query($connection, "SELECT * FROM products_categories WHERE product_id = {$product['product_id']}");
    if ($categoriesResult) {
        while ($category = mysqli_fetch_assoc($categoriesResult)) {
            $categoryQuery = mysqli_query($connection, "INSERT INTO `products_categories` (`id`, `product_id`, `category_id`) 
            VALUES (NULL, '$newProductId', '{$category['category_id']}')");
            if (!$categoryQuery) {
                die("Error inserting product category: " . mysqli_error($connection));
            }
        }
    }
}

// Success message
echo "Products have been successfully duplicated to store ID $newStoreId with prices converted to ZMW.";

// Close the connection
mysqli_close($connection);