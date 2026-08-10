# gc_example

`gc_example` — минимальный reference module GCore. Он показывает, как независимый
resource проверяет совместимость Core API, читает отделённый DTO игрока,
проверяет server-owned lifecycle и отправляет уведомление без доступа к
внутренностям `gc_core`.

## Установка и запуск

Resource находится рядом с `gc_core` и объявляет `dependency 'gc_core'`. После
`ensure gc_core` добавьте:

```cfg
ensure gc_example
```

Подключённый игрок выполняет `/gcexample`. Сервер проверяет
`CanUseGameplayFeatures(source)`, получает свежий Public Session DTO и вызывает
`NotifyPlayer`. В server console эта же команда выводит совместимые версии core.

## Демонстрируемый контракт

- Требуется Core API `>= 1`, а не точная resource version ядра.
- Реализация server-only: клиент не передаёт authoritative payload.
- Используются только документированные exports `gc_core`.
- После старта `gc_core` совместимость проверяется заново; при недоступном core
  операция безопасно отклоняется.
- Модуль не содержит аккаунты, персонажей, деньги, inventory и игровые системы.

## Тесты

```sh
lua tools/module_test_harness.lua . gc_example
```

Тесты проверяют compatibility, stopped core, gameplay gate, Public DTO,
notification и регистрацию команды. См. [Module Contract](../../../docs/ru/module-contract.md).
