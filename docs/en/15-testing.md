# Testing / Тестирование

## Level 1. In simple words

Tests verify that GreenCore works correctly.

## Level 2. Technical explanation

All tests are written in Lua.
They do not require external frameworks.

## Test runner

```lua
GCTest = {}

function GCTest.ExpectEqual(actual, expected, testName)
end

function GCTest.ExpectTrue(value, testName)
end

function GCTest.ExpectFalse(value, testName)
end

function GCTest.Run()
end
```

## Test files

| File | What it checks |
| ---- | -------------- |
| `test_runner.lua` | Built-in test runner |
| `validation_test.lua` | Payload validation |
| `states_test.lua` | State transitions |
| `sessions_test.lua` | Sessions |
| `connection_test.lua` | Identifiers |
| `spawn_test.lua` | Spawn |
| `rate_limit_test.lua` | Rate limit |
| `notifications_test.lua` | Notifications |
| `run.lua` | Entry point for running tests |

## What is checked

- Payload validation.
- Session ID generation.
- Session creation.
- Session cloning.
- Session removal.
- Allowed transitions.
- Forbidden transitions.
- Identifier masking.
- Rate limit.
- Spawn decision creation.
- Decision ID validation.
- Decision expiry.
- Duplicate confirmation.

## Running tests

Tests run automatically when `gc_core` starts, if development mode
is enabled in `config/general.lua`:

```lua
GCConfig.General.developmentMode = true
```

In this case the `tests/run.lua` file calls `GCTest.Run()` automatically.
In production (`developmentMode = false`) the tests are skipped.

You can also run the tests manually through the server console:

```lua
GCTest.Run()
```

Test files are loaded in `fxmanifest.lua` in the `server_scripts` block
after the main server logic.

## Manual test scenarios

### Successful connection

**Expected result**: the player passes validation, gets a Lua session, and spawns at the configured point.

### Missing license

**Expected result**: the connection is rejected with a clear localized message.

### Duplicate connection

**Expected result**: the second connection with the same license is handled according to the configuration.

### Duplicate `clientReady`

**Expected result**: no new session is created and no duplicate spawn runs.

### Fake Decision ID

**Expected result**: the server rejects the confirmation.

### Expired decision

**Expected result**: the server does not accept the confirmation.

### Model load error

**Expected result**: the client finishes waiting by timeout and reports the error code to the server.

### Disconnection during spawn

**Expected result**: the Lua session and the temporary decision are fully removed.

### Resource restart

**Expected result**: players resync without endless spawning.

## Next step

Go to [Development Guide](16-development-guide.md).