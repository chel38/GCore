# Full gc_identity NUI and lifecycle audit

Date: 2026-08-11

Baseline: `2486af064a77f234a392eda8215e6fa113ed1397`

Result: `gc_identity 0.4.1-alpha`, Identity API 1, protocol 3.

## NUI inventory

| Resource | NUI | Purpose | Fullscreen | Focus | Lifecycle |
| --- | --- | --- | --- | --- | --- |
| `gc_identity` | Yes | Registration, email/new-IP verification, spawn transition, character selection | Yes | Yes, non-ready only | Active |
| `gc_core` | No | Loading and server-authoritative spawn | — | No | Active |
| `gc_example` | No | Reference module | — | No | Active |

The repository contains exactly one `ui_page`:
`gc_identity/web/dist/index.html`. Vite uses `base: './'`; the HTML and hashed
JS/CSS assets exist and are included by `fxmanifest.lua`. There are no external
CDNs, videos, WebGL surfaces, or remote images.

## Root causes found

1. The old shell ended in a translucent `linear-gradient(... / .94, ... /
   .96)`, allowing the GTA renderer to leak through mandatory pre-spawn UI.
2. The shell used only `min-height: 100vh`; it was not fixed through
   `position: fixed; inset: 0`, so coverage depended on document layout.
3. Every view rendered its own fullscreen `<section>`, so transitions had no
   single visual-layer cleanup invariant.
4. The card and exit overlay used `backdrop-filter`. Fullscreen CEF compositor
   layers can produce black rectangle/strip artifacts.
5. The countdown used a permanent `setInterval`, including while the NUI was
   hidden.
6. Lua managed focus/freeze in separate paths and did not guarantee
   `SetNuiFocusKeepInput(false)` across stop, exit, and failure paths.
7. The loading screen closed after JS-ready but before a browser frame actually
   contained the opaque shell, leaving a world-flash race.

## Architecture after the fix

```text
transparent HTML/body/#app + hidden root
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
empty DOM + hidden transparent root
focus false + keepInput false + identity freeze released
```

`IdentityShell` is `position: fixed`, `inset: 0`, `100vw × 100vh`, with an opaque
`#030a07` base. The grid and green glows are lightweight CSS layers above that
base; the world cannot be visible below them. `html`, `body`, and `#app` always
remain transparent. A hidden root uses `display: none`, not opacity alone.

`backdrop-filter`, `will-change`, fullscreen blur, oversized shadows, and
permanent GPU layers were removed. Short fade/translate animations respect
`prefers-reduced-motion`.

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

At most one `IdentityView` exists at a time. Before mounting a new view, the app
idempotently removes old DOM, timers, and pending animation frames. An unknown
server state fails closed into a controlled fatal screen instead of preserving a
stale overlay.

The verification countdown exists only on the two verification views and is
removed on every transition, reset, or destroy. There is no permanent frontend
polling.

## Loading and spawn handoff

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

The FiveM loading screen therefore remains until the browser frame is covered by
the shell. No fixed `Wait(1000)` synchronization exists.

After finalization the server moves identity to `spawn_releasing`; the same shell
shows “Entering the server…”. Core remains the sole owner of spawn, entity
verification, and retry. After the server-authoritative spawn hook:

- a persisted selected character reaches `ready`, performs full cleanup, and
  reveals the world;
- when no character exists, the intentional character view stays inside the
  same opaque shell until selection. This is post-spawn identity domain, not a
  stale pre-spawn overlay; Core has allowed the world, but the UI intentionally
  keeps it covered.

## Cleanup and focus

Lua `GCIdentityNuiController.Cleanup(reason, sendReset)` centrally:

- cancels the control-restriction generation;
- calls `SetNuiFocus(false, false)`;
- calls `SetNuiFocusKeepInput(false)`;
- releases the identity-owned freeze from both the captured handle and the
  current player ped when `SetPlayerModel` replaced the entity during handoff;
- sends frontend `reset` while JS is available.

Cleanup runs on `ready`, explicit exit, client failure, resource start, resource
stop, and `gc_core` stop. Repeated calls are safe. Frontend reset clears the
snapshot, form draft, errors, exit modal, countdown, pending frame, and all DOM.

## Registration and authentication UX

- One card progresses through name/email, code, verified summary, and spawn
  transition; no previous card remains hidden below it.
- Name/email drafts survive pending requests and email correction.
- Email uses `type=email`, `autocomplete=email`, and `spellcheck=false`.
- Code paste is supported, non-digits are removed, and length is capped at six;
  Enter submits the normal form.
- Errors remain local, actions disable while pending, and resend timing remains
  server-authoritative.
- The new-IP screen exposes only masked email and a user-facing explanation, not
  raw IP/fingerprint data.
- All new strings have RU/EN variants; keyboard focus is visible and Escape opens
  an exit confirmation.

## Responsive contract

The shell is aspect-ratio independent. Content scroll stays inside a safe
viewport and horizontal scroll is prohibited. Card width is capped, supporting
1280×720, 1366×768, 1920×1080, 2560×1440, 3840×2160, and ultrawide layouts. A
low-height media query reduces spacing and typography without weakening
fullscreen coverage.

## Regression protection

Frontend tests cover:

- transparent hidden root with no overlay;
- one opaque fixed shell for registration/auth;
- exactly one active view;
- reset/unmount and unknown-state fail-safe;
- spawn transition and ready cleanup;
- bounded verification timer;
- code paste sanitization, explicit finalization, and exit cleanup;
- `presented` ACK only after a browser frame.

Lua runtime tests cover focus/freeze/keepInput symmetry, lost/delayed NUI-ready,
presented loading handoff, duplicate ACK, resource stop, duplicate cleanup,
model-replacement freeze recovery, and exit. The repository validator prevents
regressions in fixed/opaque shell coverage, `backdrop-filter`, and permanent
`setInterval` usage.

## Diagnostics

Temporarily enable `GCIdentityConfig.client.debug` and inspect
`[GC][IDENTITY][CLIENT]` for JS-ready, view-presented, loading handoff, focus, and
cleanup reason. Email, code, identifier, raw IP, token, and connection string are
never logged.
