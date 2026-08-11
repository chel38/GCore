# Полный аудит NUI и lifecycle gc_identity

Дата: 2026-08-11

Baseline: `2486af064a77f234a392eda8215e6fa113ed1397`

Результат: `gc_identity 0.4.1-alpha`, Identity API 1, protocol 3.

## NUI inventory

| Resource | NUI | Назначение | Fullscreen | Focus | Lifecycle |
| --- | --- | --- | --- | --- | --- |
| `gc_identity` | Да | Registration, email/new-IP verification, spawn transition, character selection | Да | Да, только non-ready | Active |
| `gc_core` | Нет | Loading и server-authoritative spawn | — | Нет | Active |
| `gc_example` | Нет | Reference module | — | Нет | Active |

В репозитории найден ровно один `ui_page`: `gc_identity/web/dist/index.html`.
Vite использует `base: './'`; HTML и hashed JS/CSS assets существуют и включены
в `fxmanifest.lua`. Внешних CDN, video, WebGL и удалённых изображений нет.

## Найденные причины визуальных дефектов

1. Старый shell заканчивался полупрозрачным `linear-gradient(... / .94, ... /
   .96)`. Это позволяло renderer GTA просвечивать за обязательным pre-spawn UI.
2. Shell имел только `min-height: 100vh`, но не был `position: fixed; inset: 0`.
   Геометрия зависела от layout document/root.
3. Каждый view самостоятельно создавал fullscreen `<section>`, поэтому cleanup
   не гарантировал единственный visual layer при переходе состояния.
4. Card и exit overlay использовали `backdrop-filter`. Fullscreen CEF compositor
   layers способны давать black rectangle/strip artifacts.
5. Countdown использовал постоянный `setInterval`, даже когда NUI был hidden.
6. Lua отдельно управлял focus/freeze и не гарантировал
   `SetNuiFocusKeepInput(false)` во всех stop/exit/failure paths.
7. Loading screen закрывался после JS-ready, но до фактического browser-frame,
   содержащего непрозрачный shell. Между ними существовал world-flash race.

## Архитектура после исправления

```text
transparent HTML/body/#app + root hidden
        ↓ authoritative snapshot
resolve exactly one IdentityView
        ↓
one fixed opaque IdentityShell
        ├── CSS GCore background
        ├── one content card
        ├── optional exit confirmation
        └── footer/brand
        ↓ ready/reset/stop/exit
cleanupVisualState + GCIdentityNuiController.Cleanup
        ↓
DOM empty + root hidden + transparent
focus false + keepInput false + identity freeze released
```

`IdentityShell` имеет `position: fixed`, `inset: 0`, `100vw × 100vh` и
непрозрачный `#030a07` base. Grid и зелёные glow — только лёгкие CSS layers над
этой базой; под ними не может быть виден мир. `html`, `body` и `#app` всегда
transparent. При hidden root используется `display: none`, а не только opacity.

`backdrop-filter`, `will-change`, fullscreen blur, гигантские shadows и
постоянные GPU layers удалены. Короткие fade/translate animations отключаются
через `prefers-reduced-motion`.

## Frontend state machine

```text
hidden
loading
registration
registration-verification
login-verification
registration-verified
profile-completion
spawn-transition
characters
fatal-error
```

В каждый момент существует не более одного `IdentityView`. Перед mount нового
view выполняется idempotent cleanup старого DOM, timer и pending animation frame.
Неизвестное server state fail-closed переводится в controlled fatal screen, а не
оставляет предыдущий overlay.

Verification countdown создаётся только на двух verification views и удаляется
при любом переходе/reset/destroy. Permanent frontend polling отсутствует.

## Loading и spawn handoff

```text
NUI JS initialized
  → ready callback
  → Lua RESET
  → authoritative full snapshot
  → frontend mounts opaque IdentityShell
  → requestAnimationFrame
  → presented callback
  → Lua idempotently calls ShutdownLoadingScreen/Nui
```

Таким образом системный FiveM loading не закрывается, пока browser frame ещё не
перекрыт shell. Никаких `Wait(1000)` для синхронизации нет.

После финализации сервер переводит identity в `spawn_releasing`; тот же shell
показывает «Входим на сервер…». Core остаётся единственным владельцем spawn,
entity verification и retry. После server-authoritative spawn hook:

- выбранный persisted character приводит к `ready`, полному cleanup и показу мира;
- если персонажа ещё нет, intentional character view остаётся внутри того же
  opaque shell до выбора. Это post-spawn identity domain, а не stale pre-spawn
  overlay; мир уже разрешён Core, но всё ещё намеренно закрыт UI.

## Cleanup и focus

Lua `GCIdentityNuiController.Cleanup(reason, sendReset)` централизованно:

- останавливает control restriction generation;
- вызывает `SetNuiFocus(false, false)`;
- вызывает `SetNuiFocusKeepInput(false)`;
- снимает принадлежащий identity freeze и со сохранённого handle, и с текущего
  player PED, если `SetPlayerModel` заменил entity во время handoff;
- отправляет frontend `reset`, когда JS доступен.

Cleanup вызывается при `ready`, explicit exit, client failure, resource start,
resource stop и `gc_core` stop. Повторные вызовы безопасны. Frontend reset очищает
snapshot, draft, error, exit modal, countdown, pending frame и весь DOM.

## Registration и authentication UX

- Один card последовательно показывает имя/email, code, verified summary и spawn
  transition; скрытых предыдущих cards нет.
- Имя и email draft сохраняются во время pending request и email correction.
- Email использует `type=email`, `autocomplete=email`, `spellcheck=false`.
- Code принимает paste, удаляет нецифровые символы и ограничивается шестью
  цифрами; Enter отправляет обычную form.
- Ошибки локальны, действия блокируются на время pending request, resend timer
  остаётся server-authoritative.
- New-IP экран показывает только masked email и пользовательское объяснение без
  raw IP/fingerprint.
- Все новые строки имеют RU/EN варианты; keyboard focus видим, ESC открывает
  подтверждение выхода.

## Responsive contract

Shell не зависит от aspect ratio. Content scroll находится внутри safe viewport;
горизонтального scroll нет. Card ограничен max-width, поэтому одинаково работает
на 1280×720, 1366×768, 1920×1080, 2560×1440, 3840×2160 и ultrawide. Low-height
media query уменьшает padding и typography, не меняя fullscreen coverage.

## Regression protection

Frontend tests проверяют:

- transparent hidden root без overlay;
- один opaque fixed shell для registration/auth;
- ровно один active view;
- reset/unmount и unknown-state fail-safe;
- spawn transition и ready cleanup;
- bounded verification timer;
- code paste sanitization, explicit finalize и exit cleanup;
- `presented` ACK только после browser frame.

Lua runtime tests проверяют focus/freeze/keepInput symmetry, lost/delayed NUI-ready,
presented loading handoff, duplicate ACK, resource stop, duplicate cleanup,
model-replacement freeze recovery и exit. Repository validator запрещает потерю
fixed/opaque shell contract, `backdrop-filter` и постоянный `setInterval`.

## Диагностика

Временно включите `GCIdentityConfig.client.debug` и ищите категории
`[GC][IDENTITY][CLIENT]`: JS-ready, view presented, loading handoff, focus и
cleanup reason. Email, code, identifier, raw IP, token и connection string не
логируются.
