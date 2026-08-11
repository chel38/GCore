# Зависимости модулей

Каждый обязательный GCore module имеет две согласованные декларации:

```lua
dependency 'gc_identity'
gcore_requires 'gc_identity:api>=1'
```

FiveM declaration задаёт start order и runtime dependency. GCore declaration
задаёт требуемый Public API contract. Conformance checker отклоняет required
GCore edge без соответствующей FiveM dependency.

Для core используется специальная форма:

```lua
dependency 'gc_core'
gcore_requires_core_api '1'
```

Нельзя использовать Core protocol или точную resource version `0.x` как module
dependency.

Optional integration объявляется только через `gcore_optional`; её отсутствие не
ошибка и не останавливает resource. Missing/stopped required module или слишком
старая API version делает consumer incompatible. Self-dependency и directed cycle
запрещены.

Registry только сообщает эти факты: он не останавливает, не перезапускает, не
скачивает и не proxy-ит модули. Module вызывает Public API dependency напрямую.
