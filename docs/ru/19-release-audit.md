# Аудит релиза 0.1.2-alpha

| Область | Статус | Проверка |
| --- | --- | --- |
| Repository layout | Готово | один tracked gc_core, runtime/txData игнорируются |
| Runtime context | Готово | `GCRuntime`, raw native только в одном файле |
| Versions | Готово | resource `0.1.2-alpha`, API 1, protocol 1 |
| Handshake | Готово | общий validator, strict protocol |
| Recovery | Готово | server ped authority, timeout |
| Spawn decision | Готово | source/session/TTL/one-time checks |
| Spawn verification | Готово | entity/owner/model/health/position |
| Retry | Готово | новый ID/model, bounded attempts/fallback |
| IDs/random | Готово | correlation IDs отделены от ped random |
| Payloads | Готово | exact schema, bounds, finite numbers |
| Rate limits | Готово | action-specific windows + violation decay |
| State machine | Готово | production mutation через `GCStates.Set` |
| API contracts | Готово | detached DTO, explicit version exports |
| Test isolation | Готово | opt-in loader, production не исполняет tests |
| Test coverage | Готово | unit/integration/security/runtime |
| CI | Готово | syntax, harness, versions, links, forbidden patterns |
| Documentation | Готово | RU/EN contracts, security, migration, diagrams |
| txAdmin | Готово | official artifact, OneSync, junction, clean startup |
| Remaining boundary | Ручной тест | подключение реального FiveM клиента и network ownership |

Локальный FXServer smoke test подтверждает загрузку resource и встроенные тесты.
Последняя граница, которую нельзя полноценно эмулировать без игрового клиента, —
фактическая миграция network ownership/координат во время подключения. Серверный
код в этой точке fail-closed и использует bounded retry/timeout.
