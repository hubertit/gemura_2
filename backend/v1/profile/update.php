<?php
require_once("../configs/configs.php");
header('Content-Type: application/json');

// Debug marker
error_log("=== PROFILE UPDATE DEBUG START ===");

$raw = file_get_contents("php://input");
$data = json_decode($raw, true);

if (json_last_error() !== JSON_ERROR_NONE) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Invalid JSON format."
    ]);
    exit;
}

// Validate required
if (empty($data['token'])) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Missing token."
    ]);
    exit;
}

$token        = mysqli_real_escape_string($connection, trim($data['token']));
$name         = isset($data['name']) ? mysqli_real_escape_string($connection, trim($data['name'])) : null;
$email        = isset($data['email']) && $data['email'] !== '' ? mysqli_real_escape_string($connection, trim($data['email'])) : null;
$phoneRaw     = isset($data['phone']) ? preg_replace('/[^0-9]/', '', $data['phone']) : null; // keep digits only
$phone        = $phoneRaw !== null ? mysqli_real_escape_string($connection, $phoneRaw) : null;
$nid          = isset($data['nid']) && $data['nid'] !== '' ? mysqli_real_escape_string($connection, trim($data['nid'])) : null;
$address      = isset($data['address']) && $data['address'] !== '' ? mysqli_real_escape_string($connection, trim($data['address'])) : null;
$requestedAccountId = isset($data['account_id']) ? intval($data['account_id']) : null;

// NEW: KYC Fields
$province     = isset($data['province']) && $data['province'] !== '' ? mysqli_real_escape_string($connection, trim($data['province'])) : null;
$district     = isset($data['district']) && $data['district'] !== '' ? mysqli_real_escape_string($connection, trim($data['district'])) : null;
$sector       = isset($data['sector']) && $data['sector'] !== '' ? mysqli_real_escape_string($connection, trim($data['sector'])) : null;
$cell         = isset($data['cell']) && $data['cell'] !== '' ? mysqli_real_escape_string($connection, trim($data['cell'])) : null;
$village      = isset($data['village']) && $data['village'] !== '' ? mysqli_real_escape_string($connection, trim($data['village'])) : null;
$idNumber     = isset($data['id_number']) && $data['id_number'] !== '' ? mysqli_real_escape_string($connection, trim($data['id_number'])) : null;
$idFrontPhotoUrl = isset($data['id_front_photo_url']) && $data['id_front_photo_url'] !== '' ? mysqli_real_escape_string($connection, trim($data['id_front_photo_url'])) : null;
$idBackPhotoUrl  = isset($data['id_back_photo_url']) && $data['id_back_photo_url'] !== '' ? mysqli_real_escape_string($connection, trim($data['id_back_photo_url'])) : null;
$selfiePhotoUrl  = isset($data['selfie_photo_url']) && $data['selfie_photo_url'] !== '' ? mysqli_real_escape_string($connection, trim($data['selfie_photo_url'])) : null;

// Minimal validation
if ($name === null || $name === '' || $phone === null || $phone === '') {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Name and phone are required."
    ]);
    exit;
}

// Resolve logged-in user (match other APIs: users.token)
$userQuery = mysqli_query($connection, "
    SELECT u.id, u.default_account_id
    FROM users u
    WHERE u.token = '$token' AND u.status = 'active'
    LIMIT 1
");

if (!$userQuery || mysqli_num_rows($userQuery) === 0) {
    http_response_code(403);
    echo json_encode([
        "code" => 403,
        "status" => "error",
        "message" => "Unauthorized. Invalid token."
    ]);
    exit;
}

$user = mysqli_fetch_assoc($userQuery);
$userId = intval($user['id']);
$targetAccountId = $requestedAccountId ?: intval($user['default_account_id'] ?? 0);
if ($targetAccountId <= 0) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "No valid account found to update."
    ]);
    exit;
}

// Build dynamic user update set
$setParts = array();
$setParts[] = "name='$name'";
$setParts[] = "phone='$phone'";
if ($email !== null)   $setParts[] = "email='$email'";
if ($nid !== null)     $setParts[] = "nid='$nid'";
if ($address !== null) $setParts[] = "address='$address'";

// NEW: Add KYC fields to update
if ($province !== null) $setParts[] = "province='$province'";
if ($district !== null) $setParts[] = "district='$district'";
if ($sector !== null) $setParts[] = "sector='$sector'";
if ($cell !== null) $setParts[] = "cell='$cell'";
if ($village !== null) $setParts[] = "village='$village'";
if ($idNumber !== null) $setParts[] = "id_number='$idNumber'";
if ($idFrontPhotoUrl !== null) $setParts[] = "id_front_photo_url='$idFrontPhotoUrl'";
if ($idBackPhotoUrl !== null) $setParts[] = "id_back_photo_url='$idBackPhotoUrl'";
if ($selfiePhotoUrl !== null) $setParts[] = "selfie_photo_url='$selfiePhotoUrl'";

// NEW: Update KYC status to pending if photos are uploaded
if ($idFrontPhotoUrl !== null || $idBackPhotoUrl !== null || $selfiePhotoUrl !== null) {
    $setParts[] = "kyc_status='pending'";
}

$setSql = implode(", ", $setParts);

// Update users
$userUpdate = mysqli_query($connection, "
    UPDATE users SET $setSql, updated_at = NOW(), updated_by = $userId WHERE id = $userId
");
if (!$userUpdate) {
    http_response_code(500);
    echo json_encode([
        "code" => 500,
        "status" => "error",
        "message" => "Failed to update user: " . mysqli_error($connection)
    ]);
    exit;
}

// Note: Account name updates have been removed from profile updates
// Account name should be updated through dedicated account management endpoints

// Get updated user data with same structure as get profile
$userQuery = mysqli_query($connection, "
    SELECT 
        u.id AS user_id,
        u.name AS user_name,
        u.email,
        u.phone,
        u.default_account_id,
        u.status,
        u.token,
        u.account_type
    FROM users u
    WHERE u.id = $userId
    LIMIT 1
");

if (!$userQuery || mysqli_num_rows($userQuery) === 0) {
    http_response_code(500);
    echo json_encode([
        "code" => 500,
        "status" => "error",
        "message" => "Failed to retrieve updated user data."
    ]);
    exit;
}

$user = mysqli_fetch_assoc($userQuery);
$user_id = $user['user_id'];

// Get all accounts user has access to (same as get profile)
$accountsQuery = mysqli_query($connection, "
    SELECT 
        a.id AS account_id,
        a.code AS account_code,
        a.name AS account_name,
        a.type AS account_type,
        a.status AS account_status,
        a.created_at AS account_created_at,
        ua.role,
        ua.permissions,
        ua.status AS user_account_status,
        ua.created_at AS access_granted_at,
        CASE WHEN u.default_account_id = a.id THEN 1 ELSE 0 END as is_default
    FROM user_accounts ua
    JOIN accounts a ON a.id = ua.account_id
    JOIN users u ON u.id = ua.user_id
    WHERE ua.user_id = $user_id
      AND ua.status = 'active'
      AND a.status != 'deleted'
    ORDER BY ua.created_at DESC
");

$accounts = [];
$defaultAccount = null;

if ($accountsQuery && mysqli_num_rows($accountsQuery) > 0) {
    while ($row = mysqli_fetch_assoc($accountsQuery)) {
        $account = [
            "account_id" => intval($row['account_id']),
            "account_code" => $row['account_code'],
            "account_name" => $row['account_name'],
            "account_type" => $row['account_type'],
            "account_status" => $row['account_status'],
            "account_created_at" => $row['account_created_at'],
            "role" => $row['role'],
            "permissions" => $row['permissions'] ? json_decode($row['permissions'], true) : null,
            "user_account_status" => $row['user_account_status'],
            "access_granted_at" => $row['access_granted_at'],
            "is_default" => (bool)$row['is_default']
        ];
        
        $accounts[] = $account;
        
        // Set default account
        if ($row['is_default']) {
            $defaultAccount = [
                'id' => intval($row['account_id']),
                'code' => $row['account_code'],
                'name' => $row['account_name'],
                'type' => $row['account_type']
            ];
        }
    }
}

// Calculate profile completion percentage (same as get profile)
$profileFields = [
    'user_name', 'email', 'phone', 'province', 'district', 'sector', 
    'cell', 'village', 'id_number', 'id_front', 'id_back', 'selfie'
];

$completedFields = 0;
foreach ($profileFields as $field) {
    if (!empty($user[$field])) {
        $completedFields++;
    }
}

$profileCompletion = round(($completedFields / count($profileFields)) * 100);

// Return same structure as get profile
echo json_encode([
    "code" => 200,
    "status" => "success",
    "message" => "Profile updated successfully",
    "data" => [
        "user" => [
            "id" => intval($user['user_id']),
            "name" => $user['user_name'],
            "email" => $user['email'],
            "phone" => $user['phone'],
            "account_type" => $user['account_type'] ?? 'mcc',
            "status" => $user['status'],
            "token" => $user['token']
        ],
        "account" => $defaultAccount,
        "accounts" => $accounts,
        "total_accounts" => count($accounts),
        "profile_completion" => $profileCompletion
    ]
]);

error_log("=== PROFILE UPDATE DEBUG END ===");
?>


