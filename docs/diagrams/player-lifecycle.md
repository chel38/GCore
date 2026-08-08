# Жизненный цикл игрока / Player Lifecycle

## Диаграмма / Diagram

```mermaid
stateDiagram-v2
    [*] --> connecting
    connecting --> validated
    validated --> joining
    joining --> client_ready
    client_ready --> spawn_pending
    spawn_pending --> spawning
    spawning --> spawned
    spawned --> disconnecting
    disconnecting --> disconnected
    disconnected --> [*]

    connecting --> rejected
    validated --> rejected
    joining --> error
    client_ready --> error
    spawn_pending --> error
    spawning --> error
    error --> disconnecting
```

## Объяснение RU

- **connecting**: игрок подключается.
- **validated**: проверка завершена.
- **joining**: игрок входит.
- **client_ready**: клиент готов.
- **spawn_pending**: спавн подготавливается.
- **spawning**: выполняется спавн.
- **spawned**: игрок появился.
- **disconnecting**: игрок отключается.
- **disconnected**: игрок отключён.
- **rejected**: подключение отклонено.
- **error**: произошла ошибка.

## Explanation EN

- **connecting**: the player is connecting.
- **validated**: validation completed.
- **joining**: the player is joining.
- **client_ready**: the client is ready.
- **spawn_pending**: spawn is being prepared.
- **spawning**: spawn is in progress.
- **spawned**: the player has spawned.
- **disconnecting**: the player is disconnecting.
- **disconnected**: the player disconnected.
- **rejected**: connection rejected.
- **error**: an error occurred.

## ASCII-схема / ASCII diagram

```text
[*] → connecting → validated → joining → client_ready
      → spawn_pending → spawning → spawned
      → disconnecting → disconnected → [*]

connecting → rejected
validated → rejected
joining → error
client_ready → error
spawn_pending → error
spawning → error
error → disconnecting