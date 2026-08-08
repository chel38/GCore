# Security

Trust model: the client requests, the server validates and decides, the client
executes, and the server independently verifies the result.

## Trust boundaries

- `source` comes only from the network event context.
- Clients cannot choose session IDs, peds, coordinates, or server state.
- Every payload is an exact allowlisted table with bounded strings and finite
  numbers; NaN and infinities are rejected.
- Handshakes require an exact protocol match.
- Decision IDs are correlation values, not secrets. Authorization uses source,
  current session, state, TTL, and one-time consumption.
- `confirmSpawn` is not proof. During a bounded window the server verifies the
  OneSync ped, entity existence, owner, health, model, and decision distance.
- During recovery `isPedAlive` is diagnostic only; the server reads its own ped.

## Retry and replay

Each spawn decision is one-time. On failure the old decision is removed, the model
is added to `attemptedPedModels`, state returns to `spawn_pending`, and a new ID is
created after a delay. Attempt/model counts are bounded. Replays, foreign sources,
foreign sessions, expired IDs, and consumed IDs are rejected.

## Rate limits

All five ingress actions have independent interval/window/maxAttempts settings.
Violation timestamps expire after `violationWindowMs`; the kick threshold applies
only to the current window. An invalid payload also counts as a violation.

## Data and logs

The logger masks license, IP, Discord, and other sensitive keys automatically.
`GetPlayerSession` does not expose identifiers or internal decisions. FXServer and
txAdmin secrets live only in ignored `txData`, never in Git.

Report vulnerabilities through [private vulnerability reporting](../../SECURITY.md).

Continue with [errors](13-errors.md).
