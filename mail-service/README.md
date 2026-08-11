# GCore Mail Service

This is a small, stateless SMTP delivery boundary for `gc_identity`. It accepts
verification presentation data from GCore over localhost HTTP and sends a
plain-text plus HTML email. It does **not** own accounts, generate codes, verify
codes, inspect FiveM licenses/IPs, or store data.

## Architecture

```text
gc_identity (authoritative challenge owner)
  -> HTTP 127.0.0.1 + X-GCore-Mail-Token
  -> GCore Mail Service
  -> generic SMTP
  -> Mailpit in development / SMTP provider in production
```

The HTTP server refuses every bind address except `127.0.0.1`. `POST` requests
have an 8 KiB body limit, constant-time token comparison, strict payload schema,
an additional fixed-window rate limit, and bounded SMTP timeouts. The service is
stateless and has no database.

## Requirements and install

- Node.js 22 LTS or newer
- pnpm 11
- an SMTP server (Mailpit is recommended locally)

```powershell
cd C:\Gcore\mail-service
pnpm install --frozen-lockfile
Copy-Item .env.example .env
```

Replace `MAIL_SERVICE_TOKEN` with a random secret of at least 32 characters.
`.env` is ignored by Git. Never commit the token or SMTP password.

## Run and verify

```powershell
pnpm dev
# or
pnpm build
pnpm start
```

```powershell
Invoke-RestMethod http://127.0.0.1:8091/health
```

Success is `{ "ok": true, "service": "gcore-mail-service", "status": "healthy" }`.
`POST /v1/email/verification` requires `X-GCore-Mail-Token` and accepts exactly:

```json
{ "email": "user@example.com", "code": "483921", "type": "registration" }
```

`type` is `registration` or `authentication`. HTTP `202` means the configured
SMTP server accepted the message; it is not a guarantee that an inbox provider
will deliver it.

## Mailpit

Run Mailpit with SMTP on `127.0.0.1:1025` and its web UI on a local port (the
standard standalone defaults are SMTP 1025 and UI 8025). Keep the example SMTP
settings and open `http://127.0.0.1:8025` to inspect HTML and plain text. No SMTP
username/password is needed.

## Production SMTP

Change only `.env`: `SMTP_HOST`, `SMTP_PORT`, `SMTP_SECURE`, optional paired
`SMTP_USER`/`SMTP_PASSWORD`, and the sender name/address. TLS certificate
validation is never disabled. Deliverability also depends on the provider,
SPF, DKIM, DMARC, reputation, and recipient filtering.

## GCore integration

Set these FXServer convars before `ensure gc_identity`:

```cfg
set gcore_mail_service_url "http://127.0.0.1:8091"
set gcore_mail_token "same-long-random-value-as-mail-service"
set gcore_identity_challenge_secret "independent-random-secret-at-least-32-chars"
set gcore_ip_fingerprint_secret "another-independent-random-secret-at-least-32-chars"
```

Use independent secrets. Changing the IP secret invalidates stored trust
fingerprints and causes email verification on the next login. Existing users
from the same trusted IP can authorize while mail is unavailable; registration
and new-IP authorization always fail closed.

## Tests and troubleshooting

```powershell
pnpm lint
pnpm test
pnpm build
```

- `MAIL-CONFIG-UNSAFE-HOST`: host must be exactly `127.0.0.1`.
- `MAIL-UNAUTHORIZED`: token mismatch between FXServer and mail service.
- `MAIL-SMTP-FAILED`: check SMTP address, TLS/auth, Mailpit, and timeouts.
- HTTP health succeeds but mail fails: HTTP process is alive; SMTP is not usable.

Logs mask recipient email and never include codes, tokens, SMTP credentials,
FiveM identifiers, account IDs, or IP addresses.
