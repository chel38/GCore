GCIdentityMigrations.Register({
    version = '001_initial_identity',
    description = 'Persistent accounts, trusted identifiers, characters, and selection',
    statements = {
        [[
            CREATE TABLE IF NOT EXISTS `gc_accounts` (
                `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                `email` VARCHAR(254) NULL,
                `status` VARCHAR(16) NOT NULL DEFAULT 'active',
                `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
                `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
                    ON UPDATE CURRENT_TIMESTAMP(3),
                `last_login_at` DATETIME(3) NULL,
                PRIMARY KEY (`id`),
                UNIQUE KEY `uk_gc_accounts_email` (`email`),
                CONSTRAINT `chk_gc_accounts_status`
                    CHECK (`status` IN ('active', 'disabled', 'locked'))
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ]],
        [[
            CREATE TABLE IF NOT EXISTS `gc_account_identifiers` (
                `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                `account_id` BIGINT UNSIGNED NOT NULL,
                `identifier_type` VARCHAR(32) NOT NULL,
                `identifier` VARCHAR(191) NOT NULL,
                `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
                `last_seen_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
                PRIMARY KEY (`id`),
                UNIQUE KEY `uk_gc_account_identifiers_value`
                    (`identifier_type`, `identifier`),
                KEY `idx_gc_account_identifiers_account` (`account_id`),
                CONSTRAINT `fk_gc_account_identifiers_account`
                    FOREIGN KEY (`account_id`) REFERENCES `gc_accounts` (`id`)
                    ON UPDATE RESTRICT ON DELETE RESTRICT
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin
        ]],
        [[
            CREATE TABLE IF NOT EXISTS `gc_characters` (
                `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                `account_id` BIGINT UNSIGNED NOT NULL,
                `first_name` VARCHAR(32) NOT NULL,
                `last_name` VARCHAR(32) NOT NULL,
                `status` VARCHAR(16) NOT NULL DEFAULT 'active',
                `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
                `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
                    ON UPDATE CURRENT_TIMESTAMP(3),
                PRIMARY KEY (`id`),
                KEY `idx_gc_characters_account` (`account_id`, `status`, `id`),
                CONSTRAINT `chk_gc_characters_status`
                    CHECK (`status` IN ('active', 'disabled')),
                CONSTRAINT `fk_gc_characters_account`
                    FOREIGN KEY (`account_id`) REFERENCES `gc_accounts` (`id`)
                    ON UPDATE RESTRICT ON DELETE RESTRICT
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ]],
        [[
            CREATE TABLE IF NOT EXISTS `gc_account_character_selections` (
                `account_id` BIGINT UNSIGNED NOT NULL,
                `character_id` BIGINT UNSIGNED NOT NULL,
                `selected_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
                PRIMARY KEY (`account_id`),
                UNIQUE KEY `uk_gc_character_selections_character` (`character_id`),
                CONSTRAINT `fk_gc_character_selections_account`
                    FOREIGN KEY (`account_id`) REFERENCES `gc_accounts` (`id`)
                    ON UPDATE RESTRICT ON DELETE CASCADE,
                CONSTRAINT `fk_gc_character_selections_character`
                    FOREIGN KEY (`character_id`) REFERENCES `gc_characters` (`id`)
                    ON UPDATE RESTRICT ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ]]
    }
})
