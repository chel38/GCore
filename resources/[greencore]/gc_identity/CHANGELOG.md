# gc_identity Changelog

## [0.4.1-alpha] - 2026-08-11

### Fixed

- Replaced translucent, independently rendered fullscreen views with one opaque
  fixed `IdentityShell`, preventing GTA world leakage during registration,
  email verification, new-IP verification, and spawn release.
- Removed CEF `backdrop-filter` compositor layers and permanent hidden countdown
  polling that could leave black rectangles or unnecessary background work.
- Added centralized idempotent Lua/DOM cleanup for ready, exit, resource stop,
  core stop, NUI reload, and failed bundle paths. Focus, keep-input and the
  identity-owned ped freeze are always released together.
- Fixed a model-swap recovery race where cleanup could unfreeze only the old
  ped handle and leave the current player ped immobile after a resource restart.

### Changed

- Registration and verification cards now share one responsive RU/EN shell,
  preserve form drafts, sanitize pasted codes, and expose clearer loading,
  error, email-change, verified, and spawn-transition states.
- Frontend tests cover hidden transparency, fullscreen shell ownership, one
  active view, state reset, spawn handoff, new-IP auth, code sanitization and
  bounded timers. Lua runtime tests cover idempotent stop/exit cleanup and ped
  replacement during the identity-to-spawn handoff.
- Identity API remains v1 and module protocol remains v3.

## [0.4.0-alpha] - 2026-08-11

### Added

- Pre-spawn registered-name and email flow with explicit post-code finalization.
- Manual Core spawn release, same-IP fast path, new-IP verification, profile
  completion for legacy accounts, and `GetDisplayName(source)` API v1 export.
- Migration `003_pre_spawn_registration` and security regression coverage.

### Security

- Email verification alone creates no account and grants no spawn. Finalization
  revalidates the server-owned identifier, endpoint fingerprint, challenge,
  name and email inside one repository transaction.

## [0.3.0-alpha] - 2026-08-11

### Added

- Localhost-only, token-authenticated Fastify/Nodemailer mail service with
  generic SMTP, Mailpit templates, rate limiting, body limits, timeouts, tests,
  and independent CI.
- DB-backed one-time registration/authentication challenges with HMAC-SHA256
  code digests, bounded TTL/attempts/resend and transactional consumption.
- Server-observed IPv4/IPv6 normalization and HMAC IP fingerprints for a
  secondary new-network-address risk check.
- Registration/new-IP verification NUI, masked email, countdown, resend, and
  stable diagnostics.

### Changed

- Registration creates an active account only after the correct email code.
- Same-license/same-IP users auto-authorize; new-IP users require email proof.
- Identity API remains v1; module network protocol is v2.

### Security

- Raw codes and IPs are never persisted or logged; public DTOs contain no
  challenge/fingerprint metadata. Mail failure blocks registration/new-IP flows
  without blocking a verified same-IP login.

## [0.2.1-alpha] - 2026-08-11

### Fixed

- The eagerly loaded NUI page no longer paints a fullscreen loading layer before
  an authoritative Lua snapshot, removing the connection-time black screen.
- The inactive production document no longer forces a dark colour-scheme canvas;
  its root is explicitly hidden until an authoritative view exists.
- NUI focus and ped restriction are acquired only after the JavaScript-ready
  callback and are released on resource stop or bundle failure.
- Transient core/bootstrap/database races retry silently; degraded database and
  bounded hello failures now produce stable visible diagnostics.
- A missing NUI-ready callback performs one validated controlled disconnect
  instead of leaving a frozen player or an infinite black screen.

### Tests

- Added regressions for hidden initial UI, returning-player no-flash behavior,
  deterministic root visibility and snapshot replay, hello timeout, database
  degradation, broken bundle cleanup, and the client-failure allowlist.

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
