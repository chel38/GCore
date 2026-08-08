# События / Events

## Уровень 1. Простыми словами

События — это сообщения между клиентом и сервером.
GreenCore использует единый namespace `gc_core:`.

## Уровень 2. Техническое объяснение

Все события имеют уникальные имена с префиксом `gc_core:`.
Это предотвращает конфликты с другими ресурсами.

## События клиент → сервер

| Событие | Назначение |
| ------- | ---------- |
| `gc_core:server:clientReady` | Готовность клиента |
| `gc_core:server:requestSpawn` | Запрос спавна |
| `gc_core:server:confirmSpawn` | Подтверждение спавна |
| `gc_core:server:reportClientError` | Сообщение об ошибке |

## События сервер → клиент

| Событие | Назначение |
| ------- | ---------- |
| `gc_core:client:connectionAccepted` | Подтверждение подключения |
| `gc_core:client:spawnApproved` | Одобрение спавна |
| `gc_core:client:spawnRejected` | Отклонение спавна |
| `gc_core:client:forceResync` | Принудительная ресинхронизация |
| `gc_core:client:notify` | Уведомление |

## Документация события: `gc_core:server:clientReady`

- **Название**: `gc_core:server:clientReady`
- **Направление**: клиент → сервер
- **Назначение**: сообщает серверу о готовности клиента
- **Payload**:
  ```lua
  {
      clientVersion = '0.1.0',
      protocolVersion = 1,
      locale = 'ru'
  }
  ```
- **Обязательные поля**: `clientVersion`, `protocolVersion`
- **Типы**: `string`, `number`
- **Ограничения**: длина `clientVersion` ≤ 32
- **Допустимые состояния**: `joining`
- **Rate limit**: `clientReady`
- **Возможные ошибки**: `GC-PAYLOAD-*`

## Документация события: `gc_core:server:confirmSpawn`

- **Название**: `gc_core:server:confirmSpawn`
- **Направление**: клиент → сервер
- **Назначение**: подтверждает завершение спавна
- **Payload**:
  ```lua
  {
      decisionId = 'gc:spawn:generated-id'
  }
  ```
- **Обязательные поля**: `decisionId`
- **Типы**: `string`
- **Ограничения**: длина `decisionId` ≤ 128
- **Допустимые состояния**: `spawning`
- **Rate limit**: `confirmSpawn`
- **Возможные ошибки**: `GC-SPAWN-*`

## Документация события: `gc_core:client:notify`

- **Название**: `gc_core:client:notify`
- **Направление**: сервер → клиент
- **Назначение**: показывает игроку уведомление
- **Payload**:
  ```lua
  {
      message = 'Добро пожаловать!',
      type = 'success'
  }
  ```
- **Обязательные поля**: `message`
- **Типы**: `string`, `string`
- **Ограничения**: длина `message` ≤ 256
- **Допустимые типы**: `info`, `success`, `warning`, `error`
- **Отправка**: через exports `NotifyPlayer` и `NotifyAll`

## Запрещённые названия

```text
ready
spawn
start
load
check
playerReady
```

## Следующий шаг

Перейдите к [Безопасности](12-security.md).