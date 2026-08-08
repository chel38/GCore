# Глоссарий / Glossary

## Термины

| Термин | RU | EN |
| ------ | -- | -- |
| `source` | Идентификатор игрока на сервере | Player identifier on the server |
| `session` | Временная карточка игрока | Temporary player card |
| `state` | Этап жизненного цикла игрока | Player lifecycle stage |
| `spawn decision` | Решение сервера о спавне | Server spawn decision |
| `deferrals` | Механизм отложенного подключения | Deferred connection mechanism |
| `payload` | Данные сетевого события | Network event data |
| `rate limit` | Ограничение частоты запросов | Request frequency limit |
| `export` | Публичная функция ресурса | Public resource function |
| `namespace` | Пространство имён событий | Event namespace |
| `natives` | Встроенные функции FiveM | Built-in FiveM functions |
| `ped` | Игровой персонаж | Game character |
| `model` | Модель персонажа | Character model |
| `heading` | Направление взгляда | View direction |
| `collision` | Физическая коллизия | Physical collision |
| `license` | Идентификатор лицензии FiveM | FiveM license identifier |

## Сокращения

| Сокращение | Расшифровка |
| ---------- | ----------- |
| `GC` | GreenCore |
| `API` | Application Programming Interface |
| `SDK` | Software Development Kit |
| `RU` | Русский язык |
| `EN` | Английский язык |
| `ID` | Идентификатор |
| `IP` | Internet Protocol |
| `UUID` | Universally Unique Identifier |

## Ключевые понятия

### Сервер является источником истины

Сервер принимает все решения.
Клиент только выполняет разрешённые действия.

### Клиент просит → Сервер решает

Клиент может только запросить действие.
Сервер решает, разрешить его или нет.

### Runtime ядра — Lua; NUI — TypeScript + Tailwind

Runtime `gc_core` (сервер, клиент, shared, config, locales, tests) написан на Lua 5.4.
Дальнейшая разработка и добавление NUI будут использовать TypeScript + Tailwind CSS
и другие современные технологии, поддерживаемые FiveM.
C# не будет использоваться.
На данном этапе NUI в `gc_core` не используется.