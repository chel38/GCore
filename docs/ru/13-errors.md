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
| `GC-SPAWN-ENTITY-*` | отсутствующая или мёртвая server entity |
| `GC-SPAWN-OWNER-MISMATCH` | network owner не равен player source |
| `GC-SPAWN-MODEL/POSITION-MISMATCH` | snapshot не совпал с server decision |
| `GC-SPAWN-SESSION-CHANGED` | async verification transaction отменена |
| `GC-SPAWN-VERIFY-*` | bounded server verification failure/timeout |
| `GC-SPAWN-PED-*` | ped config/load/exhaustion |
| `GC-RECOVERY-*`, `GC-RESYNC-*` | recovery timeout/stale/lifecycle diagnostics |

Не передавайте внутренний код игроку автоматически. Используйте `GCErrors.IsPublic`
и локализованный `localeKey`. В лог добавляйте безопасный контекст без полного
identifier, license key или client-supplied текста.

Перейдите к [устранению неполадок](14-troubleshooting.md).
