<?php

// Migration script to register real users from old system to new v2 API
// Based on data from: https://app.gemura.rw/api/public/users

$oldUsersData = [
    [
        "name" => "UWERA Bonnefete",
        "email" => null, // No email in old data
        "phone" => "0785289566",
        "nid" => null, // No NID in old data
        "role" => "owner",
        "account_name" => "UWERA Bonnefete"
    ],
    [
        "name" => "Erica-Livia Ingabire",
        "email" => "ingabireericalivia@gmail.com",
        "phone" => "0790137395",
        "nid" => null,
        "role" => "farmer",
        "account_name" => "Erica-Livia Ingabire"
    ],
    [
        "name" => "NIYIKORA Jean",
        "email" => null,
        "phone" => "0728496215",
        "nid" => null,
        "role" => "farmer",
        "account_name" => "NIYIKORA Jean"
    ],
    [
        "name" => "BIZIMANA Donath",
        "email" => null,
        "phone" => "0783269503",
        "nid" => null,
        "role" => "farmer",
        "account_name" => "BIZIMANA Donath"
    ],
    [
        "name" => "Kalisa Sulaiman",
        "email" => "sulaimankalisa@gmail.com",
        "phone" => "0788461649",
        "nid" => null,
        "role" => "farmer",
        "account_name" => "Kalisa Sulaiman"
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

// Start migration
echo "Starting migration of 5 real users to v2 API...\n\n";

$registeredUsers = [];
$failedUsers = [];

foreach ($oldUsersData as $index => $userData) {
    echo "Registering user " . ($index + 1) . ": " . $userData["name"] . "\n";
    echo "   Phone: " . $userData["phone"] . "\n";
    echo "   Email: " . ($userData["email"] ?: "Not provided") . "\n";
    echo "   Role: " . $userData["role"] . "\n";
    
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

if (!empty($failedUsers)) {
    echo "\nFailed users:\n";
    foreach ($failedUsers as $failed) {
        echo "- " . $failed['user_data']['name'] . ": " . $failed['error'] . "\n";
    }
}

echo "\nMigration completed!\n";
?>
