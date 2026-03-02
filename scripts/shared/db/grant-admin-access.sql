-- Grant admin access to user 250788606765 (Hubert) for MCC GISHALI and MCC KIGABIRO accounts
-- User ID for 250788606765: 198ee784-0053-433b-a5f8-470ffaf0123c
-- MCC GISHALI account_id: d4ad78d2-35ff-4f7f-bbea-e7175d7167de
-- MCC KIGABIRO account_id: fed91790-af71-4663-aca2-e10e1c685d9f

INSERT INTO user_accounts (id, user_id, account_id, role, status, created_at)
VALUES
  (gen_random_uuid(), '198ee784-0053-433b-a5f8-470ffaf0123c', 'd4ad78d2-35ff-4f7f-bbea-e7175d7167de', 'admin', 'active', NOW()),
  (gen_random_uuid(), '198ee784-0053-433b-a5f8-470ffaf0123c', 'fed91790-af71-4663-aca2-e10e1c685d9f', 'admin', 'active', NOW())
ON CONFLICT (user_id, account_id) DO UPDATE SET role = 'admin', status = 'active';
