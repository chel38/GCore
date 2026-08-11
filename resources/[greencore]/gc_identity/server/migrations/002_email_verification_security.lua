GCIdentityMigrations.Register({
    version = '002_email_verification_security',
    description = 'Verified email, trusted IP fingerprint, and one-time challenges',
    statements = {
        [[
            ALTER TABLE `gc_accounts`
                ADD COLUMN IF NOT EXISTS `email_verified_at` DATETIME(3) NULL AFTER `email`,
                ADD COLUMN IF NOT EXISTS `last_ip_fingerprint` CHAR(64) NULL AFTER `email_verified_at`
        ]],
        [[
            CREATE TABLE IF NOT EXISTS `gc_identity_verification_challenges` (
                `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                `account_id` BIGINT UNSIGNED NULL,
                `binding_key` CHAR(64) NOT NULL,
                `email` VARCHAR(254) NOT NULL,
                `verification_type` VARCHAR(24) NOT NULL,
                `code_hash` CHAR(64) NOT NULL,
                `expires_at` DATETIME(3) NOT NULL,
                `attempts` TINYINT UNSIGNED NOT NULL DEFAULT 0,
                `max_attempts` TINYINT UNSIGNED NOT NULL,
                `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
                `last_sent_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
                `consumed_at` DATETIME(3) NULL,
                PRIMARY KEY (`id`),
                KEY `idx_gc_identity_challenge_binding`
                    (`binding_key`, `verification_type`, `consumed_at`, `expires_at`),
                KEY `idx_gc_identity_challenge_account` (`account_id`),
                CONSTRAINT `fk_gc_identity_challenge_account`
                    FOREIGN KEY (`account_id`) REFERENCES `gc_accounts` (`id`)
                    ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ]]
    }
})
