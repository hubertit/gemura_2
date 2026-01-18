<?php
require_once("../configs/configs.php");

header('Content-Type: application/json');

$input_data = file_get_contents("php://input");
$data = json_decode($input_data, true);

// Validate JSON format
if (json_last_error() !== JSON_ERROR_NONE) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'Invalid JSON format.'
    ]);
    exit;
}

// Ensure token is provided
if (!isset($data['token']) || empty(trim($data['token']))) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'Token is required.'
    ]);
    exit;
}

$token = trim($data['token']);

// Query user with token
$stmt = $connection->prepare("
    SELECT code, name, email, phone, status 
    FROM users 
    WHERE token = ? AND status = 'active' 
    LIMIT 1
");

$stmt->bind_param("s", $token);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    http_response_code(401);
    echo json_encode([
        'code' => 401,
        'status' => 'error',
        'message' => 'Token is invalid or expired.'
    ]);
    exit;
}

$user = $result->fetch_assoc();
$stmt->close();

// Success
http_response_code(200);
echo json_encode([
    'code' => 200,
    'status' => 'success',
    'message' => 'Token is valid.',
    'data' => $user
]);
?>
