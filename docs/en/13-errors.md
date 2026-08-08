# Errors / Ошибки

## Level 1. In simple words

Errors are codes that help understand what went wrong.

## Level 2. Technical explanation

Error format:

```text
GC-<AREA>-<NUMBER>
```

## Example codes

```text
GC-BOOT-001
GC-CONNECTION-001
GC-IDENTIFIER-001
GC-SESSION-001
GC-STATE-001
GC-PAYLOAD-001
GC-RATE-LIMIT-001
GC-SPAWN-001
GC-SPAWN-002
GC-CLIENT-001
GC-SECURITY-001
GC-INTERNAL-001
```

## Error table

```lua
GCErrors = {
    ['GC-CONNECTION-001'] = {
        localeKey = 'error.connection_invalid_source',
        severity = 'error',
        public = false
    }
}
```

## Error documentation: `GC-CONNECTION-002`

- **Code**: `GC-CONNECTION-002`
- **Area**: connection
- **Russian description**: Не удалось подтвердить лицензию FiveM.
- **English description**: Failed to verify the FiveM license.
- **Possible causes**: missing `license` and `license2`
- **Server actions**: rejects the connection
- **Client actions**: shows a message
- **Fix**: check the `connection.lua` configuration
- **Can be shown to the player**: yes

## Error documentation: `GC-SPAWN-002`

- **Code**: `GC-SPAWN-002`
- **Area**: spawn
- **Russian description**: Появление игрока запрещено.
- **English description**: Player spawn is denied.
- **Possible causes**: invalid state, fake Decision ID
- **Server actions**: rejects the request
- **Client actions**: shows a message
- **Fix**: check the player lifecycle
- **Can be shown to the player**: yes

## Next step

Go to [Troubleshooting](14-troubleshooting.md).