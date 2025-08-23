<?php

// Comprehensive migration script to register ALL users from old system to new v2 API
// Based on data from: https://app.gemura.rw/api/public/users

// Read the JSON data file
$jsonData = file_get_contents('latest_users_data.json');
$data = json_decode($jsonData, true);

if (!$data || !isset($data['data'])) {
    die("Error: Could not read or parse the JSON data file.\n");
}

$users = $data['data'];
$totalUsers = count($users);

echo "Found {$totalUsers} users in the old system.\n";
echo "Starting comprehensive migration to v2 API...\n\n";

// Track migration progress
$registeredUsers = [];
$failedUsers = [];
$suppliersCreated = 0;
$suppliersFailed = 0;
$processedCount = 0;

// Function to register a user
function registerUser($userData) {
    $curl = curl_init();
    
    $postData = [
        "name" => $userData["name"],
        "phone" => "+250" . $userData["phone"],
        "password" => "password123", // Default password for all users
        "role" => $userData["role"],
        "account_name" => $userData["name"],
        "permissions" => [
            "can_collect" => true,
            "can_add_supplier" => true,
            "can_view_reports" => true
        ]
    ];
    
    // Add email only if available
    if (!empty($userData["email"])) {
        $postData["email"] = $userData["email"];
    }
    
    // Add NID only if available
    if (!empty($userData["nid"])) {
        $postData["nid"] = $userData["nid"];
    }
    
    curl_setopt_array($curl, array(
        CURLOPT_URL => 'https://api.gemura.rw/v2/auth/register',
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_ENCODING => '',
        CURLOPT_MAXREDIRS => 10,
        CURLOPT_TIMEOUT => 30,
        CURLOPT_FOLLOWLOCATION => true,
        CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
        CURLOPT_CUSTOMREQUEST => 'POST',
        CURLOPT_POSTFIELDS => json_encode($postData),
        CURLOPT_HTTPHEADER => array(
            'Content-Type: application/json'
        ),
    ));
    
    $response = curl_exec($curl);
    $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
    curl_close($curl);
    
    return [
        'http_code' => $httpCode,
        'response' => $response,
        'user_data' => $userData
    ];
}

// Function to create supplier
function createSupplier($token, $supplierData) {
    $curl = curl_init();
    
    $postData = array_merge(["token" => $token], $supplierData);
    
    curl_setopt_array($curl, array(
        CURLOPT_URL => 'https://api.gemura.rw/v2/suppliers/create',
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_ENCODING => '',
        CURLOPT_MAXREDIRS => 10,
        CURLOPT_TIMEOUT => 30,
        CURLOPT_FOLLOWLOCATION => true,
        CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
        CURLOPT_CUSTOMREQUEST => 'POST',
        CURLOPT_POSTFIELDS => json_encode($postData),
        CURLOPT_HTTPHEADER => array(
            'Content-Type: application/json'
        ),
    ));
    
    $response = curl_exec($curl);
    $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
    curl_close($curl);
    
    return [
        'http_code' => $httpCode,
        'response' => $response,
        'supplier_data' => $supplierData
    ];
}

// Process all users
foreach ($users as $index => $user) {
    $processedCount++;
    
    // Skip if already processed (phone 0788606765 appears multiple times)
    $phoneKey = $user['user_phone'];
    if (isset($processedPhones[$phoneKey])) {
        echo "Skipping duplicate phone: {$phoneKey} (User: {$user['user_fname']} {$user['user_lname']})\n";
        continue;
    }
    $processedPhones[$phoneKey] = true;
    
    // Prepare user data
    $userData = [
        "name" => $user['user_fname'] . " " . $user['user_lname'],
        "email" => $user['user_email'],
        "phone" => $user['user_phone'],
        "nid" => null, // No NID in old data
        "role" => strtolower($user['user_category']),
        "account_name" => $user['user_fname'] . " " . $user['user_lname'],
        "wallet_equity" => $user['wallet_equity'] ?? "0"
    ];
    
    // Special handling for admin users
    if (strtolower($user['user_category']) === 'admin') {
        $userData["role"] = "owner";
    }
    
    echo "Processing user {$processedCount}/{$totalUsers}: {$userData['name']}\n";
    echo "   Phone: {$userData['phone']}\n";
    echo "   Email: " . ($userData['email'] ?: "Not provided") . "\n";
    echo "   Role: {$userData['role']}\n";
    echo "   Category: {$user['user_category']}\n";
    echo "   Wallet Equity: {$userData['wallet_equity']} RWF\n";
    
    $result = registerUser($userData);
    
    if ($result['http_code'] == 200) {
        $responseData = json_decode($result['response'], true);
        
        if ($responseData['code'] == 201) {
            $token = $responseData['data']['user']['token'] ?? null;
            $userCode = $responseData['data']['user']['code'] ?? 'N/A';
            
            echo "✅ Success: {$userData['name']} registered\n";
            echo "   User Code: {$userCode}\n";
            echo "   Token: " . substr($token, 0, 20) . "...\n\n";
            
            $registeredUsers[] = [
                'user_data' => $userData,
                'token' => $token,
                'response' => $responseData,
                'original_user' => $user
            ];
            
            // Create supplier for users who have suppliers in old system
            if ($token && !empty($user['suppliers'])) {
                echo "Creating suppliers for: {$userData['name']}\n";
                
                foreach ($user['suppliers'] as $supplierIndex => $supplier) {
                    $supplierData = [
                        "name" => $supplier['user_fname'] . " " . $supplier['user_lname'] . " Supplier",
                        "phone" => "250" . $supplier['user_phone'],
                        "email" => $supplier['user_email'] ?: "supplier" . ($supplierIndex + 1) . "@example.com",
                        "nid" => "1199880012345" . str_pad($supplierIndex + 1, 3, "0", STR_PAD_LEFT),
                        "address" => "Rwanda",
                        "price_per_liter" => 340 + ($supplierIndex * 5) // Varying prices
                    ];
                    
                    $supplierResult = createSupplier($token, $supplierData);
                    
                    if ($supplierResult['http_code'] == 200) {
                        $supplierResponse = json_decode($supplierResult['response'], true);
                        if ($supplierResponse['code'] == 201) {
                            echo "✅ Supplier created: {$supplierData['name']}\n";
                            $suppliersCreated++;
                        } else {
                            echo "❌ Supplier creation failed: {$supplierData['name']}\n";
                            $suppliersFailed++;
                        }
                    } else {
                        echo "❌ Supplier creation failed: {$supplierData['name']}\n";
                        $suppliersFailed++;
                    }
                    
                    sleep(1); // Delay between supplier creations
                }
                echo "\n";
            }
            
        } else {
            echo "❌ Failed: {$userData['name']}\n";
            echo "   Response: {$result['response']}\n\n";
            
            $failedUsers[] = [
                'user_data' => $userData,
                'error' => $result['response'],
                'original_user' => $user
            ];
        }
        
        // Add a small delay to avoid overwhelming the API
        sleep(1);
        
    } else {
        echo "❌ Failed: {$userData['name']}\n";
        echo "   HTTP Code: {$result['http_code']}\n";
        echo "   Response: {$result['response']}\n\n";
        
        $failedUsers[] = [
            'user_data' => $userData,
            'error' => $result['response'],
            'original_user' => $user
        ];
    }
    
    // Progress update every 10 users
    if ($processedCount % 10 == 0) {
        echo "=== PROGRESS UPDATE ===\n";
        echo "Processed: {$processedCount}/{$totalUsers}\n";
        echo "Successfully registered: " . count($registeredUsers) . "\n";
        echo "Failed: " . count($failedUsers) . "\n";
        echo "Suppliers created: {$suppliersCreated}\n";
        echo "Suppliers failed: {$suppliersFailed}\n\n";
    }
}

// Final summary
echo "=== FINAL MIGRATION SUMMARY ===\n";
echo "Total users in old system: {$totalUsers}\n";
echo "Total users processed: {$processedCount}\n";
echo "Successfully registered: " . count($registeredUsers) . "\n";
echo "Failed registrations: " . count($failedUsers) . "\n";
echo "Suppliers created: {$suppliersCreated}\n";
echo "Suppliers failed: {$suppliersFailed}\n";

if (!empty($failedUsers)) {
    echo "\nFailed users:\n";
    foreach ($failedUsers as $failed) {
        echo "- {$failed['user_data']['name']} ({$failed['user_data']['phone']}): {$failed['error']}\n";
    }
}

// Save results to file
$results = [
    'timestamp' => date('Y-m-d H:i:s'),
    'total_users' => $totalUsers,
    'processed_count' => $processedCount,
    'registered_users' => $registeredUsers,
    'failed_users' => $failedUsers,
    'suppliers_created' => $suppliersCreated,
    'suppliers_failed' => $suppliersFailed
];

file_put_contents('migration_results.json', json_encode($results, JSON_PRETTY_PRINT));

echo "\nMigration results saved to: migration_results.json\n";
echo "Migration completed!\n";
?>
