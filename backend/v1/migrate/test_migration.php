<?php
// Test script for migration API
// This script helps you test the migration with different parameters

$api_url = 'https://api.gemura.rw/v2/migrate/collections.php';

// Test scenarios
$test_scenarios = [
    'dry_run_small' => [
        'dry_run' => true,
        'limit' => 10,
        'description' => 'Dry run with 10 records'
    ],
    'dry_run_medium' => [
        'dry_run' => true,
        'limit' => 50,
        'description' => 'Dry run with 50 records'
    ],
    'actual_small' => [
        'dry_run' => false,
        'limit' => 5,
        'description' => 'Actual migration with 5 records'
    ],
    'actual_medium' => [
        'dry_run' => false,
        'limit' => 20,
        'description' => 'Actual migration with 20 records'
    ]
];

function testMigration($url, $data, $scenario_name) {
    echo "\n=== Testing: $scenario_name ===\n";
    echo "Description: {$data['description']}\n";
    
    $json_data = json_encode($data);
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $json_data);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Content-Length: ' . strlen($json_data)
    ]);
    curl_setopt($ch, CURLOPT_TIMEOUT, 60);
    
    $response = curl_exec($ch);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    echo "HTTP Code: $http_code\n";
    
    if ($response) {
        $result = json_decode($response, true);
        if ($result) {
            echo "Status: {$result['status']}\n";
            echo "Message: {$result['message']}\n";
            
            if (isset($result['data'])) {
                $data = $result['data'];
                echo "Total Processed: {$data['total_processed']}\n";
                echo "Successful: {$data['successful']}\n";
                echo "Failed: {$data['failed']}\n";
                
                // Show some details for failed items
                if ($data['failed'] > 0) {
                    echo "\nFailed Items (first 5):\n";
                    $failed_count = 0;
                    foreach ($data['details'] as $detail) {
                        if (!$detail['success'] && $failed_count < 5) {
                            echo "- Collection ID: {$detail['collection_id']} - {$detail['reason']}\n";
                            $failed_count++;
                        }
                    }
                }
            }
        } else {
            echo "Invalid JSON response\n";
            echo "Raw response: $response\n";
        }
    } else {
        echo "No response received\n";
    }
    
    echo "================================\n";
}

// Run tests
echo "Starting Migration Tests...\n";
echo "API URL: $api_url\n";

foreach ($test_scenarios as $scenario => $data) {
    testMigration($api_url, $data, $scenario);
    
    // Add delay between tests
    sleep(2);
}

echo "\nAll tests completed!\n";
echo "\nTo run a specific test manually, use:\n";
echo "curl -X POST $api_url \\\n";
echo "  -H 'Content-Type: application/json' \\\n";
echo "  -d '{\"dry_run\": true, \"limit\": 10}'\n";
?>
