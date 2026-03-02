-- Find users by phone (Rwanda: 250...) and list their accounts
\echo '=== Users 250782184608 and 250788260684 ==='
SELECT u.id AS user_id, u.phone, u.email, u.name, u.status, u.default_account_id
FROM users u
WHERE u.phone IN ('250782184608', '250788260684', '0782184608', '0788260684')
   OR u.phone LIKE '%782184608' OR u.phone LIKE '%788260684';

\echo ''
\echo '=== UserAccounts for those users ==='
SELECT ua.id, ua.user_id, ua.account_id, ua.role, ua.status, a.code AS account_code, a.name AS account_name
FROM user_accounts ua
JOIN accounts a ON a.id = ua.account_id
WHERE ua.user_id IN (
  SELECT id FROM users WHERE phone IN ('250782184608', '250788260684', '0782184608', '0788260684')
     OR phone LIKE '%782184608' OR phone LIKE '%788260684'
)
AND ua.status = 'active'
ORDER BY ua.user_id, ua.account_id;

\echo ''
\echo '=== User 250788606765 (to grant admin) ==='
SELECT id AS user_id, phone, email, name, status, default_account_id
FROM users
WHERE phone IN ('250788606765', '0788606765') OR phone LIKE '%788606765';

\echo ''
\echo '=== Current UserAccounts for 250788606765 ==='
SELECT ua.id, ua.user_id, ua.account_id, ua.role, ua.status, a.code, a.name
FROM user_accounts ua
JOIN accounts a ON a.id = ua.account_id
WHERE ua.user_id IN (SELECT id FROM users WHERE phone IN ('250788606765', '0788606765') OR phone LIKE '%788606765');
