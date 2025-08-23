<?php

// Migration script to register 5 more real users with suppliers
// Based on latest data from: https://app.gemura.rw/api/public/users

$oldUsersData = [
    [
        "name" => "Nsengiyumba Bonifas",
        "email" => null,
        "phone" => "0787407683",
        "nid" => null,
        "role" => "farmer",
        "account_name" => "Nsengiyumba Bonifas",
        "wallet_equity" => "2182440"
    ],
    [
        "name" => "Ndebera Eric",
        "email" => null,
        "phone" => "0789375162",
        "nid" => null,
        "role" => "farmer",
        "account_name" => "Ndebera Eric",
        "wallet_equity" => "1248390"
    ],
    [
        "name" => "Festo Ndayisenga",
        "email" => "festondayisenga2016@gmail.com",
        "phone" => "0782638531",
        "nid" => null,
        "role" => "farmer",
        "account_name" => "Festo Ndayisenga",
        "wallet_equity" => "60000"
    ],
    [
        "name" => "Ruhimbana Muzamil",
        "email" => "muzamil@orora.rw",
        "phone" => "0783717710",
        "nid" => null,
        "role" => "admin",
        "account_name" => "Ruhimbana Muzamil",
        "wallet_equity" => "886000"
    ],
    [
        "name" => "Abdoul",
        "email" => null,
        "phone" => "0780463691",
        "nid" => null,
        "role" => "admin",
        "account_name" => "Abdoul",
        "wallet_equity" => "23500"
    ]
];

// Supplier data for each user
$suppliersData = [
    [
        "name" => "Nsengiyumba Dairy Farm",
        "phone" => "250787407683",
        "email" => "nsengiyumba.dairy@example.com",
        "nid" => "1199880012345681",
        "address" => "Gisagara, Southern Province",
        "price_per_liter" => 340
    ],
    [
        "name" => "Ndebera Milk Collection",
        "phone" => "250789375162",
        "email" => "ndepera.milk@example.com",
        "nid" => "1199880012345682",
        "address" => "Gisagara, Southern Province",
        "price_per_liter" => 330
    ],
    [
        "name" => "Festo Dairy Supplier",
        "phone" => "250782638531",
        "email" => "festo.dairy@example.com",
        "nid" => "1199880012345683",
        "address" => "Kigali, Rwanda",
        "price_per_liter" => 350
    ],
    [
        "name" => "Ruhimbana Collection Center",
        "phone" => "250783717710",
        "email" => "ruhimbana.collection@example.com",
        "nid" => "1199880012345684",
        "address" => "Kigali, Rwanda",
        "price_per_liter" => 360
    ],
    [
        "name" => "Abdoul Dairy Farm",
        "phone" => "250780463691",
        "email" => "abdoul.dairy@example.com",
        "nid" => "1199880012345685",
        "address" => "Kigali, Rwanda",
        "price_per_liter" => 345
    ]
];

function registerUser($userData) {
    $curl = curl_init();
    
    $postData = [
        "name" => $userData["name"],
        "phone" => "+250" . $userData["phone"],
        "password" => "password123", // Default password for all users
        "role" => $userData["role"],
        "account_name" => $userData["account_name"],
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

// Start migration
echo "Starting migration of 5 more users with suppliers to v2 API...\n\n";

$registeredUsers = [];
$failedUsers = [];
$suppliersCreated = 0;
$suppliersFailed = 0;

foreach ($oldUsersData as $index => $userData) {
    echo "Registering user " . ($index + 1) . ": " . $userData["name"] . "\n";
    echo "   Phone: " . $userData["phone"] . "\n";
    echo "   Email: " . ($userData["email"] ?: "Not provided") . "\n";
    echo "   Role: " . $userData["role"] . "\n";
    echo "   Wallet Equity: " . $userData["wallet_equity"] . " RWF\n";
    
    $result = registerUser($userData);
    
    if ($result['http_code'] == 200) {
        $responseData = json_decode($result['response'], true);
        
        if ($responseData['code'] == 201) {
            $token = $responseData['data']['user']['token'] ?? null;
            $userCode = $responseData['data']['user']['code'] ?? 'N/A';
            
            echo "✅ Success: " . $userData["name"] . " registered\n";
            echo "   User Code: " . $userCode . "\n";
            echo "   Token: " . substr($token, 0, 20) . "...\n\n";
            
            $registeredUsers[] = [
                'user_data' => $userData,
                'token' => $token,
                'response' => $responseData
            ];
            
            // Create supplier for this user
            if ($token && isset($suppliersData[$index])) {
                echo "Creating supplier for: " . $userData["name"] . "\n";
                $supplierData = $suppliersData[$index];
                
                $supplierResult = createSupplier($token, $supplierData);
                
                if ($supplierResult['http_code'] == 201) {
                    echo "✅ Supplier created successfully\n";
                    echo "   Name: " . $supplierData['name'] . "\n";
                    echo "   Price per liter: " . $supplierData['price_per_liter'] . " RWF\n";
                    echo "   Address: " . $supplierData['address'] . "\n\n";
                    $suppliersCreated++;
                } else {
                    echo "❌ Supplier creation failed\n";
                    echo "   HTTP Code: " . $supplierResult['http_code'] . "\n";
                    echo "   Response: " . $supplierResult['response'] . "\n\n";
                    $suppliersFailed++;
                }
            }
            
        } else {
            echo "❌ Failed: " . $userData["name"] . "\n";
            echo "   Response: " . $result['response'] . "\n\n";
            
            $failedUsers[] = [
                'user_data' => $userData,
                'error' => $result['response']
            ];
        }
        
        // Add a small delay to avoid overwhelming the API
        sleep(1);
        
    } else {
        echo "❌ Failed: " . $userData["name"] . "\n";
        echo "   HTTP Code: " . $result['http_code'] . "\n";
        echo "   Response: " . $result['response'] . "\n\n";
        
        $failedUsers[] = [
            'user_data' => $userData,
            'error' => $result['response']
        ];
    }
}

// Summary
echo "=== MIGRATION SUMMARY ===\n";
echo "Total users processed: " . count($oldUsersData) . "\n";
echo "Successfully registered: " . count($registeredUsers) . "\n";
echo "Failed registrations: " . count($failedUsers) . "\n";
echo "Suppliers created: " . $suppliersCreated . "\n";
echo "Suppliers failed: " . $suppliersFailed . "\n";

if (!empty($failedUsers)) {
    echo "\nFailed users:\n";
    foreach ($failedUsers as $failed) {
        echo "- " . $failed['user_data']['name'] . ": " . $failed['error'] . "\n";
    }
}

echo "\nMigration completed!\n";
?>
