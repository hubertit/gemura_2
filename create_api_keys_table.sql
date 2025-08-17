-- Create api_keys table for storing universal API keys like OpenAI, Claude, Google, etc.
CREATE TABLE IF NOT EXISTS `api_keys` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `key_name` varchar(255) NOT NULL,
  `key_type` ENUM('openai', 'claude', 'google', 'anthropic', 'azure', 'aws', 'other') NOT NULL,
  `key_value` text NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `status` ENUM('active', 'inactive', 'deleted') NOT NULL DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `key_type` (`key_type`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Sample data (optional - remove the comments to insert sample data)
-- INSERT INTO `api_keys` (`key_name`, `key_type`, `key_value`, `is_active`) VALUES
-- ('OpenAI API Key', 'openai', 'sk-...', 1),
-- ('Claude AI', 'claude', 'sk-ant-...', 1),
-- ('Google AI', 'google', 'AIza...', 1);
