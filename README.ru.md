# GCore / GreenCore

[Русский](README.ru.md) | [English](README.en.md)

> **GreenCore использует Lua 5.4 для всей серверной и клиентской логики.**
> **GreenCore uses Lua 5.4 for all server-side and client-side logic.**

**Логика — только Lua. NUI — TypeScript + Tailwind. / Lua for logic. TypeScript + Tailwind for NUI.**

---

## Назначение

GreenCore — это минимальный модульный движок для FiveM, написанный исключительно на Lua 5.4.
Он отвечает за безопасный жизненный цикл игрока:

```text
Подключение → Проверку → Сессию → Готовность клиента → Спавн → Подтверждение → Отключение
```

## Статус разработки

**0.1.0** — первая рабочая версия.

## Возможности версии

- Проверка подключения через deferrals
- Проверка идентификаторов
- Временные Lua-сессии в памяти
- Управление состояниями игрока
- Rate limit сетевых событий
- Серверное решение о спавне
- Клиентский спавн на Lua natives
- Публичный API v1
- Локализация RU|EN
- Диагностический режим

## Ограничения версии

Первая версия **не** включает:

- Регистрацию, аккаунты, персонажей
- Базу данных
- Деньги, инвентарь, транспорт
- Чат, HUD, админ-панель

## Требования

- FXServer (актуальная версия)
- Windows или Linux
- OneSync
- Lua 5.4 (включён через `lua54 'yes'`)

## Установка

1. Откройте папку ресурсов FiveM-сервера.
2. Создайте папку `[greencore]`.
3. Поместите `gc_core` в эту папку.
4. Откройте `server.cfg`.
5. Добавьте:

```cfg
ensure gc_core
```

6. Сохраните `server.cfg`.
7. Запустите FXServer.
8. Найдите сообщение:

```text
[GreenCore] [INFO] gc_core 0.1.0 started successfully
```

## Конфигурация

Вся конфигурация хранится в Lua-файлах в `resources/[greencore]/gc_core/config/`.

## Структура

```text
resources/[greencore]/gc_core/
├── fxmanifest.lua
├── config/       # Lua-конфигурация
├── locales/      # Lua-локализация
├── shared/       # Общий код
├── server/       # Серверная логика
├── client/       # Клиентская логика
└── tests/        # Lua-тесты
```

## API

Серверные exports:

| Export                   | Возвращает     | Назначение                |
| ------------------------ | -------------- | ------------------------- |
| `GetApiVersion`          | number         | Версия API                |
| `GetVersion`             | table          | Версия `gc_core`          |
| `IsPlayerConnected`      | boolean        | Проверяет сессию          |
| `IsPlayerReady`          | boolean        | Проверяет готовность      |
| `IsPlayerSpawned`        | boolean        | Проверяет спавн           |
| `GetPlayerState`         | string или nil | Возвращает состояние      |
| `GetPlayerSession`       | table или nil  | Возвращает копию сессии   |
| `GetPlayerIdentifier`    | string или nil | Возвращает идентификатор  |
| `CanUseGameplayFeatures` | boolean        | Разрешает игровые функции |
| `RequestPlayerSpawn`     | table или nil  | Запрашивает спавн         |
| `NotifyPlayer`           | boolean        | Отправляет уведомление    |
| `NotifyAll`              | boolean        | Отправляет уведомление всем |

## Документация

- [Документация RU](docs/ru/00-introduction.md)
- [Documentation EN](docs/en/00-introduction.md)
- [Диаграммы](docs/diagrams/architecture.md)

## Тестирование

Все тесты написаны на Lua:

```text
resources/[greencore]/gc_core/tests/
```

## Безопасность

- Сервер является источником истины
- Клиент никогда не доверяется
- Все payload проверяются
- Идентификаторы маскируются
- Rate limit на все события

## Лицензия

См. [LICENSE.txt](LICENSE.txt).