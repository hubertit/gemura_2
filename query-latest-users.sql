-- Query to get the latest 15 users from production database
-- Run this on the server: docker exec -i devslab-postgres psql -U devslab_admin -d gemura_db

SELECT 
    id,
    name,
    email,
    phone,
    account_type,
    status,
    created_at
FROM users 
ORDER BY created_at DESC 
LIMIT 15;

-- Alternative: Get more details including account information
SELECT 
    u.id,
    u.name,
    u.email,
    u.phone,
    u.account_type,
    u.status,
    u.created_at,
    COUNT(ua.id) as account_count
FROM users u
LEFT JOIN user_accounts ua ON ua.user_id = u.id
GROUP BY u.id, u.name, u.email, u.phone, u.account_type, u.status, u.created_at
ORDER BY u.created_at DESC 
LIMIT 15;
