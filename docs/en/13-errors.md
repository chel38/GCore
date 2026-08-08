# Errors

`shared/errors.lua` is the single registry. Each entry contains `localeKey`,
`severity`, and `public`. `reportClientError` accepts only a registered code;
arbitrary client strings are rejected.

| Family | Meaning |
| --- | --- |
| `GC-PAYLOAD-TYPE/SCHEMA/NUMBER-*` | wrong type, extra field, NaN/infinity |
| `GC-PROTOCOL-MISMATCH-*` | incompatible protocol |
| `GC-RATE-LIMIT-*` | action limit exceeded |
| `GC-SPAWN-DECISION-*` | missing, expired, or consumed decision |
| `GC-SPAWN-ENTITY-*` | missing or dead server entity |
| `GC-SPAWN-OWNER-MISMATCH` | network owner is not the player source |
| `GC-SPAWN-MODEL/POSITION-MISMATCH` | snapshot differs from server decision |
| `GC-SPAWN-SESSION-CHANGED` | async verification transaction was canceled |
| `GC-SPAWN-VERIFY-*` | bounded server verification failure/timeout |
| `GC-SPAWN-PED-*` | ped config/load/exhaustion |
| `GC-RECOVERY-*`, `GC-RESYNC-*` | recovery timeout/stale/lifecycle diagnostics |

Never expose an internal code automatically. Check `GCErrors.IsPublic` and use the
localized `localeKey`. Logs must not include full identifiers, license keys, or
unbounded client-supplied text.

Continue with [troubleshooting](14-troubleshooting.md).
