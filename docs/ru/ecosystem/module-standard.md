# GCore Module Standard v1

Module Standard описывает обычный FiveM resource, который работает с GCore через
публичные контракты. Это структура и compatibility metadata, а не security review,
package signature или permission system.

## Обязательная структура

```text
module/
├── fxmanifest.lua
├── README.md
├── README.ru.md
├── shared/version.lua
├── server/                 # обязателен для production module
└── tests/run.lua
```

`client/` создаётся только для client runtime, `web/` — только для реального NUI.
Server-only module не должен содержать фиктивный client script.

## Обязательные metadata manifest

```lua
fx_version 'cerulean'
game 'gta5'

name 'example_resource'
author 'Example Author'
description 'Краткое фактическое описание'
version '0.1.0-alpha'

gcore_module 'yes'
gcore_contract '1'
gcore_type 'domain'
gcore_requires_core_api '1'

dependency 'gc_core'
```

В contract v1 разрешены типы `reference`, `domain`, `infrastructure`,
`integration`, `developer`.

## Необязательные metadata

- `gcore_api '1'`, если модуль имеет документированный Public API.
- Повторяемый `gcore_capability 'value'` для catalog/diagnostics.
- Повторяемый `gcore_requires 'resource:api>=1'` для обязательного GCore-модуля.
- Повторяемый `gcore_optional 'resource:api>=1'` для optional integration.
- `gcore_repository` и `gcore_license`, когда эти сведения полезны при публикации.

Каждый required `gcore_requires` дублируется FiveM `dependency`. Optional edge не
становится обязательной FiveM dependency. Совместимость с ядром проверяется через
`gcore_requires_core_api`, а не private Core protocol и не точную patch-версию.

## Имена и third-party resources

Префикс `gc_*` зарезервирован для официальных ресурсов GCore. Discovery использует
`gcore_module 'yes'`, поэтому сторонний модуль может иметь другое корректное имя.
Наличие metadata не доказывает, что сторонний код безопасен или trusted.

## Public boundary

- Используйте документированные exports или local server events.
- Не импортируйте `gc_core/server/*` и не читайте `GCSessions`, `GCStates`,
  `GCSpawn` или другие internal tables.
- Возвращайте detached минимальные DTO без secrets.
- Считайте client/NUI payload недоверенным и валидируйте его на сервере.
- После DB/HTTP yield и рестарта dependency повторно проверяйте state.
- Domain state, security, rate limits и business logic остаются внутри модуля.

## Совместимость

Module Contract, resource version, Public API version и network protocol — разные
значения. Contract v1 допускает additive metadata. Breaking standard change требует
новую версию contract.

Перед tests и packaging выполните:

```text
lua tools/module_conformance.lua path/to/module
```
