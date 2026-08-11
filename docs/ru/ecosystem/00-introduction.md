# GCore Ecosystem v0.1

GCore Ecosystem — developer infrastructure вокруг небольшого фундамента `gc_core`.
Core владеет player lifecycle. Независимые resources владеют gameplay domains и
общаются через документированные Public API.

```text
                         gc_core / Public API v1
                                  ▲
                 ┌────────────────┼────────────────┐
                 │                │                │
            gc_identity      gc_example       third-party

             optional convenience        optional diagnostics
                    gc_sdk                  gc_ecosystem
```

`gc_sdk` убирает небольшой повторяемый compatibility boilerplate. `gc_ecosystem`
наблюдает metadata установленных модулей и сообщает совместимость. Они не нужны
для запуска `gc_core`, не proxy-ят gameplay и не владеют player state.

Development flow:

```text
create-module → domain logic → conformance → tests → package → artifact
```

Начните с [Module Standard v1](module-standard.md), затем откройте
[Создание модуля](creating-module.md). Проверенные результаты реализации находятся в
[отчёте Ecosystem v0.1](ecosystem-v0.1-report.md).
