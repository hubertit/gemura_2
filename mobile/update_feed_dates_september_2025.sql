-- Update all feed posts to have random dates in September 2025
UPDATE feed_posts 
SET created_at = DATE_ADD(
    '2025-09-01 00:00:00', 
    INTERVAL FLOOR(RAND() * 30) DAY
) + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE + INTERVAL FLOOR(RAND() * 60) SECOND
WHERE status = 'active';

-- Also update the updated_at field to match
UPDATE feed_posts 
SET updated_at = created_at
WHERE status = 'active';

-- Verify the date range - should show all dates in September 2025
SELECT 
    MIN(created_at) as earliest_post,
    MAX(created_at) as latest_post,
    COUNT(*) as total_posts,
    DATE_FORMAT(MIN(created_at), '%Y-%m') as earliest_month,
    DATE_FORMAT(MAX(created_at), '%Y-%m') as latest_month
FROM feed_posts 
WHERE status = 'active';
