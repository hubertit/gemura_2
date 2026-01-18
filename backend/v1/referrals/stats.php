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
    SELECT u.id, u.name, u.referral_code, u.referral_count, u.total_points, u.available_points
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

// Get referral statistics
$referralStats = mysqli_query($connection, "
    SELECT 
        COUNT(*) as total_referrals,
        COUNT(CASE WHEN ur.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 1 END) as recent_week,
        COUNT(CASE WHEN ur.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN 1 END) as recent_month,
        COUNT(CASE WHEN ur.created_at >= DATE_SUB(NOW(), INTERVAL 90 DAY) THEN 1 END) as recent_quarter
    FROM user_referrals ur
    WHERE ur.referrer_id = $user_id
");

if (!$referralStats) {
    http_response_code(500);
    echo json_encode([
        "code" => 500,
        "status" => "error",
        "message" => "Database error: " . mysqli_error($connection)
    ]);
    exit;
}

$stats = mysqli_fetch_assoc($referralStats);

// Get recent referrals
$recentReferrals = mysqli_query($connection, "
    SELECT 
        u.name as referred_name,
        u.phone_number,
        ur.created_at,
        ur.points_awarded
    FROM user_referrals ur
    JOIN users u ON ur.referred_id = u.id
    WHERE ur.referrer_id = $user_id
    ORDER BY ur.created_at DESC
    LIMIT 10
");

$recent_list = [];
if ($recentReferrals) {
    while ($row = mysqli_fetch_assoc($recentReferrals)) {
        $recent_list[] = [
            "name" => $row['referred_name'],
            "phone" => $row['phone_number'],
            "joined_at" => $row['created_at'],
            "points_earned" => intval($row['points_awarded'])
        ];
    }
}

// Get points history
$pointsHistory = mysqli_query($connection, "
    SELECT 
        points_earned,
        points_source,
        description,
        created_at
    FROM user_points
    WHERE user_id = $user_id
    ORDER BY created_at DESC
    LIMIT 20
");

$points_list = [];
if ($pointsHistory) {
    while ($row = mysqli_fetch_assoc($pointsHistory)) {
        $points_list[] = [
            "points" => intval($row['points_earned']),
            "source" => $row['points_source'],
            "description" => $row['description'],
            "earned_at" => $row['created_at']
        ];
    }
}

echo json_encode([
    "code" => 200,
    "status" => "success",
    "message" => "Referral statistics retrieved successfully.",
    "data" => [
        "user_info" => [
            "name" => $user['name'],
            "referral_code" => $user['referral_code'],
            "total_points" => intval($user['total_points']),
            "available_points" => intval($user['available_points'])
        ],
        "statistics" => [
            "total_referrals" => intval($stats['total_referrals']),
            "recent_week" => intval($stats['recent_week']),
            "recent_month" => intval($stats['recent_month']),
            "recent_quarter" => intval($stats['recent_quarter'])
        ],
        "recent_referrals" => $recent_list,
        "points_history" => $points_list
    ]
]);
?>
