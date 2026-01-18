<?php
require_once("../configs/configs.php");
header('Content-Type: application/json');

// Create feed_posts table
$createPostsTable = "
CREATE TABLE IF NOT EXISTS `feed_posts` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `content` text DEFAULT NULL,
  `media_url` varchar(500) DEFAULT NULL,
  `hashtags` longtext DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `likes_count` int(11) DEFAULT 0,
  `shares_count` int(11) DEFAULT 0,
  `bookmarks_count` int(11) DEFAULT 0,
  `comments_count` int(11) DEFAULT 0,
  `status` varchar(20) DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_by` bigint(20) UNSIGNED DEFAULT NULL,
  `updated_by` bigint(20) UNSIGNED DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
";

// Create feed_comments table
$createCommentsTable = "
CREATE TABLE IF NOT EXISTS `feed_comments` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `post_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `content` text NOT NULL,
  `parent_comment_id` bigint(20) UNSIGNED DEFAULT NULL,
  `likes_count` int(11) DEFAULT 0,
  `status` varchar(20) DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_by` bigint(20) UNSIGNED DEFAULT NULL,
  `updated_by` bigint(20) UNSIGNED DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
";

// Create feed_interactions table
$createInteractionsTable = "
CREATE TABLE IF NOT EXISTS `feed_interactions` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `post_id` bigint(20) UNSIGNED DEFAULT NULL,
  `story_id` bigint(20) UNSIGNED DEFAULT NULL,
  `interaction_type` varchar(20) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
";

// Create user_bookmarks table
$createBookmarksTable = "
CREATE TABLE IF NOT EXISTS `user_bookmarks` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `post_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
";

// Create user_relationships table
$createRelationshipsTable = "
CREATE TABLE IF NOT EXISTS `user_relationships` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `follower_id` bigint(20) UNSIGNED NOT NULL,
  `following_id` bigint(20) UNSIGNED NOT NULL,
  `status` varchar(20) DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
";

$results = [];

// Execute table creation queries
$tables = [
    'feed_posts' => $createPostsTable,
    'feed_comments' => $createCommentsTable,
    'feed_interactions' => $createInteractionsTable,
    'user_bookmarks' => $createBookmarksTable,
    'user_relationships' => $createRelationshipsTable
];

foreach ($tables as $tableName => $query) {
    if (mysqli_query($connection, $query)) {
        $results[$tableName] = "Created successfully";
    } else {
        $results[$tableName] = "Error: " . mysqli_error($connection);
    }
}

echo json_encode([
    "code" => 200,
    "status" => "success",
    "message" => "Database tables setup completed.",
    "data" => $results
]);
?>
