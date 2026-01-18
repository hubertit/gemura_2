<?php
require_once("../configs/configs.php");

header('Content-Type: application/json');

// SMS Helper Function
function sendSMS($recipient, $message) {
    global $connection;
    
    try {
        // Get Mista SMS API key from database
        $stmt = $connection->prepare("
            SELECT key_value FROM api_keys 
            WHERE key_type = 'mista' AND is_active = 1 
            LIMIT 1
        ");
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            error_log("SMS API key not found or inactive");
            return false;
        }
        
        $apiKey = $result->fetch_assoc()['key_value'];
        $stmt->close();
        
        // Prepare SMS data
        $smsData = [
            'recipient' => $recipient,
            'sender_id' => 'E-Notifier',
            'type' => 'plain',
            'message' => $message
        ];
        
        // Send SMS via Mista API
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, 'https://api.mista.io/sms');
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($smsData));
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Authorization: Bearer ' . $apiKey,
            'Content-Type: application/json'
        ]);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 30);
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        if ($httpCode === 200) {
            $responseData = json_decode($response, true);
            if (isset($responseData['status']) && $responseData['status'] === 'success') {
                error_log("SMS sent successfully to $recipient");
                return true;
            }
        }
        
        error_log("SMS sending failed: HTTP $httpCode, Response: $response");
        return false;
        
    } catch (Exception $e) {
        error_log("SMS sending error: " . $e->getMessage());
        return false;
    }
}

$input_data = file_get_contents("php://input");
$data = json_decode($input_data, true);

// Validate JSON
if (json_last_error() !== JSON_ERROR_NONE) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'Invalid JSON format.'
    ]);
    exit;
}

// Validate input - require either phone or email
if (empty($data['phone']) && empty($data['email'])) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'Phone number or email is required.'
    ]);
    exit;
}

$phone = !empty($data['phone']) ? preg_replace('/[^0-9]/', '', $data['phone']) : null;
$email = !empty($data['email']) ? strtolower(trim($data['email'])) : null;

// Validate email format if provided
if ($email && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'Invalid email format.'
    ]);
    exit;
}

// Check if user exists
$user_query = "";
$user_params = [];
$user_types = "";

if ($phone && $email) {
    // Both provided - check for either
    $user_query = "SELECT id, name, phone, email FROM users WHERE phone = ? OR email = ? LIMIT 1";
    $user_params = [$phone, $email];
    $user_types = "ss";
} elseif ($phone) {
    // Only phone provided
    $user_query = "SELECT id, name, phone, email FROM users WHERE phone = ? LIMIT 1";
    $user_params = [$phone];
    $user_types = "s";
} else {
    // Only email provided
    $user_query = "SELECT id, name, phone, email FROM users WHERE email = ? LIMIT 1";
    $user_params = [$email];
    $user_types = "s";
}

$stmt = $connection->prepare($user_query);
$stmt->bind_param($user_types, ...$user_params);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    http_response_code(404);
    echo json_encode([
        'code' => 404,
        'status' => 'error',
        'message' => 'User not found with provided phone or email.'
    ]);
    exit;
}

$user = $result->fetch_assoc();
$stmt->close();

// Generate 6-digit reset code
$reset_code = rand(100000, 999999);
$expires_at = date("Y-m-d H:i:s", strtotime("+15 minutes"));

// Insert into password_resets
$stmt = $connection->prepare("
    INSERT INTO password_resets (user_id, reset_code, expires_at, created_at)
    VALUES (?, ?, ?, NOW())
");

$stmt->bind_param("iss", $user['id'], $reset_code, $expires_at);
$stmt->execute();
$stmt->close();

// Send reset code via SMS if phone is available
$smsSent = false;
if ($user['phone']) {
    $smsMessage = "Kode yanyu yo guhindura ijambo banga: $reset_code\n\nIyi kode irarangira mu minota 15.";
    $smsSent = sendSMS($user['phone'], $smsMessage);
}

// Send email if email is available (fallback)
$emailSent = false;
if ($user['email']) {
    $subject = "Password Reset Code - Gemura";
    $message = "Your password reset code is: $reset_code\n\nThis code will expire in 15 minutes.\n\nIf you didn't request this, please ignore this message.";
    $headers = "From: noreply@gemura.rw";
    
    $emailSent = mail($user['email'], $subject, $message, $headers);
}

// Success response
http_response_code(200);
echo json_encode([
    'code' => 200,
    'status' => 'success',
    'message' => 'Reset code sent successfully.',
    'data' => [
        'user_id' => $user['id'],
        'sms_sent' => $smsSent,
        'email_sent' => $emailSent,
        'contact_info' => [
            'phone' => $user['phone'],
            'email' => $user['email']
        ]
    ]
]);
?>
