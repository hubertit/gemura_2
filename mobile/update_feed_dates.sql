-- Update feed posts with random dates between 2024 and September 2025
-- This will make the posts appear to have been created at different times

UPDATE feed_posts 
SET created_at = DATE_ADD(
    '2024-01-01 00:00:00', 
    INTERVAL FLOOR(RAND() * DATEDIFF('2025-09-30 23:59:59', '2024-01-01 00:00:00')) DAY
) + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE + INTERVAL FLOOR(RAND() * 60) SECOND
WHERE status = 'active';

-- Optional: Also update the updated_at field to match
UPDATE feed_posts 
SET updated_at = created_at
WHERE status = 'active';

-- Verify the date range
SELECT 
    MIN(created_at) as earliest_post,
    MAX(created_at) as latest_post,
    COUNT(*) as total_posts
FROM feed_posts 
WHERE status = 'active';
