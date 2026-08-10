# gc_identity Changelog

## [0.2.0-alpha] - 2026-08-10

### Added

- Explicit email registration and trusted-license returning authorization.
- MariaDB/oxmysql production repository, ordered migrations, constraints, and
  transactional account/character operations.
- Read-only idempotent import of legacy JSON identity records.
- TypeScript/Tailwind NUI with registration, character, error, and exit views.
- `GetIdentityHealth` additive API v1 export.
- Repository, migration, persistence, NUI, startup-race, and security tests.

### Changed

- Production storage no longer uses JSON and has no silent fallback.
- Unknown identifiers enter `registration_required` instead of automatically
  creating an account.
- Identity state machine now models loading, registration, selection, error,
  and disconnecting transitions explicitly.
- Account DTO additively includes registered email and account status.

### Security

- Password authentication is explicitly disabled; no password is collected or
  stored.
- Runtime SQL is parameterized and critical writes are transactional.
- NUI double submits, forged authority fields, foreign character IDs, stale
  storage results, server-event spoofing, and startup races have regressions.

## [0.1.0-alpha] - 2026-08-10

### Added

- License-backed account resolution through GCore Public API v1.
- Explicit identity state machine and detached Public DTOs.
- Character creation, ownership validation, selection, and limits.
- JSON repository adapter behind a replaceable persistence boundary.
- Strict payload validation, protocol checks, rate limits, and replay handling.
- Resource/core restart recovery and disconnect cleanup.
- Public Identity API v1, RU/EN documentation, and automated tests.
