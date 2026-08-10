# gc_identity

`gc_identity` determines who a connected GCore player is. `gc_core` owns the
connection, session, and spawn lifecycle; this independent module owns a
license-backed account, character list, selected character, and identity state.

Version: `0.1.0-alpha`
Identity API: `1`
Identity protocol: `1`
Required Core API: `>= 1`

## Scope

The MVP automatically resolves or creates an account from a trusted server-side
core identifier. Players can create up to three characters and select one. It
does not implement passwords, NUI, roles, money, inventory, jobs, or a general
database layer.

## Install

The resource declares `dependency 'gc_core'`. Add:

```cfg
ensure gc_core
ensure gc_identity
```

After an administrative `restart gc_core`, FiveM stops declared dependants. Run
`ensure gc_identity` afterwards; the module performs a bounded online-player
recovery and restores persisted selections.

Runtime identity data is saved to `data/identities.json` and ignored by Git.
Back it up like other private server data.

## Commands

- `/gcidentity` — request a fresh identity snapshot.
- `/gccreate FirstName LastName` — create a character after core spawn.
- `/gcselect ID` — select a character owned by the current account.

Commands are only a minimal alpha interaction surface. The server validates all
payloads, lifecycle, ownership, rate limits, and replay IDs. No NUI is required.

## Public server API v1

| Export | Returns |
| --- | --- |
| `GetIdentityVersion()` | resource version string |
| `GetIdentityApiVersion()` | integer API version |
| `GetIdentityProtocolVersion()` | integer protocol version |
| `IsAuthorized(source)` | account resolution state |
| `IsIdentityReady(source)` | selected-character readiness |
| `GetIdentityState(source)` | state or `nil` |
| `GetAccount(source)` | detached Account DTO or `nil` |
| `GetCharacters(source)` | detached Character DTO array |
| `GetSelectedCharacter(source)` | detached Character DTO or `nil` |

Example downstream gate:

```lua
local coreReady = exports.gc_core:CanUseGameplayFeatures(source)
local identityReady = exports.gc_identity:IsIdentityReady(source)

if not coreReady or not identityReady then
    return
end
```

Account DTO contains only `id` and `createdAt`. Character DTO contains `id`,
`firstName`, `lastName`, and `createdAt`. Identifier and persistence metadata are
never public.

## Events and security

Client → server: `hello`, `createCharacter`, and `selectCharacter` events from the
registry in `shared/events.lua`. Server → client: `snapshot` and `rejected`.
Server-only client handlers enforce `source == 65535`. All ingress payloads use
exact schemas, module protocol 1, bounded rates, and server-side ownership.

See the full [design](../../../docs/en/modules/gc_identity/design.md), the GCore
[Module Contract](../../../docs/en/module-contract.md), and module tests:

```sh
lua tools/module_test_harness.lua . gc_identity
```

## Troubleshooting

- `GC-IDENTITY-CORE-*`: verify `gc_core` is started and API is at least 1.
- `GC-IDENTITY-STORAGE-*`: verify the resource data directory is writable and
  the private JSON file is valid.
- `GC-IDENTITY-PROTOCOL-MISMATCH`: client and server resource builds differ.
- `GC-IDENTITY-RATE-LIMIT`: wait for the bounded request window to reset.
- Module remains stopped after `restart gc_core`: run `ensure gc_identity` as the
  documented dependency restart sequence.
