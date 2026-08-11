# Тестирование и conformance

Portable проверки из repository root:

```text
lua tools/module_conformance.lua path/to/module
lua tools/module_conformance.lua path/to/module --json
lua tools/module_test_harness.lua . path/to/module
lua tools/run-module-suite.lua .
lua tools/tests/run.lua .
lua tools/generate-ecosystem-docs.lua . --check
```

Exit codes conformance: `0` PASS, `1` contract failure, `2` invalid invocation.
Tool declaratively разбирает manifest и никогда не выполняет сторонний manifest Lua.
Проверяются metadata/files, SemVer/version source, dependencies, contract/API,
reserved fields, private core access и unknown Core API exports.

Каждый production module владеет подходящими boundary unit, integration,
security/restart и API contract tests. Модуль с `ui_page` и `web/package.json`
автоматически попадает в CI install/test/build и проверку committed `dist`. Модуль
без NUI не получает frontend job.

Fixtures покрывают valid/malformed third-party modules, missing manifest/metadata,
private core access, unknown export, dependency declaration и missing docs. Отдельные
registry tests покрывают runtime missing/stopped dependencies, API incompatibility,
cycles, DTO isolation и start/stop refresh.
