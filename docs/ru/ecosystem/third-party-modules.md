# Сторонние модули

Third-party FiveM resource участвует в ecosystem через `gcore_module 'yes'` и
Module Standard v1. Официальный префикс `gc_*` ему не нужен. Проверка:

```text
lua tools/module_conformance.lua /path/to/vendor_resource --json
```

Conformance подтверждает structure, известные Core API, dependency declarations и
version compatibility. Local registry сообщает эти metadata и runtime resource state.
Ни один из них не доказывает, что code safe, trusted, reviewed или не содержит
вредоносное поведение.

Установка стороннего FiveM resource запускает его server/client code. До `ensure`
проверьте source, permissions, network events, NUI callbacks, DB migrations, HTTP
calls и package checksum. В GCore v0.1 нет badge `Verified`/`Trusted`/`Safe`, remote
installer/updater и remote Lua execution.

Capabilities информационные. Для security-sensitive работы используйте explicit
dependency на документированный API, а не automatic provider selection.
