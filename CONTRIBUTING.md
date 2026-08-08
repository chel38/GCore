# Contributing / Вклад в проект

Спасибо за интерес к GreenCore! / Thank you for your interest in GreenCore!

## Язык проекта / Project language

Runtime ядра `gc_core` (сервер, клиент, shared, config, locales, tests) пишется **только на Lua 5.4**.
The `gc_core` core runtime (server, client, shared, config, locales, tests) is written **only in Lua 5.4**.

Дальнейшая разработка и добавление **NUI** будут использовать **TypeScript + Tailwind CSS**
и другие современные технологии, поддерживаемые FiveM.
Further development and adding **NUI** will use **TypeScript + Tailwind CSS**
and other modern FiveM-supported technologies.

Запрещены / Forbidden:

- C# (не используется) / C# (not used)
- Ручной JavaScript без сборки из TypeScript / Hand-written JavaScript without a TypeScript build
- JSON для конфигурации и локализации / JSON for configuration and localization
- Базы данных / Databases
- Внешние бинарные зависимости / External binary dependencies

## Правила / Rules

1. Комментарии пишутся на русском и английском / Comments are written in Russian and English.
2. Каждая функция должна быть документирована / Every function must be documented.
3. Не добавляйте игровые системы в `gc_core` / Do not add gameplay systems to `gc_core`.
4. Соблюдайте стиль Lua-кода из `docs/ru/16-development-guide.md`.
5. Тесты пишутся на Lua / Tests are written in Lua.

## Процесс / Process

1. Создайте ветку / Create a branch.
2. Внесите изменения / Make your changes.
3. Добавьте тесты / Add tests.
4. Обновите документацию / Update documentation.
5. Обновите `CHANGELOG.md`.
6. Создайте pull request / Create a pull request.