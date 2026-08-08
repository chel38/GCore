# Security Policy / Политика безопасности

## Поддерживаемые версии / Supported versions

| Версия / Version | Поддержка / Supported |
| ---------------- | --------------------- |
| 0.1.x            | ✅                    |

## Сообщение об уязвимости / Reporting a vulnerability

Если вы обнаружили уязвимость, **не** создавайте публичный issue.
If you find a vulnerability, do **not** create a public issue.

Свяжитесь с командой GreenCore напрямую.
Contact the GreenCore team directly.

## Принципы безопасности / Security principles

- Сервер является источником истины / Server is the source of truth.
- Клиент никогда не доверяется / Client is never trusted.
- Все payload проверяются / All payloads are validated.
- Идентификаторы маскируются / Identifiers are masked.
- Rate limit на все события / Rate limit on all events.
- Никакого выполнения кода из строк / No code execution from strings.