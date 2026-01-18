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

// Validate input fields
if (
    empty($data['user_id']) ||
    empty($data['reset_code']) ||
    empty($data['new_password'])
) {
    http_response_code(400);
    echo json_encode([
        'code' => 400,
        'status' => 'error',
        'message' => 'User ID, reset code, and new password are required.'
    ]);
    exit;
}

$user_id = intval($data['user_id']);
$reset_code = trim($data['reset_code']);
$new_password = password_hash(trim($data['new_password']), PASSWORD_BCRYPT);

// Check reset code validity
$stmt = $connection->prepare("
    SELECT * FROM password_resets 
    WHERE user_id = ? 
      AND reset_code = ? 
      AND used = 0 
      AND expires_at >= NOW()
    LIMIT 1
");

$stmt->bind_param("is", $user_id, $reset_code);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    http_response_code(401);
    echo json_encode([
        'code' => 401,
        'status' => 'error',
        'message' => 'Invalid or expired reset code.'
    ]);
    exit;
}

$reset_record = $result->fetch_assoc();
$stmt->close();

// Update password
$stmt = $connection->prepare("
    UPDATE users SET password_hash = ? WHERE id = ?
");

$stmt->bind_param("si", $new_password, $user_id);
$password_updated = $stmt->execute();
$stmt->close();

if (!$password_updated) {
    http_response_code(500);
    echo json_encode([
        'code' => 500,
        'status' => 'error',
        'message' => 'Failed to update password.'
    ]);
    exit;
}

// Mark code as used
$stmt = $connection->prepare("
    UPDATE password_resets SET used = 1, used_at = NOW() 
    WHERE user_id = ? AND reset_code = ?
");

$stmt->bind_param("is", $user_id, $reset_code);
$stmt->execute();
$stmt->close();

// Success response
http_response_code(200);
echo json_encode([
    'code' => 200,
    'status' => 'success',
    'message' => 'Password has been reset successfully.'
]);
?>
