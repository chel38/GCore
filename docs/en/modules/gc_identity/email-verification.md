# gc_identity email verification and network-risk flow

Version `0.3.0-alpha` keeps Identity API v1 backward-compatible and raises the
module network protocol to v2. The protocol change is intentional: registration
is no longer complete after submitting an email; a server-generated one-time
code is mandatory.

## Ownership and trust

```text
FiveM license       gc_core server export       primary trusted identity
current IP          GetPlayerEndpoint server    secondary risk signal
email/code input    NUI -> client -> server      untrusted
challenge/state     gc_identity server + DB      authoritative
mail result         localhost mail service       infrastructure result only
```

The client never sends an IP. `gc_identity` removes the source port, canonicalizes
IPv4/IPv6/IPv4-mapped IPv6, and stores only
`HMAC-SHA256(gcore_ip_fingerprint_secret, normalizedIP)`. IP is not account
ownership proof and only decides whether an additional email check is needed.

## Registration

```text
registration_required -> email submitted -> registering
  -> secure 6-digit code from MariaDB RANDOM_BYTES
  -> HMAC digest stored in DB-backed one-time challenge
  -> localhost mail request accepted
  -> email_verification_pending
  -> server validates code, TTL, attempts, binding and current endpoint
  -> one transaction consumes challenge, creates account, links license,
     marks email verified and stores first IP fingerprint
  -> authorized -> character_required/ready
```

No active account is created before code verification. A code lives for 10
minutes, has five attempts, and resend has a 60-second cooldown. Resend consumes
the previous challenge. All values are configurable in module config; expiry and
attempts are enforced by the server, not the NUI countdown.

## Returning player

- Same license + same fingerprint: automatic authorization, no mail dependency.
- Same license + different fingerprint: `auth_verification_required`, an
  `authentication` email, and no authorization until the correct code.
- A successful new-IP code replaces the single stored trusted fingerprint.
- Legacy accounts with no `email_verified_at` return to registration/email
  confirmation; migrations never mark old email data as verified blindly.

## Failure and restart policy

Challenges are stored in MariaDB and survive `gc_identity` restart until expiry.
Session generation and challenge ID guards discard stale HTTP callbacks. Every
HTTP wait is bounded. A failed/timeout mail request consumes the unsent challenge.
Mail outage does not disable the module: same-IP users continue, while registration
and new-IP authorization fail closed and remain retryable.

## Public and NUI boundaries

Identity API v1 returns the same copied Account/Character DTOs and never exposes
challenge state, code digest, attempts, IP fingerprint, or secrets. NUI snapshots
may contain only verification type, masked email, `expiresIn`, and `resendIn`.
The expected code never reaches NUI. New protocol-v2 ingress events are
`verifyEmail` and `resendVerification`; every payload is exact-schema validated
and rate-limited.

See [the mail service README](../../../../mail-service/README.md) for process and
SMTP setup.
