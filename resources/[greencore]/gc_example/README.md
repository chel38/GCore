# gc_example

`gc_example` is the smallest possible GCore reference module. It demonstrates
how an independent resource checks Core API compatibility, reads a detached
player DTO, gates gameplay on server-owned lifecycle state, and sends a
notification without touching `gc_core` internals.

## Install and run

The resource is already placed next to `gc_core` and declares
`dependency 'gc_core'`. Add this after `ensure gc_core`:

```cfg
ensure gc_example
```

Run `/gcexample` as a connected player. The server checks
`CanUseGameplayFeatures(source)`, obtains a fresh Public Session DTO, and calls
`NotifyPlayer`. From the server console, the same command prints compatible core
version metadata.

## Contract demonstrated

- Required Core API: `>= 1`; no exact core resource version dependency.
- Server-only implementation; the client supplies no authoritative payload.
- Uses only documented `gc_core` exports.
- Re-checks exports after a `gc_core` resource start and fails closed while core
  is unavailable.
- Owns no account, character, money, inventory, or other gameplay state.

## Tests

```sh
lua tools/module_test_harness.lua . gc_example
```

Tests cover compatibility, stopped-core behavior, gameplay gating, public DTO
usage, notifications, and command registration. See the repository
[Module Contract](../../../docs/en/module-contract.md).
