# GCore / GreenCore

[Русский](README.ru.md) | [English](README.en.md)

> **GreenCore runtime полностью написан на Lua.**
> **GreenCore runtime is 100% Lua.**
>
> Сервер, клиент, shared, config, locales и tests `gc_core` — всё на Lua.
> Дальнейшая разработка и добавление **NUI** будут использовать **TypeScript + Tailwind CSS**
> и другие современные технологии, поддерживаемые FiveM. **C# использоваться не будет.**

---

## Назначение

GreenCore — это минимальный модульный движок для FiveM, написанный исключительно на Lua 5.4.
Он отвечает за безопасный жизненный цикл игрока:

```text
Подключение → Проверку → Сессию → Готовность клиента → Спавн → Подтверждение → Отключение
```

## Статус разработки

**0.1.2-alpha** — стабилизированная early-alpha версия.

## Возможности версии

- Проверка подключения через deferrals
- Проверка идентификаторов
- Временные Lua-сессии в памяти
- Управление состояниями игрока
- Rate limit сетевых событий
- Серверное решение о спавне
- Серверная проверка OneSync ped, ownership, model и позиции
- Recovery без доверия клиентскому `isPedAlive`
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
- NUI (будет добавлен позже) / NUI (will be added later)
- C# (не планируется) / C# (not planned)

> **NUI, когда будет добавлен, будет написан на TypeScript + Tailwind CSS**
> **и других современных технологиях FiveM. C# не будет использоваться.**
> **When NUI is added, it will be written with TypeScript + Tailwind CSS**
> **and other modern FiveM technologies. C# will not be used.**

## Требования

- FXServer (актуальная версия)
- Windows или Linux
- OneSync
- Lua 5.4 (runtime полностью на Lua / runtime is entirely Lua)

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
[GreenCore] [INFO] gc_core 0.1.2-alpha started successfully
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
| `GetProtocolVersion`     | number         | Версия протокола          |
| `GetVersion`             | table          | Версия `gc_core`          |
| `GetVersionString`       | string         | Строка `0.1.2-alpha`      |
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
- [Runtime и txAdmin](docs/ru/18-runtime-txadmin.md)
- [Миграция 0.1.1 → 0.1.2](docs/ru/migration/0.1.1-to-0.1.2.md)

## Тестирование

Все тесты написаны на Lua и загружаются только при явном `gc_runTests 1`:

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
