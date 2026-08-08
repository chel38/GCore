# Политика совместимости API

Core API Version: `1` — **Stable for module development**.

| Тип изменения | Политика |
| --- | --- |
| Patch release (`0.1.x`) | Без breaking changes Public API v1. Только fixes, tests, docs и совместимые internals. |
| Minor pre-1.0 release (`0.x.0`) | Разрешены additive API v1 methods/fields; существующие контракты сохраняются. |
| Breaking Public API change | Увеличить Core API version и опубликовать migration notes. По возможности оставить compatibility adapter. |
| Breaking network contract | Увеличить protocol version; одного resource version недостаточно. |
| Internal refactor | API/protocol не повышаются, если public behavior и payload contracts совместимы. |

Модули проверяют `GetApiVersion()`, а не точный `GetVersionString()`. Deprecation
документируется до удаления. Breaking change нельзя скрывать в patch release.
