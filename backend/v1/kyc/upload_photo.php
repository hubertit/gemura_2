<?php
// /Applications/AMPPS/www/gemura2/api/v2/kyc/upload_photo.php

require_once("../configs/configs.php");

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Allow multipart form
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['code' => 405, 'status' => 'error', 'message' => 'Method not allowed.']);
    exit;
}

// Required fields
$required = ['token', 'photo_type'];
foreach ($required as $key) {
    if (empty($_POST[$key])) {
        http_response_code(400);
        echo json_encode(['code' => 400, 'status' => 'error', 'message' => "Missing field: $key"]);
        exit;
    }
}

// Extract input values
$token = mysqli_real_escape_string($connection, $_POST['token']);
$photo_type = mysqli_real_escape_string($connection, $_POST['photo_type']);

// Validate photo type
$allowed_photo_types = ['id_front', 'id_back', 'selfie'];
if (!in_array($photo_type, $allowed_photo_types)) {
    http_response_code(400);
    echo json_encode(['code' => 400, 'status' => 'error', 'message' => 'Invalid photo type. Allowed types: ' . implode(', ', $allowed_photo_types)]);
    exit;
}

// Validate token and get user
$user_q = mysqli_query($connection, "SELECT id, code FROM users WHERE token = '$token' AND status = 'active' LIMIT 1");
if (!$user_q || mysqli_num_rows($user_q) === 0) {
    http_response_code(401);
    echo json_encode(['code' => 401, 'status' => 'error', 'message' => 'Invalid or expired token.']);
    exit;
}
$user = mysqli_fetch_assoc($user_q);
$user_id = $user['id'];
$user_code = $user['code'];

// Upload image to Cloudinary
$img_url = null;
if (!empty($_FILES['photo']['tmp_name'])) {
    $cloudinary_url = "https://api.cloudinary.com/v1_1/dhwqnur8s/image/upload";
    $upload_preset = "expo_rwanda";

    $temp_file = $_FILES['photo']['tmp_name'];
    $cfile = curl_file_create($temp_file, $_FILES['photo']['type'], $_FILES['photo']['name']);

    $post = [
        'file' => $cfile,
        'upload_preset' => $upload_preset,
        'folder' => 'GEMURA/kyc'
    ];

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $cloudinary_url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $post);

    $response = curl_exec($ch);
    curl_close($ch);

    $cloudinary_result = json_decode($response, true);
    if (isset($cloudinary_result['secure_url'])) {
        $img_url = $cloudinary_result['secure_url'];
    } else {
        http_response_code(500);
        echo json_encode(['code' => 500, 'status' => 'error', 'message' => 'Image upload failed.']);
        exit;
    }
} else {
    http_response_code(400);
    echo json_encode(['code' => 400, 'status' => 'error', 'message' => 'No photo uploaded.']);
    exit;
}

// Update user's KYC photo URL in database
$photo_url_field = $photo_type . '_photo_url';
$update_query = mysqli_query($connection, "
    UPDATE users 
    SET $photo_url_field = '$img_url',
        kyc_status = 'pending',
        updated_at = NOW(),
        updated_by = $user_id
    WHERE id = $user_id
");

if (!$update_query) {
    http_response_code(500);
    echo json_encode(['code' => 500, 'status' => 'error', 'message' => 'Failed to update user record: ' . mysqli_error($connection)]);
    exit;
}

// Return success response
echo json_encode([
    'code' => 200,
    'status' => 'success',
    'message' => 'Photo uploaded successfully.',
    'data' => [
        'photo_url' => $img_url,
        'photo_type' => $photo_type,
        'user_id' => $user_id,
        'kyc_status' => 'pending'
    ]
]);
?>
