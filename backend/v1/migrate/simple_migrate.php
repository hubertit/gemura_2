<?php
require_once("../configs/configs.php");
header('Content-Type: application/json');

// Simple migration script
// 1. Get phone numbers from old API
// 2. Find users by phone in new DB
// 3. Get their account IDs
// 4. Record collection in new DB

function fetchOldData() {
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
        throw new Exception("Failed to fetch data. HTTP Code: $httpCode");
    }
    
    $data = json_decode($response, true);
    if (!$data || !isset($data['data'])) {
        throw new Exception("Invalid response format");
    }
    
    return $data['data'];
}

function findUserByPhone($connection, $phone) {
    $phone = mysqli_real_escape_string($connection, $phone);
    
    $query = "SELECT id, default_account_id FROM users WHERE phone = '$phone' AND status = 'active' LIMIT 1";
    $result = mysqli_query($connection, $query);
    
    if ($result && mysqli_num_rows($result) > 0) {
        return mysqli_fetch_assoc($result);
    }
    
    return null;
}

function createRelationship($connection, $supplier_account_id, $customer_account_id) {
    $supplier_id = intval($supplier_account_id);
    $customer_id = intval($customer_account_id);
    
    // Check if relationship exists
    $check = "SELECT id FROM suppliers_customers WHERE supplier_account_id = $supplier_id AND customer_account_id = $customer_id LIMIT 1";
    $result = mysqli_query($connection, $check);
    
    if ($result && mysqli_num_rows($result) > 0) {
        return true; // Already exists
    }
    
    // Create relationship
    $insert = "INSERT INTO suppliers_customers (supplier_account_id, customer_account_id, price_per_liter, relationship_status) VALUES ($supplier_id, $customer_id, 340.00, 'active')";
    return mysqli_query($connection, $insert);
}

function migrateCollection($connection, $collection) {
    $supplier_phone = $collection['supplier'];
    $customer_phone = $collection['customer'];
    $quantity = floatval($collection['quantity']);
    $collection_date = $collection['collection_date'];
    $status = strtolower($collection['status']);
    $quality_check = $collection['quality_check'];
    
    // Skip zero quantities
    if ($quantity <= 0) {
        return ['success' => false, 'reason' => 'Zero quantity'];
    }
    
    // Find supplier user
    $supplier_user = findUserByPhone($connection, $supplier_phone);
    if (!$supplier_user) {
        return ['success' => false, 'reason' => "Supplier not found: $supplier_phone"];
    }
    
    // Find customer user
    $customer_user = findUserByPhone($connection, $customer_phone);
    if (!$customer_user) {
        return ['success' => false, 'reason' => "Customer not found: $customer_phone"];
    }
    
    $supplier_account_id = $supplier_user['default_account_id'];
    $customer_account_id = $customer_user['default_account_id'];
    
    // Ensure relationship exists
    createRelationship($connection, $supplier_account_id, $customer_account_id);
    
    // Map status
    $new_status = 'pending';
    if ($status === 'approved') $new_status = 'accepted';
    if ($status === 'rejected') $new_status = 'rejected';
    
    // Create notes
    $notes = "Migrated from V1. Quality: $quality_check. Original ID: {$collection['collection_id']}";
    
    // Insert collection
    $supplier_account_id = intval($supplier_account_id);
    $customer_account_id = intval($customer_account_id);
    $quantity = floatval($quantity);
    $customer_user_id = intval($customer_user['id']);
    
    $insert = "INSERT INTO milk_sales (supplier_account_id, customer_account_id, quantity, unit_price, status, sale_at, notes, recorded_by, created_by) VALUES ($supplier_account_id, $customer_account_id, $quantity, 340.00, '$new_status', '$collection_date', '$notes', $customer_user_id, 1)";
    
    if (mysqli_query($connection, $insert)) {
        return [
            'success' => true,
            'new_id' => mysqli_insert_id($connection),
            'supplier' => $supplier_phone,
            'customer' => $customer_phone,
            'quantity' => $quantity
        ];
    } else {
        return ['success' => false, 'reason' => 'DB Error: ' . mysqli_error($connection)];
    }
}

// Main execution
try {
    $input = json_decode(file_get_contents("php://input"), true);
    $dry_run = isset($input['dry_run']) ? boolval($input['dry_run']) : false;
    
    // Fetch old data
    $old_data = fetchOldData();
    
    $results = [
        'total' => count($old_data),
        'successful' => 0,
        'failed' => 0,
        'details' => []
    ];
    
    if ($dry_run) {
        // Just analyze
        foreach ($old_data as $item) {
            $supplier = findUserByPhone($connection, $item['supplier']);
            $customer = findUserByPhone($connection, $item['customer']);
            
            $results['details'][] = [
                'collection_id' => $item['collection_id'],
                'supplier_phone' => $item['supplier'],
                'customer_phone' => $item['customer'],
                'quantity' => $item['quantity'],
                'supplier_found' => $supplier ? true : false,
                'customer_found' => $customer ? true : false,
                'can_migrate' => ($supplier && $customer && floatval($item['quantity']) > 0)
            ];
            
            if ($supplier && $customer && floatval($item['quantity']) > 0) {
                $results['successful']++;
            } else {
                $results['failed']++;
            }
        }
        
        echo json_encode([
            'code' => 200,
            'status' => 'success',
            'message' => 'Dry run analysis completed',
            'data' => $results
        ]);
        
    } else {
        // Actual migration
        foreach ($old_data as $item) {
            $result = migrateCollection($connection, $item);
            $results['details'][] = $result;
            
            if ($result['success']) {
                $results['successful']++;
            } else {
                $results['failed']++;
            }
        }
        
        echo json_encode([
            'code' => 200,
            'status' => 'success',
            'message' => 'Migration completed',
            'data' => $results
        ]);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'code' => 500,
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
}
?>
