<?php
require_once("../configs/configs.php");
header('Content-Type: application/json');

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

if (empty($data['token'])) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'Token is required.'
    ]);
    exit;
}

$token = mysqli_real_escape_string($connection, trim($data['token']));

// Get logged in user
$userQuery = mysqli_query($connection, "
    SELECT u.id, u.name, u.referral_code, u.referral_count, u.total_points
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
$user_id = $user['id'];

// Generate referral code if user doesn't have one
if (empty($user['referral_code'])) {
    $referral_code = strtoupper(substr(md5($user_id . time()), 0, 8));
    
    // Ensure code is unique
    $codeCheck = mysqli_query($connection, "
        SELECT id FROM users WHERE referral_code = '$referral_code' LIMIT 1
    ");
    
    while (mysqli_num_rows($codeCheck) > 0) {
        $referral_code = strtoupper(substr(md5($user_id . time() . rand()), 0, 8));
        $codeCheck = mysqli_query($connection, "
            SELECT id FROM users WHERE referral_code = '$referral_code' LIMIT 1
        ");
    }
    
    // Update user with referral code
    $updateQuery = "
        UPDATE users 
        SET referral_code = '$referral_code' 
        WHERE id = $user_id
    ";
    
    if (!mysqli_query($connection, $updateQuery)) {
        http_response_code(500);
        echo json_encode([
            "code" => 500,
            "status" => "error",
            "message" => "Failed to generate referral code."
        ]);
        exit;
    }
} else {
    $referral_code = $user['referral_code'];
}

// Get referral statistics
$referralStats = mysqli_query($connection, "
    SELECT 
        COUNT(*) as total_referrals,
        COUNT(CASE WHEN ur.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN 1 END) as recent_referrals
    FROM user_referrals ur
    WHERE ur.referrer_id = $user_id
");

$stats = mysqli_fetch_assoc($referralStats);

echo json_encode([
    "code" => 200,
    "status" => "success",
    "message" => "Referral code retrieved successfully.",
    "data" => [
        "user_id" => $user_id,
        "user_name" => $user['name'],
        "referral_code" => $referral_code,
        "total_referrals" => intval($stats['total_referrals']),
        "recent_referrals" => intval($stats['recent_referrals']),
        "total_points" => intval($user['total_points']),
        "referral_url" => "https://app.gemura.rw/register?ref=" . $referral_code
    ]
]);
?>
