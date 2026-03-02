-- Grant MCC Gahengeri user (250782638531) access to all accounts that 0788606765 (Hubert) has,
-- except accounts named/coded "syste" or "hubert".
-- Gahengeri user_id: ae2026e7-4ab3-44ee-b425-e38e9e3b8ea8
-- Hubert user_id: 198ee784-0053-433b-a5f8-470ffaf0123c

INSERT INTO user_accounts (id, user_id, account_id, role, status, created_at)
SELECT gen_random_uuid(), 'ae2026e7-4ab3-44ee-b425-e38e9e3b8ea8', ua.account_id, ua.role, 'active', NOW()
FROM user_accounts ua
JOIN accounts a ON a.id = ua.account_id
WHERE ua.user_id = '198ee784-0053-433b-a5f8-470ffaf0123c'
  AND ua.status = 'active'
  AND a.status = 'active'
  AND lower(trim(a.name)) NOT IN ('syste', 'system', 'hubert')
  AND (a.code IS NULL OR lower(trim(a.code)) NOT IN ('syste', 'system', 'hubert'))
ON CONFLICT (user_id, account_id) DO UPDATE SET role = EXCLUDED.role, status = 'active';
