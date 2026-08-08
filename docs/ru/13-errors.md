# Ошибки

`shared/errors.lua` — единый registry. Каждая запись содержит `localeKey`,
`severity` и `public`. Клиент может отправить через `reportClientError` только код,
который есть в registry; произвольные строки отклоняются.

| Семейство | Значение |
| --- | --- |
| `GC-PAYLOAD-TYPE/SCHEMA/NUMBER-*` | неверный тип, лишнее поле, NaN/Infinity |
| `GC-PROTOCOL-MISMATCH-*` | protocol не совпадает |
| `GC-RATE-LIMIT-*` | action limit превышен |
| `GC-SPAWN-DECISION-*` | отсутствует/истёк/потреблён decision |
| `GC-SPAWN-OWNER/STATE-*` | чужая session/source или неверный state |
| `GC-SPAWN-VERIFY-*` | server entity/model/position не подтвердились |
| `GC-SPAWN-PED-*` | ped config/load/exhaustion |
| `GC-RESYNC-*` | recovery/resync lifecycle |

Не передавайте внутренний код игроку автоматически. Используйте `GCErrors.IsPublic`
и локализованный `localeKey`. В лог добавляйте безопасный контекст без полного
identifier, license key или client-supplied текста.

Перейдите к [устранению неполадок](14-troubleshooting.md).
