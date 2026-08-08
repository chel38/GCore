# Security / Безопасность

## Level 1. In simple words

GreenCore does not trust the client.
The server validates every message from the client.

## Level 2. Technical explanation

The architecture is built around the rule:

```text
Client requests → Server validates → Server decides → Client executes → Server confirms
```

## Mandatory rules

1. Never trust the client.
2. Do not accept `source` from the payload.
3. Use the server `source` of the event.
4. Do not accept spawn coordinates from the client.
5. Do not accept a model from the client.
6. Do not accept a player state from the client.
7. Do not accept a Session ID from the client.
8. Do not accept a Decision ID not created by the server.
9. Validate the type of every value.
10. Validate the length of every string.
11. Limit the event frequency.
12. Validate the lifecycle.
13. Validate the decision expiry.
14. Do not process one decision twice.
15. Mask identifiers.
16. Do not execute code from strings.
17. Do not use unsafe global tables.
18. Do not allow the client to directly change the server session.
19. Do not create an automatic ban system.
20. Do not hide critical errors.

## Payload validation

All client data is considered untrusted.

```lua
function GCValidation.ClientReady(payload)
    if type(payload) ~= 'table' then
        return false, 'GC-PAYLOAD-TYPE-001'
    end

    if type(payload.clientVersion) ~= 'string' then
        return false, 'GC-PAYLOAD-VERSION-001'
    end

    if #payload.clientVersion > 32 then
        return false, 'GC-PAYLOAD-VERSION-002'
    end

    return true
end
```

## Rate limit

Each event has a frequency limit.

```lua
GCConfig.Security.rateLimits = {
    clientReady = {
        intervalMs = 3000,
        maxAttempts = 3,
        windowMs = 15000
    }
}
```

## Identifier masking

```text
license:12ab********************************90cd
```

The IP address does not appear in the regular log.

## Next step

Go to [Errors](13-errors.md).