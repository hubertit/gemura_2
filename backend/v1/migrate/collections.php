<?php
require_once("../configs/configs.php");
header('Content-Type: application/json');

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Function to fetch data from old API
function fetchOldCollections() {
    $url = 'https://app.gemura.rw/api/public/milk_collection';
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 30);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode !== 200) {
        throw new Exception("Failed to fetch data from old API. HTTP Code: $httpCode");
    }
    
    $data = json_decode($response, true);
    if (!$data || !isset($data['data'])) {
        throw new Exception("Invalid response format from old API");
    }
    
    return $data['data'];
}

// Function to get user account by phone number
function getUserAccountByPhone($connection, $phone) {
    $phone = mysqli_real_escape_string($connection, $phone);
    
    $query = "
        SELECT u.id as user_id, u.default_account_id as account_id, a.code as account_code, a.name as account_name
        FROM users u
        LEFT JOIN accounts a ON a.id = u.default_account_id
        WHERE u.phone = '$phone' AND u.status = 'active'
        LIMIT 1
    ";
    
    $result = mysqli_query($connection, $query);
    if (!$result || mysqli_num_rows($result) === 0) {
        return null;
    }
    
    return mysqli_fetch_assoc($result);
}

// Function to create supplier-customer relationship if it doesn't exist
function ensureSupplierCustomerRelationship($connection, $supplier_account_id, $customer_account_id, $default_price = 340.00) {
    $supplier_account_id = intval($supplier_account_id);
    $customer_account_id = intval($customer_account_id);
    
    // Check if relationship exists
    $checkQuery = "
        SELECT id FROM suppliers_customers 
        WHERE supplier_account_id = $supplier_account_id 
        AND customer_account_id = $customer_account_id
        LIMIT 1
    ";
    
    $result = mysqli_query($connection, $checkQuery);
    if ($result && mysqli_num_rows($result) > 0) {
        return true; // Relationship already exists
    }
    
    // Create relationship
    $insertQuery = "
        INSERT INTO suppliers_customers (
            supplier_account_id, 
            customer_account_id, 
            price_per_liter, 
            relationship_status
        ) VALUES (
            $supplier_account_id,
            $customer_account_id,
            $default_price,
            'active'
        )
    ";
    
    return mysqli_query($connection, $insertQuery);
}

// Function to migrate a single collection
function migrateCollection($connection, $collection, $migration_user_id) {
    $supplier_phone = $collection['supplier'];
    $customer_phone = $collection['customer'];
    $quantity = floatval($collection['quantity']);
    $collection_date = $collection['collection_date'];
    $status = strtolower($collection['status']);
    $quality_check = $collection['quality_check'];
    
    // Skip if quantity is 0
    if ($quantity <= 0) {
        return [
            'success' => false,
            'reason' => 'Zero quantity',
            'collection_id' => $collection['collection_id']
        ];
    }
    
    // Get supplier account
    $supplier_account = getUserAccountByPhone($connection, $supplier_phone);
    if (!$supplier_account) {
        return [
            'success' => false,
            'reason' => "Supplier not found: $supplier_phone",
            'collection_id' => $collection['collection_id']
        ];
    }
    
    // Get customer account
    $customer_account = getUserAccountByPhone($connection, $customer_phone);
    if (!$customer_account) {
        return [
            'success' => false,
            'reason' => "Customer not found: $customer_phone",
            'collection_id' => $collection['collection_id']
        ];
    }
    
    // Ensure supplier-customer relationship exists
    ensureSupplierCustomerRelationship($connection, $supplier_account['account_id'], $customer_account['account_id']);
    
    // Get unit price from relationship
    $priceQuery = "
        SELECT price_per_liter
        FROM suppliers_customers
        WHERE supplier_account_id = {$supplier_account['account_id']} 
        AND customer_account_id = {$customer_account['account_id']}
        AND relationship_status = 'active'
        LIMIT 1
    ";
    
    $priceResult = mysqli_query($connection, $priceQuery);
    $unit_price = 340.00; // Default price
    if ($priceResult && mysqli_num_rows($priceResult) > 0) {
        $priceRow = mysqli_fetch_assoc($priceResult);
        $unit_price = $priceRow['price_per_liter'];
    }
    
    // Map status
    $new_status = 'pending';
    if ($status === 'approved') {
        $new_status = 'accepted';
    } elseif ($status === 'rejected') {
        $new_status = 'rejected';
    }
    
    // Create notes with quality check info
    $notes = "Migrated from V1. Quality: $quality_check. Original ID: {$collection['collection_id']}";
    
    // Insert into milk_sales table
    $insertQuery = "
        INSERT INTO milk_sales (
            supplier_account_id,
            customer_account_id,
            quantity,
            unit_price,
            status,
            sale_at,
            notes,
            recorded_by,
            created_by
        )
        VALUES (
            {$supplier_account['account_id']},
            {$customer_account['account_id']},
            $quantity,
            $unit_price,
            '$new_status',
            '$collection_date',
            '$notes',
            {$customer_account['user_id']},
            $migration_user_id
        )
    ";
    
    if (mysqli_query($connection, $insertQuery)) {
        return [
            'success' => true,
            'new_id' => mysqli_insert_id($connection),
            'collection_id' => $collection['collection_id'],
            'supplier' => $supplier_phone,
            'customer' => $customer_phone,
            'quantity' => $quantity,
            'amount' => $quantity * $unit_price
        ];
    } else {
        return [
            'success' => false,
            'reason' => 'Database error: ' . mysqli_error($connection),
            'collection_id' => $collection['collection_id']
        ];
    }
}

// Main migration logic
try {
    // Get migration parameters
    $input_data = file_get_contents("php://input");
    $data = json_decode($input_data, true);
    
    $token = isset($data['token']) ? mysqli_real_escape_string($connection, $data['token']) : null;
    $migration_user_id = isset($data['migration_user_id']) ? intval($data['migration_user_id']) : 1;
    $limit = isset($data['limit']) ? intval($data['limit']) : 100; // Default limit
    $dry_run = isset($data['dry_run']) ? boolval($data['dry_run']) : false;
    
    // Validate token if provided
    if ($token) {
        $userQuery = mysqli_query($connection, "
            SELECT id FROM users WHERE token = '$token' AND status = 'active' LIMIT 1
        ");
        
        if (!$userQuery || mysqli_num_rows($userQuery) === 0) {
            http_response_code(403);
            echo json_encode([
                "code" => 403,
                "status" => "error",
                "message" => "Unauthorized. Invalid token."
            ]);
            exit;
        }
        
        $user = mysqli_fetch_assoc($userQuery);
        $migration_user_id = $user['id'];
    }
    
    // Fetch old collections
    $old_collections = fetchOldCollections();
    
    // Limit the number of records to process
    $old_collections = array_slice($old_collections, 0, $limit);
    
    $results = [
        'total_processed' => count($old_collections),
        'successful' => 0,
        'failed' => 0,
        'details' => []
    ];
    
    if ($dry_run) {
        // Dry run - just analyze the data
        foreach ($old_collections as $collection) {
            $supplier_phone = $collection['supplier'];
            $customer_phone = $collection['customer'];
            $quantity = floatval($collection['quantity']);
            
            $supplier_account = getUserAccountByPhone($connection, $supplier_phone);
            $customer_account = getUserAccountByPhone($connection, $customer_phone);
            
            $results['details'][] = [
                'collection_id' => $collection['collection_id'],
                'supplier_phone' => $supplier_phone,
                'customer_phone' => $customer_phone,
                'quantity' => $quantity,
                'supplier_found' => $supplier_account ? true : false,
                'customer_found' => $customer_account ? true : false,
                'can_migrate' => ($supplier_account && $customer_account && $quantity > 0)
            ];
            
            if ($supplier_account && $customer_account && $quantity > 0) {
                $results['successful']++;
            } else {
                $results['failed']++;
            }
        }
        
        echo json_encode([
            "code" => 200,
            "status" => "success",
            "message" => "Dry run completed. Analysis results:",
            "data" => $results
        ]);
        
    } else {
        // Actual migration
        foreach ($old_collections as $collection) {
            $result = migrateCollection($connection, $collection, $migration_user_id);
            $results['details'][] = $result;
            
            if ($result['success']) {
                $results['successful']++;
            } else {
                $results['failed']++;
            }
        }
        
        echo json_encode([
            "code" => 200,
            "status" => "success",
            "message" => "Migration completed successfully.",
            "data" => $results
        ]);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "code" => 500,
        "status" => "error",
        "message" => "Migration failed: " . $e->getMessage()
    ]);
}
?>
