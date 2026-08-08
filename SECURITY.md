# Security Policy / Политика безопасности

## Поддерживаемые версии / Supported versions

| Версия / Version | Поддержка / Supported |
| ---------------- | --------------------- |
| 0.1.x            | ✅                    |

## Сообщение об уязвимости / Reporting a vulnerability

Если вы обнаружили уязвимость, **не** создавайте публичный issue.
If you find a vulnerability, do **not** create a public issue.

Используйте [приватное сообщение об уязвимости GitHub](https://github.com/chel38/GCore/security/advisories/new).
Use [GitHub private vulnerability reporting](https://github.com/chel38/GCore/security/advisories/new).

Укажите затронутую версию, минимальные шаги воспроизведения, влияние и
предлагаемое исправление, если оно известно. Не публикуйте ключи сервера,
идентификаторы игроков или другие секреты.

Include the affected version, minimal reproduction steps, impact, and a proposed
fix when known. Never include server keys, player identifiers, or other secrets.

## Принципы безопасности / Security principles

- Сервер является источником истины / Server is the source of truth.
- Клиент никогда не доверяется / Client is never trusted.
- Все payload проверяются / All payloads are validated.
- Идентификаторы маскируются / Identifiers are masked.
- Rate limit на все события / Rate limit on all events.
- Никакого выполнения кода из строк / No code execution from strings.
