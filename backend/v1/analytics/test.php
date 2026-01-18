<?php
// Simple test file for analytics API
echo "Analytics API Test\n";
echo "==================\n\n";

$baseUrl = "http://localhost/gemura2/api/v2/analytics/";
$token = "YOUR_TEST_TOKEN_HERE"; // Replace with actual token

$endpoints = [
    "collections" => "collections.php",
    "metrics" => "metrics.php", 
    "customers" => "customers.php"
];

foreach ($endpoints as $name => $endpoint) {
    echo "Testing $name endpoint...\n";
    
    $data = [
        "token" => $token,
        "date_from" => "2024-01-01",
        "date_to" => "2024-12-31"
    ];
    
    $ch = curl_init();
    $url = $baseUrl . $endpoint . '?' . http_build_query($data);
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    echo "HTTP Code: $httpCode\n";
    echo "Response: " . substr($response, 0, 200) . "...\n\n";
}

echo "Test completed!\n";
?>
