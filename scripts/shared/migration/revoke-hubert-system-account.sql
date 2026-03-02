-- Remove 0788606765 (Hubert) access to any account named "System".
-- Hubert user_id: 198ee784-0053-433b-a5f8-470ffaf0123c

DELETE FROM user_accounts ua
USING accounts a
WHERE ua.account_id = a.id
  AND ua.user_id = '198ee784-0053-433b-a5f8-470ffaf0123c'
  AND lower(trim(a.name)) = 'system';
