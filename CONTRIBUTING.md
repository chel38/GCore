# Contributing / Вклад в проект

Спасибо за интерес к GreenCore! / Thank you for your interest in GreenCore!

## Язык проекта / Project language

Код игровой логики (сервер и клиент) пишется **только на Lua 5.4**.
Game logic code (server and client) is written **only in Lua 5.4**.

Клиентская NUI-часть (интерфейсы, HUD, окна) пишется на **TypeScript + Tailwind CSS**.
Client-side NUI (interfaces, HUD, windows) is written with **TypeScript + Tailwind CSS**.

NUI-код (TypeScript) компилируется в JavaScript и подключается как статический ресурс;
JavaScript в NUI используется только как результат сборки, напрямую его не пишем.
NUI code (TypeScript) is compiled to JavaScript and shipped as a static resource;
JavaScript within NUI is only a build output, not written by hand.

Запрещены / Forbidden:

- C#, Python, Node.js (серверные/отдельные рантаймы) / C#, Python, Node.js (server / standalone runtimes)
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