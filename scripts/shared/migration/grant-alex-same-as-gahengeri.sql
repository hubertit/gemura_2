-- Grant Alex Ntare (250784968343) access to all accounts that MCC Gahengeri user has.
-- Alex user_id: 22e066cc-a48d-4adf-8c8b-0369960a8058
-- Gahengeri user_id: ae2026e7-4ab3-44ee-b425-e38e9e3b8ea8

INSERT INTO user_accounts (id, user_id, account_id, role, status, created_at)
SELECT gen_random_uuid(), '22e066cc-a48d-4adf-8c8b-0369960a8058', ua.account_id, ua.role, 'active', NOW()
FROM user_accounts ua
JOIN accounts a ON a.id = ua.account_id
WHERE ua.user_id = 'ae2026e7-4ab3-44ee-b425-e38e9e3b8ea8'
  AND ua.status = 'active'
  AND a.status = 'active'
ON CONFLICT (user_id, account_id) DO UPDATE SET role = EXCLUDED.role, status = 'active';
