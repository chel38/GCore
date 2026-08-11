# Аудит NUI и connection lifecycle gc_identity

Дата аудита: 2026-08-11

> Исторический аудит чёрного экрана для `0.2.1-alpha`. Исправления остаются
> актуальными, а новые экраны email-кода и входа с нового IP описаны в документе
> [Подтверждение email](email-verification.md).

Проверенный baseline: `293c92238368a5a8c08eaecccd7b0b610ce5f08d`

Исправленная версия identity: `0.2.1-alpha` (API 1, protocol 1). Core остаётся
`0.1.4-alpha` (API 1, protocol 1).

## Первопричина

FiveM заранее загружает каждый объявленный `ui_page`. Одновременно работали две
ошибки presentation lifecycle:

1. старый frontend при первом mount вызывал `renderLoading()` без snapshot от
   Lua/server и рисовал почти непрозрачный fullscreen shell;
2. production document объявлял `color-scheme: dark`, даже когда root был пуст.
   В реальном FiveM CEF canvas неактивного документа из-за этого оставался чёрным,
   а не становился прозрачным overlay.

Вторая причина изолирована в live runtime: у уже заспавненного игрока одна команда
`ensure gc_identity` возвращала чёрный слой, а `stop gc_identity` снимала его.
Core уже находился в `spawned`, ped существовал в проверенной позиции, screen был
faded in. Это доказало, что оставшаяся причина находилась не в spawn/fade.

Исправление убирает принудительную тёмную цветовую схему документа и вводит явный
`hidden` lifecycle DOM root. Root показывается только когда authoritative snapshot
или terminal diagnostic действительно содержит view. Ранние core/database races
и ошибки JavaScript/Lua также получают bounded recovery вместо вечного пустого
overlay.

Assets не были причиной: `vite.config.ts` уже содержал `base: './'`, built HTML
ссылался на относительные hashed assets, все ссылки существовали в `web/dist`, а
real FiveM log не содержал exception из bundle.

## Фактический connection path

```text
FiveM connection / deferrals
  → загрузка gc_core client scripts
  → bounded clientReady hello
  → server connectionAccepted
  → server-authoritative spawn decision
  → client fade-out, model/collision/position, fade-in
  → server entity verification и spawnConfirmed
  → gc_core один раз закрывает FiveM loading screens
  → gc_identity находит trusted identifier
  → ready identity остаётся визуально скрытым
     ИЛИ registration/character state открывает NUI
```

`gc_core` владеет fades, loading-screen shutdown, spawn decisions и spawn
verification. `gc_identity` владеет только NUI focus/presentation restriction и
identity state. Аудит не нашёл screen-fade/loading native в identity и не нашёл
unbounded wait в core.

## NUI lifecycle после исправления

```text
HTML loaded → root hidden / прозрачный document canvas / без focus
JavaScript initialized → NUI ready callback
Lua сохраняет или уже имеет authoritative snapshot
  ├─ state=ready → replay snapshot, NUI пустой, focus/freeze сняты
  └─ state!=ready → replay snapshot, UI показан, focus/freeze выданы

transient core/DB/bootstrap race → bounded silent hello retry
terminal DB/hello failure → diagnostic retry/exit view
нет JavaScript ready ACK → снять focus/freeze → validated server disconnect
resource stop → отменить watchdog → очистить view → снять focus/freeze
```

Fixed sleep не используется как механизм синхронизации. Все waits принадлежат
bounded retry/deadline watchdog; readiness определяется callbacks и authoritative
snapshots.

## Failure recovery и диагностика

| Code | Значение | Результат |
| --- | --- | --- |
| `GC-IDENTITY-HELLO-TIMEOUT` | authoritative ответ не пришёл за bounded hello window | видимый retry/exit view |
| `GC-IDENTITY-DATABASE-UNAVAILABLE` | startup завершился с degraded database | server rejection и видимая ошибка |
| `GC-IDENTITY-NUI-NOT-READY` | JS bundle не вызвал ready вовремя | focus/freeze сняты, controlled disconnect |
| `GC-IDENTITY-CLIENT-FAILURE-INVALID` | forged/unapproved client failure code | reject без privileged effect |

Transient `CORE-UNAVAILABLE`, `PLAYER-NOT-CONNECTED`, `PLAYER-NOT-READY`,
`OPERATION-IN-PROGRESS` и non-degraded database bootstrap не показывают terminal
error. Их повторяет существующий bounded hello loop.

Для диагностики временно включите `GCIdentityConfig.client.debug` и ищите в FiveM
client log категорию `[GC][IDENTITY][CLIENT]`. Нельзя логировать connection string,
email, identifiers, passwords или tokens. Password authentication в этой версии
отключена: password field и password storage отсутствуют.

## Build и manifest contract

- `ui_page`: `web/dist/index.html`;
- manifest files: built HTML и `web/dist/assets/*`;
- Vite base: `./`;
- при standalone browser development bridge inert, если отсутствует
  `GetParentResourceName`;
- CI пересобирает NUI и падает, если committed `dist` отличается.

## Regression coverage

Automated tests проверяют скрытый initial mount, отсутствие flash у ready player,
authoritative snapshot replay после JS ACK, симметричные focus/freeze, bounded
hello timeout, transient core startup, degraded database response, server reject,
cleanup сломанного NUI bundle, controlled disconnect allowlist, restart recovery,
reconnect, две изолированные server-side player sessions, spawn failure/retry и
core loading completion.

| Сценарий | Граница | Результат |
| --- | --- | --- |
| returning player и чистый reconnect | real FXServer + один FiveM client | PASS |
| `restart gc_identity` во время spawned | real FXServer + один FiveM client | PASS |
| `restart gc_core` + повторный ensure зависимого ресурса | real FXServer + один FiveM client | PASS |
| новая identity от регистрации до ready | production Lua path в module harness + NUI unit path | PASS |
| database unavailable / degraded | production service/events с mock границы БД | PASS |
| медленный database/bootstrap race | production recovery path с deferred boundary | PASS |
| delayed или missing NUI ready | production Lua client path в runtime harness | PASS |
| server rejection и spawn failure | module/core integration harnesses | PASS |
| две одновременные identity sessions | production service path в integration harness | PASS |
| два отдельных real FiveM clients | не запускалось | NOT RUN |

## Оставшееся архитектурное наблюдение

В проверенной API v1 architecture core spawn сейчас завершается независимо от
identity readiness; `CanUseGameplayFeatures` означает только core state `spawned`.
Это не было причиной чёрного экрана и намеренно не изменено minimal bug fix.
Будущий identity-before-gameplay gate должен быть generic versioned contract между
core/modules, а не private зависимостью core от `gc_identity`.

## Runtime gate

Исправленный production build проверен в FXServer build b3751 с MariaDB и
oxmysql:

- существующий игрок выполнил чистый disconnect/reconnect и вошёл в gameplay;
- `restart gc_identity` во время spawned сохранил видимый игровой мир;
- `restart gc_core` с обязательным последующим `ensure gc_identity` восстановил
  spawned игрока, NUI остался прозрачным;
- live FiveM log зафиксировал `state=ready` без exception из NUI bundle;
- до исправления document canvas отдельные stop/start только `gc_identity`
  воспроизводили проблему, после исправления — больше нет.

Регистрация нового аккаунта, несколько отдельных real clients и искусственная
задержка реальной БД не выполнялись как destructive/multi-client live tests; их
production boundaries покрыты автоматическими module/runtime suites.
