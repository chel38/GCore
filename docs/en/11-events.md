# Events / События

## Level 1. In simple words

Events are messages between the client and the server.
GreenCore uses a single namespace `gc_core:`.

## Level 2. Technical explanation

All events have unique names with the `gc_core:` prefix.
This prevents conflicts with other resources.

## Client → server events

| Event | Purpose |
| ----- | ------- |
| `gc_core:server:clientReady` | Client readiness |
| `gc_core:server:requestSpawn` | Spawn request |
| `gc_core:server:confirmSpawn` | Spawn confirmation |
| `gc_core:server:reportClientError` | Error report |

## Server → client events

| Event | Purpose |
| ----- | ------- |
| `gc_core:client:connectionAccepted` | Connection acceptance |
| `gc_core:client:spawnApproved` | Spawn approval |
| `gc_core:client:spawnRejected` | Spawn rejection |
| `gc_core:client:forceResync` | Force resync |
| `gc_core:client:notify` | Notification |

## Event documentation: `gc_core:server:clientReady`

- **Name**: `gc_core:server:clientReady`
- **Direction**: client → server
- **Purpose**: reports client readiness to the server
- **Payload**:
  ```lua
  {
      clientVersion = '0.1.0',
      protocolVersion = 1,
      locale = 'ru'
  }
  ```
- **Required fields**: `clientVersion`, `protocolVersion`
- **Types**: `string`, `number`
- **Limits**: `clientVersion` length ≤ 32
- **Allowed states**: `joining`
- **Rate limit**: `clientReady`
- **Possible errors**: `GC-PAYLOAD-*`

## Event documentation: `gc_core:server:confirmSpawn`

- **Name**: `gc_core:server:confirmSpawn`
- **Direction**: client → server
- **Purpose**: confirms the spawn completion
- **Payload**:
  ```lua
  {
      decisionId = 'gc:spawn:generated-id'
  }
  ```
- **Required fields**: `decisionId`
- **Types**: `string`
- **Limits**: `decisionId` length ≤ 128
- **Allowed states**: `spawning`
- **Rate limit**: `confirmSpawn`
- **Possible errors**: `GC-SPAWN-*`

## Event documentation: `gc_core:client:notify`

- **Name**: `gc_core:client:notify`
- **Direction**: server → client
- **Purpose**: shows a notification to the player
- **Payload**:
  ```lua
  {
      message = 'Welcome!',
      type = 'success'
  }
  ```
- **Required fields**: `message`
- **Types**: `string`, `string`
- **Limits**: `message` length ≤ 256
- **Allowed types**: `info`, `success`, `warning`, `error`
- **Sending**: via the `NotifyPlayer` and `NotifyAll` exports

## Forbidden names

```text
ready
spawn
start
load
check
playerReady
```

## Next step

Go to [Security](12-security.md).