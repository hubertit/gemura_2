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
    SELECT u.id, u.name, u.total_points, u.available_points, u.referral_count, u.onboarded_count
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

// Get points breakdown by source
$pointsBreakdown = mysqli_query($connection, "
    SELECT 
        points_source,
        SUM(points_earned) as total_points,
        COUNT(*) as total_activities
    FROM user_points
    WHERE user_id = $user_id
    GROUP BY points_source
    ORDER BY total_points DESC
");

$breakdown = [];
while ($row = mysqli_fetch_assoc($pointsBreakdown)) {
    $breakdown[] = [
        "source" => $row['points_source'],
        "points" => intval($row['total_points']),
        "activities" => intval($row['total_activities'])
    ];
}

// Get recent points activities
$recentActivities = mysqli_query($connection, "
    SELECT 
        points_earned,
        points_source,
        description,
        created_at
    FROM user_points
    WHERE user_id = $user_id
    ORDER BY created_at DESC
    LIMIT 10
");

$activities = [];
while ($row = mysqli_fetch_assoc($recentActivities)) {
    $activities[] = [
        "points" => intval($row['points_earned']),
        "source" => $row['points_source'],
        "description" => $row['description'],
        "date" => $row['created_at']
    ];
}

// Get leaderboard position (optional)
$leaderboardPosition = mysqli_query($connection, "
    SELECT COUNT(*) + 1 as position
    FROM users 
    WHERE total_points > " . intval($user['total_points']) . " AND status = 'active'
");

$position = mysqli_fetch_assoc($leaderboardPosition);

echo json_encode([
    "code" => 200,
    "status" => "success",
    "message" => "Points balance retrieved successfully.",
    "data" => [
        "user_info" => [
            "name" => $user['name'],
            "total_points" => intval($user['total_points']),
            "available_points" => intval($user['available_points']),
            "referral_count" => intval($user['referral_count']),
            "onboarded_count" => intval($user['onboarded_count']),
            "leaderboard_position" => intval($position['position'])
        ],
        "points_breakdown" => $breakdown,
        "recent_activities" => $activities
    ]
]);
?>
