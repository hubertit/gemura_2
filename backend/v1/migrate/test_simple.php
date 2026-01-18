<?php
require_once("../configs/configs.php");
header('Content-Type: application/json');

// Simple test script
echo json_encode([
    'code' => 200,
    'status' => 'success',
    'message' => 'API is working!',
    'timestamp' => date('Y-m-d H:i:s'),
    'connection' => $connection ? 'OK' : 'FAILED'
]);
?>
