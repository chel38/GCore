# Glossary / Глоссарий

## Terms

| Term | RU | EN |
| ---- | -- | -- |
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

## Abbreviations

| Abbreviation | Expansion |
| ------------ | --------- |
| `GC` | GreenCore |
| `API` | Application Programming Interface |
| `SDK` | Software Development Kit |
| `RU` | Russian language |
| `EN` | English language |
| `ID` | Identifier |
| `IP` | Internet Protocol |
| `UUID` | Universally Unique Identifier |

## Key concepts

### Server is the source of truth

The server makes all decisions.
The client only performs allowed actions.

### Client requests → Server decides

The client can only request an action.
The server decides whether to allow it.

### Core runtime in Lua; NUI — TypeScript + Tailwind

The `gc_core` runtime (server, client, shared, config, locales, tests) is written in Lua 5.4.
Further development and adding NUI will use TypeScript + Tailwind CSS
and other modern FiveM-supported technologies.
C# will not be used.
NUI is not used in `gc_core` at this stage.