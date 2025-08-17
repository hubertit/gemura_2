-- Insert sample notifications for testing
-- Replace user_id and account_id with actual values from your database

-- Sample notifications for user_id = 1, account_id = 18 (adjust as needed)
INSERT INTO `notifications` (`user_id`, `account_id`, `title`, `message`, `type`, `category`, `is_read`, `is_important`, `action_url`, `action_data`, `expires_at`) VALUES
-- Unread notifications
(1, 18, 'New Collection Recorded', 'Successfully recorded 25L milk collection from supplier John Doe', 'success', 'business', 0, 0, '/collections', '{"collection_id": 123, "supplier_name": "John Doe"}', NULL),
(1, 18, 'Payment Received', 'Received payment of 15,000 Frw from customer Jane Smith', 'success', 'financial', 0, 1, '/sales', '{"sale_id": 456, "customer_name": "Jane Smith", "amount": 15000}', NULL),
(1, 18, 'Low Stock Alert', 'Milk collection is below average for this week', 'warning', 'alert', 0, 1, '/overview', '{"metric": "collections", "current": 150, "average": 200}', NULL),
(1, 18, 'New Supplier Registered', 'Supplier Alice Johnson has been added to your network', 'info', 'business', 0, 0, '/suppliers', '{"supplier_id": 789, "supplier_name": "Alice Johnson"}', NULL),
(1, 18, 'System Maintenance', 'Scheduled maintenance on Sunday 2:00 AM - 4:00 AM', 'info', 'system', 0, 0, NULL, '{"maintenance_time": "2024-01-21 02:00:00"}', '2024-01-21 04:00:00'),

-- Read notifications
(1, 18, 'Collection Completed', 'Daily collection summary: 180L collected from 12 suppliers', 'info', 'business', 1, 0, '/collections', '{"total_liters": 180, "supplier_count": 12}', NULL),
(1, 18, 'Sales Report', 'Weekly sales report: 150L sold, 45,000 Frw revenue', 'success', 'financial', 1, 0, '/sales', '{"total_liters": 150, "revenue": 45000}', NULL),
(1, 18, 'Account Updated', 'Your account information has been successfully updated', 'success', 'general', 1, 0, '/profile', NULL, NULL),
(1, 18, 'Welcome to Gemura', 'Thank you for joining our dairy management platform!', 'info', 'general', 1, 0, '/onboarding', NULL, NULL),
(1, 18, 'Backup Completed', 'Your data has been automatically backed up', 'info', 'system', 1, 0, NULL, NULL, NULL);

-- Additional notifications for different scenarios
INSERT INTO `notifications` (`user_id`, `account_id`, `title`, `message`, `type`, `category`, `is_read`, `is_important`, `action_url`, `action_data`, `expires_at`) VALUES
-- Important business notifications
(1, 18, 'High Demand Alert', 'Customer requests have increased by 30% this week', 'warning', 'business', 0, 1, '/customers', '{"demand_increase": 30, "customer_count": 25}', NULL),
(1, 18, 'Payment Overdue', 'Payment of 25,000 Frw is overdue from customer Bob Wilson', 'error', 'financial', 0, 1, '/sales', '{"customer_id": 101, "amount": 25000, "days_overdue": 5}', NULL),
(1, 18, 'Quality Issue', 'Milk quality test failed for supplier Mary Brown', 'error', 'business', 0, 1, '/collections', '{"supplier_id": 202, "issue": "quality_test_failed"}', NULL),

-- Reminder notifications
(1, 18, 'Collection Reminder', 'Don\'t forget to collect milk from suppliers today', 'info', 'reminder', 0, 0, '/collections', NULL, NULL),
(1, 18, 'Payment Due', 'Payment of 12,000 Frw is due tomorrow', 'warning', 'reminder', 0, 0, '/sales', '{"amount": 12000, "due_date": "2024-01-20"}', NULL),
(1, 18, 'Monthly Report', 'Your monthly report is ready for review', 'info', 'reminder', 0, 0, '/reports', NULL, NULL);
