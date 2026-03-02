-- Delete users festo (250782638531) and Inyange (782638531); fix MCC Gahengeri phone 2500782638531 -> 250782638531
-- Keep: ae2026e7-4ab3-44ee-b425-e38e9e3b8ea8 (MCC Gahengeri, currently 2500782638531)
-- Delete: 065907ad-27e2-4894-b69e-8b9907df5266 (festo), 84a38982-c3c1-4093-9b8d-4b7013c4dd9c (Inyange)

BEGIN;

-- Reassign milk_sales.recorded_by (Restrict) from festo/Inyange to Gahengeri user
UPDATE milk_sales SET recorded_by = 'ae2026e7-4ab3-44ee-b425-e38e9e3b8ea8' WHERE recorded_by IN ('065907ad-27e2-4894-b69e-8b9907df5266', '84a38982-c3c1-4093-9b8d-4b7013c4dd9c');
UPDATE milk_sales SET created_by = 'ae2026e7-4ab3-44ee-b425-e38e9e3b8ea8' WHERE created_by IN ('065907ad-27e2-4894-b69e-8b9907df5266', '84a38982-c3c1-4093-9b8d-4b7013c4dd9c');
UPDATE milk_sales SET updated_by = 'ae2026e7-4ab3-44ee-b425-e38e9e3b8ea8' WHERE updated_by IN ('065907ad-27e2-4894-b69e-8b9907df5266', '84a38982-c3c1-4093-9b8d-4b7013c4dd9c');

-- Any other tables with user FKs that could block delete (SetNull columns we can leave or set to kept user)
-- user_accounts: cascade on user delete, so just delete users
-- Delete the two users (cascade will remove their user_accounts)
DELETE FROM users WHERE id = '065907ad-27e2-4894-b69e-8b9907df5266';
DELETE FROM users WHERE id = '84a38982-c3c1-4093-9b8d-4b7013c4dd9c';

-- Fix phone: remove extra 0 from 2500782638531 -> 250782638531
UPDATE users SET phone = '250782638531' WHERE id = 'ae2026e7-4ab3-44ee-b425-e38e9e3b8ea8';

COMMIT;
