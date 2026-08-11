GCIdentityMigrations.Register({
    version = '003_pre_spawn_registration',
    description = 'Registered account name and explicit pre-spawn registration finalization',
    statements = {
        [[
            ALTER TABLE `gc_accounts`
                ADD COLUMN IF NOT EXISTS `first_name` VARCHAR(32) NULL AFTER `email`,
                ADD COLUMN IF NOT EXISTS `last_name` VARCHAR(32) NULL AFTER `first_name`
        ]],
        [[
            ALTER TABLE `gc_identity_verification_challenges`
                ADD COLUMN IF NOT EXISTS `pending_first_name` VARCHAR(32) NULL AFTER `email`,
                ADD COLUMN IF NOT EXISTS `pending_last_name` VARCHAR(32) NULL AFTER `pending_first_name`,
                ADD COLUMN IF NOT EXISTS `verified_at` DATETIME(3) NULL AFTER `last_sent_at`
        ]]
    }
})
