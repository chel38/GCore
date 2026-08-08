# Безопасность

Модель доверия: клиент запрашивает, сервер валидирует и принимает решение, клиент
исполняет, сервер независимо проверяет результат.

## Границы доверия

- `source` берётся только из контекста сетевого события.
- Клиент не задаёт session ID, ped, координаты или server state.
- Любой payload должен быть table с точным allowlist полей, ограниченными строками
  и конечными числами; NaN/Infinity отклоняются.
- Handshake требует точного protocol match.
- Decision ID — корреляционный, а не секретный. Авторизация строится на source,
  текущей session, state, TTL и one-time consumption.
- `confirmSpawn` не доказывает спавн. Сервер в ограниченном окне проверяет OneSync
  ped, entity existence, owner, health, model и расстояние до решения.
- В recovery `isPedAlive` — только diagnostic hint. Сервер читает собственный ped.

## Retry и replay

Каждое spawn decision одноразовое. При ошибке старое решение немедленно удаляется,
модель добавляется в `attemptedPedModels`, state возвращается в `spawn_pending`, и
после задержки создаётся новый ID. Количество попыток и моделей ограничено. Replay,
чужой source, чужая session, истёкший или уже использованный ID отклоняются.

## Rate limits

Пять входных действий имеют независимые interval/window/maxAttempts. Нарушения
хранятся как timestamps и удаляются после `violationWindowMs`; kick threshold
применяется только к текущему окну. Невалидный payload также считается нарушением.

## Данные и логи

Logger автоматически маскирует license, IP, Discord и другие чувствительные ключи.
`GetPlayerSession` не раскрывает identifiers или внутренние решения. Секреты
FXServer/txAdmin хранятся только в игнорируемом `txData`, а не в Git.

Сообщайте об уязвимостях через [private vulnerability reporting](../../SECURITY.md).

Перейдите к [ошибкам](13-errors.md).
