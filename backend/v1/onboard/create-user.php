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

if (empty($data['token']) || empty($data['name']) || empty($data['phone_number'])) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'Token, name, and phone_number are required.'
    ]);
    exit;
}

$token = mysqli_real_escape_string($connection, trim($data['token']));
$name = mysqli_real_escape_string($connection, trim($data['name']));
$phone_number = mysqli_real_escape_string($connection, trim($data['phone_number']));
$email = !empty($data['email']) ? mysqli_real_escape_string($connection, trim($data['email'])) : null;
$location = !empty($data['location']) ? mysqli_real_escape_string($connection, trim($data['location'])) : null;

// Get logged in user (the one doing the onboarding)
$userQuery = mysqli_query($connection, "
    SELECT u.id, u.name
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

$onboarder = mysqli_fetch_assoc($userQuery);
$onboarder_id = $onboarder['id'];

// Check if phone number already exists
$phoneCheck = mysqli_query($connection, "
    SELECT id FROM users WHERE phone = '$phone_number' LIMIT 1
");

if (mysqli_num_rows($phoneCheck) > 0) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Phone number already exists."
    ]);
    exit;
}

// Hash password
$password_hash = password_hash($data['password'], PASSWORD_DEFAULT);

// Generate unique user ID and token
$new_user_id = rand(100000, 999999); // Smaller ID for int(11) compatibility
$new_token = md5($new_user_id . time() . rand());

// Get current time in Africa/Kigali timezone
$kigali_time = (new DateTime('now', new DateTimeZone('Africa/Kigali')))->format('Y-m-d H:i:s');

// Start transaction
mysqli_begin_transaction($connection);

try {
    // Create new user
    $insertUser = mysqli_query($connection, "
        INSERT INTO users (
            id, name, phone, email, address, password_hash,
            onboarded_by, registration_type, status, 
            created_at, updated_at, token
        ) VALUES (
            $new_user_id,
            '$name',
            '$phone_number',
            " . ($email ? "'$email'" : "NULL") . ",
            " . ($location ? "'$location'" : "NULL") . ",
            '$password_hash',
            $onboarder_id,
            'onboarded',
            'active',
            '$kigali_time',
            '$kigali_time',
            '$new_token'
        )
    ");
    
    if (!$insertUser) {
        throw new Exception("Failed to create user: " . mysqli_error($connection));
    }
    
    // Create onboarding record
    $insertOnboarding = mysqli_query($connection, "
        INSERT INTO user_onboardings (onboarder_id, onboarded_id, points_awarded, created_at)
        VALUES ($onboarder_id, $new_user_id, 1, '$kigali_time')
    ");
    
    if (!$insertOnboarding) {
        throw new Exception("Failed to create onboarding record: " . mysqli_error($connection));
    }
    
    // Award points to onboarder
    $awardPoints = mysqli_query($connection, "
        INSERT INTO user_points (user_id, points_earned, points_source, description, created_at)
        VALUES ($onboarder_id, 1, 'onboarding', 'Onboarded user: $name', '$kigali_time')
    ");
    
    if (!$awardPoints) {
        throw new Exception("Failed to award points");
    }
    
    // Update onboarder's stats
    $updateOnboarderStats = mysqli_query($connection, "
        UPDATE users 
        SET onboarded_count = onboarded_count + 1, 
            total_points = total_points + 1,
            available_points = available_points + 1
        WHERE id = $onboarder_id
    ");
    
    if (!$updateOnboarderStats) {
        throw new Exception("Failed to update onboarder stats");
    }
    
    // Commit transaction
    mysqli_commit($connection);
    
    echo json_encode([
        "code" => 201,
        "status" => "success",
        "message" => "User onboarded successfully.",
        "data" => [
            "onboarded_user" => [
                "id" => $new_user_id,
                "name" => $name,
                "phone_number" => $phone_number,
                "email" => $email,
                "location" => $location,
                "token" => $new_token,
                "created_at" => $kigali_time
            ],
            "onboarder" => [
                "name" => $onboarder['name'],
                "points_earned" => 1
            ],
            "onboarded_at" => $kigali_time
        ]
    ]);
    
} catch (Exception $e) {
    // Rollback transaction
    mysqli_rollback($connection);
    
    http_response_code(500);
    echo json_encode([
        "code" => 500,
        "status" => "error",
        "message" => "Failed to onboard user: " . $e->getMessage()
    ]);
}
?>
