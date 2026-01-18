<?php
require_once("../configs/configs.php");
header('Content-Type: application/json');

$input_data = file_get_contents("php://input");
$data = json_decode($input_data, true);

// Validate input
if (empty($data['token']) || empty($data['user_id'])) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Token and user_id are required."
    ]);
    exit;
}

$token = mysqli_real_escape_string($connection, $data['token']);
$target_user_id = intval($data['user_id']);

// Get current user
$userQuery = mysqli_query($connection, "
    SELECT u.id FROM users u
    WHERE u.token = '$token' AND u.status = 'active' LIMIT 1
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
$current_user_id = $user['id'];

// Check if trying to follow self
if ($current_user_id == $target_user_id) {
    http_response_code(400);
    echo json_encode([
        "code" => 400,
        "status" => "error",
        "message" => "Cannot follow yourself."
    ]);
    exit;
}

// Check if target user exists
$targetUserQuery = mysqli_query($connection, "
    SELECT id FROM users 
    WHERE id = $target_user_id AND status = 'active'
    LIMIT 1
");

if (!$targetUserQuery || mysqli_num_rows($targetUserQuery) === 0) {
    http_response_code(404);
    echo json_encode([
        "code" => 404,
        "status" => "error",
        "message" => "User not found."
    ]);
    exit;
}

// Check if already following
$followQuery = mysqli_query($connection, "
    SELECT id FROM user_relationships 
    WHERE follower_id = $current_user_id AND following_id = $target_user_id
    LIMIT 1
");

if (mysqli_num_rows($followQuery) > 0) {
    // Unfollow user
    $delete = mysqli_query($connection, "
        DELETE FROM user_relationships 
        WHERE follower_id = $current_user_id AND following_id = $target_user_id
    ");
    
    if ($delete) {
        echo json_encode([
            "code" => 200,
            "status" => "success",
            "message" => "User unfollowed successfully.",
            "data" => [
                "user_id" => $target_user_id,
                "is_following" => false
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            "code" => 500,
            "status" => "error",
            "message" => "Failed to unfollow user."
        ]);
    }
} else {
    // Follow user
    $insert = mysqli_query($connection, "
        INSERT INTO user_relationships (follower_id, following_id) 
        VALUES ($current_user_id, $target_user_id)
    ");
    
    if ($insert) {
        echo json_encode([
            "code" => 200,
            "status" => "success",
            "message" => "User followed successfully.",
            "data" => [
                "user_id" => $target_user_id,
                "is_following" => true
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            "code" => 500,
            "status" => "error",
            "message" => "Failed to follow user."
        ]);
    }
}
?>
