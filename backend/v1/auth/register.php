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

// Required fields
$required = ['name', 'phone', 'password', 'account_name', 'account_type'];
foreach ($required as $field) {
    if (empty($data[$field])) {
        http_response_code(400);
        echo json_encode([
            'code' => 400,
            'status' => 'error',
            'message' => "Missing required field: $field"
        ]);
        exit;
    }
}

// Sanitize and prepare variables
$name = trim($data['name']);
$account_name = trim($data['account_name']);
$email = !empty($data['email']) ? strtolower(trim($data['email'])) : null;
$phone = preg_replace('/[^0-9]/', '', $data['phone']);
$password_hash = password_hash(trim($data['password']), PASSWORD_BCRYPT);
$token = bin2hex(random_bytes(32));

$user_code = 'U_' . strtoupper(bin2hex(random_bytes(3)));
$account_code = 'A_' . strtoupper(bin2hex(random_bytes(3)));
$wallet_code = 'W_' . strtoupper(bin2hex(random_bytes(3)));

$role = isset($data['role']) && in_array($data['role'], ['owner', 'admin', 'collector', 'supplier', 'customer'])
    ? $data['role'] : 'customer';

$account_type = isset($data['account_type']) && in_array($data['account_type'], ['mcc', 'agent', 'collector', 'veterinarian', 'supplier', 'customer', 'farmer', 'owner'])
    ? $data['account_type'] : 'mcc';

$nid = !empty($data['nid']) ? trim($data['nid']) : null;

// Set default permissions for dairy business
$default_permissions = [
    'can_collect' => true,
    'can_add_supplier' => true,
    'can_view_reports' => true
];

$permissions = isset($data['permissions']) ? json_encode($data['permissions']) : json_encode($default_permissions);

// Wallet fields
$wallet_type = isset($data['wallet']['type']) && in_array($data['wallet']['type'], ['saving', 'regular'])
    ? $data['wallet']['type'] : 'regular';
$is_joint = isset($data['wallet']['is_joint']) && $data['wallet']['is_joint'] ? 1 : 0;

// Check existing phone or NID (if provided)
if ($nid) {
    $stmt = $connection->prepare("
        SELECT id FROM users 
        WHERE phone = ? OR nid = ? LIMIT 1
    ");
    $stmt->bind_param("ss", $phone, $nid);
} else {
    $stmt = $connection->prepare("
        SELECT id FROM users 
        WHERE phone = ? LIMIT 1
    ");
    $stmt->bind_param("s", $phone);
}
$stmt->execute();
$stmt->store_result();
if ($stmt->num_rows > 0) {
    echo json_encode([
        'code' => 409,
        'status' => 'error',
        'message' => 'Phone number already registered.'
    ]);
    exit;
}
$stmt->close();

$connection->begin_transaction();

try {
    // Create user
    $stmt = $connection->prepare("
        INSERT INTO users (code, name, email, phone, nid, password_hash, token, account_type, status, created_by)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'active', ?)
    ");
    if (!$stmt) {
        throw new Exception("Failed to prepare user statement: " . $connection->error);
    }
    $created_by = null;
    $stmt->bind_param("ssssssssi", $user_code, $name, $email, $phone, $nid, $password_hash, $token, $account_type, $created_by);
    $stmt->execute();
    $user_id = $stmt->insert_id;
    $stmt->close();

    // Create tenant account
    $stmt = $connection->prepare("
        INSERT INTO accounts (code, name, type, status, created_by)
        VALUES (?, ?, 'tenant', 'active', ?)
    ");
    if (!$stmt) {
        throw new Exception("Failed to prepare account statement: " . $connection->error);
    }
    $stmt->bind_param("ssi", $account_code, $account_name, $user_id);
    $stmt->execute();
    $account_id = $stmt->insert_id;
    $stmt->close();

    // Link user to account with role & permissions
    $stmt = $connection->prepare("
        INSERT INTO user_accounts (user_id, account_id, role, permissions, status, created_by)
        VALUES (?, ?, ?, ?, 'active', ?)
    ");
    if (!$stmt) {
        throw new Exception("Failed to prepare user_accounts statement: " . $connection->error);
    }
    $stmt->bind_param("iissi", $user_id, $account_id, $role, $permissions, $user_id);
    $stmt->execute();
    $stmt->close();

    // Set default account for the user (if the column exists)
    $stmt = $connection->prepare("UPDATE users SET default_account_id = ? WHERE id = ?");
    if ($stmt) {
        $stmt->bind_param("ii", $account_id, $user_id);
        $stmt->execute();
        $stmt->close();
    }

    // Create wallet as default
    $stmt = $connection->prepare("
        INSERT INTO wallets (account_id, code, type, is_joint, balance, currency, status, is_default, created_by)
        VALUES (?, ?, ?, ?, 0.00, 'RWF', 'active', 1, ?)
    ");
    if (!$stmt) {
        throw new Exception("Failed to prepare wallet statement: " . $connection->error);
    }
    $stmt->bind_param("issii", $account_id, $wallet_code, $wallet_type, $is_joint, $user_id);
    $stmt->execute();
    $stmt->close();

    $connection->commit();

    // Send welcome SMS (Kinyarwanda)
    $welcomeMessage = "Murakaza neza kuri Gemura,\n\nMukoreshe numero ya telefone n'ijambo banga mwijire muri konti yanyu\n\nNB: Ijambobanga ni ibanga ryanyu gusa";
    $smsSent = sendSMS($phone, $welcomeMessage);

    echo json_encode([
        'code' => 201,
        'status' => 'success',
        'message' => 'Registration successful.',
        'data' => [
            'user' => [
                'code' => $user_code,
                'name' => $name,
                'email' => $email,
                'phone' => $phone,
                'nid' => $nid,
                'account_type' => $account_type,
                'status' => 'active',
                'token' => $token
            ],
            'account' => [
                'code' => $account_code,
                'name' => $account_name,
                'type' => 'tenant',
                'status' => 'active'
            ],
            'wallet' => [
                'code' => $wallet_code,
                'type' => $wallet_type,
                'is_joint' => (bool)$is_joint,
                'is_default' => true,
                'balance' => 0.00,
                'currency' => 'RWF',
                'status' => 'active'
            ],
            'sms_sent' => $smsSent
        ]
    ]);
} catch (Exception $e) {
    $connection->rollback();
    http_response_code(500);
    echo json_encode([
        'code' => 500,
        'status' => 'error',
        'message' => 'Failed to register user.',
        'error' => $e->getMessage()
    ]);
}
?>
