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

if (empty($data['token']) || empty($data['referral_code'])) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'Token and referral_code are required.'
    ]);
    exit;
}

$token = mysqli_real_escape_string($connection, trim($data['token']));
$referral_code = mysqli_real_escape_string($connection, trim($data['referral_code']));

// Get logged in user (the one being referred)
$userQuery = mysqli_query($connection, "
    SELECT u.id, u.name, u.referred_by
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

// Check if user already has a referrer
if (!empty($user['referred_by'])) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "User already has a referrer."
    ]);
    exit;
}

// Find the referrer by code
$referrerQuery = mysqli_query($connection, "
    SELECT u.id, u.name, u.referral_code
    FROM users u
    WHERE u.referral_code = '$referral_code' AND u.status = 'active'
    LIMIT 1
");

if (!$referrerQuery || mysqli_num_rows($referrerQuery) === 0) {
    http_response_code(404);
    echo json_encode([
        "code" => 404,
        "status" => "error",
        "message" => "Invalid referral code."
    ]);
    exit;
}

$referrer = mysqli_fetch_assoc($referrerQuery);
$referrer_id = $referrer['id'];

// Prevent self-referral
if ($referrer_id == $user_id) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Cannot refer yourself."
    ]);
    exit;
}

// Check if referral relationship already exists
$existingReferral = mysqli_query($connection, "
    SELECT id FROM user_referrals 
    WHERE referrer_id = $referrer_id AND referred_id = $user_id
    LIMIT 1
");

if (mysqli_num_rows($existingReferral) > 0) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Referral relationship already exists."
    ]);
    exit;
}

// Get current time in Africa/Kigali timezone
$kigali_time = (new DateTime('now', new DateTimeZone('Africa/Kigali')))->format('Y-m-d H:i:s');

// Start transaction
mysqli_begin_transaction($connection);

try {
    // Update user's referred_by field
    $updateUser = mysqli_query($connection, "
        UPDATE users 
        SET referred_by = $referrer_id, registration_type = 'referred'
        WHERE id = $user_id
    ");
    
    if (!$updateUser) {
        throw new Exception("Failed to update user referral");
    }
    
    // Create referral record
    $insertReferral = mysqli_query($connection, "
        INSERT INTO user_referrals (referrer_id, referred_id, referral_code, points_awarded, created_at)
        VALUES ($referrer_id, $user_id, '$referral_code', 1, '$kigali_time')
    ");
    
    if (!$insertReferral) {
        throw new Exception("Failed to create referral record");
    }
    
    // Award points to referrer
    $awardPoints = mysqli_query($connection, "
        INSERT INTO user_points (user_id, points_earned, points_source, description, created_at)
        VALUES ($referrer_id, 1, 'referral', 'Referred user: " . mysqli_real_escape_string($connection, $user['name']) . "', '$kigali_time')
    ");
    
    if (!$awardPoints) {
        throw new Exception("Failed to award points");
    }
    
    // Update referrer's stats
    $updateReferrerStats = mysqli_query($connection, "
        UPDATE users 
        SET referral_count = referral_count + 1, 
            total_points = total_points + 1,
            available_points = available_points + 1
        WHERE id = $referrer_id
    ");
    
    if (!$updateReferrerStats) {
        throw new Exception("Failed to update referrer stats");
    }
    
    // Commit transaction
    mysqli_commit($connection);
    
    echo json_encode([
        "code" => 200,
        "status" => "success",
        "message" => "Referral code applied successfully.",
        "data" => [
            "referrer_name" => $referrer['name'],
            "referral_code" => $referral_code,
            "points_awarded" => 1,
            "applied_at" => $kigali_time
        ]
    ]);
    
} catch (Exception $e) {
    // Rollback transaction
    mysqli_rollback($connection);
    
    http_response_code(500);
    echo json_encode([
        "code" => 500,
        "status" => "error",
        "message" => "Failed to apply referral code: " . $e->getMessage()
    ]);
}
?>
