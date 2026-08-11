# GCore Mail Service

Небольшая stateless-служба доставки писем для `gc_identity`. Она принимает от
GCore только данные оформления письма по localhost HTTP и отправляет HTML +
plain text через обычный SMTP. Служба не создаёт и не проверяет коды, не знает
об аккаунтах, license/IP и не имеет базы данных.

## Схема

```text
gc_identity (владелец challenge и решения об авторизации)
  -> HTTP 127.0.0.1 + X-GCore-Mail-Token
  -> GCore Mail Service
  -> generic SMTP
  -> Mailpit для разработки / SMTP provider в production
```

HTTP server разрешает bind только на `127.0.0.1`. Для `POST` действуют лимит
тела 8 KiB, constant-time проверка token, строгая schema, дополнительный rate
limit и bounded SMTP timeouts. Сервис ничего не хранит.

## Установка и запуск

Требуются Node.js 22 LTS+, pnpm 11 и SMTP server.

```powershell
cd C:\Gcore\mail-service
pnpm install --frozen-lockfile
Copy-Item .env.example .env
pnpm dev
```

В `.env` задайте случайный `MAIL_SERVICE_TOKEN` длиной минимум 32 символа.
Файл `.env` игнорируется Git. Для production можно выполнить `pnpm build` и
`pnpm start`.

Health check:

```powershell
Invoke-RestMethod http://127.0.0.1:8091/health
```

Endpoint `POST /v1/email/verification` требует `X-GCore-Mail-Token` и принимает
ровно `{ email, code, type }`, где code — шесть цифр, а type — `registration`
или `authentication`. HTTP 202 означает принятие письма SMTP-сервером, но не
гарантирует доставку во входящие.

## Mailpit и настоящий SMTP

Для разработки запустите Mailpit: SMTP `127.0.0.1:1025`, UI обычно
`http://127.0.0.1:8025`. Авторизация SMTP не нужна. Для настоящей доставки
измените только `.env`: host, port, secure, пару user/password и sender.
Доставляемость также зависит от SPF, DKIM, DMARC и политики получателя.

## Настройка FXServer

До `ensure gc_identity` задайте:

```cfg
set gcore_mail_service_url "http://127.0.0.1:8091"
set gcore_mail_token "тот-же-длинный-token-что-в-mail-service"
set gcore_identity_challenge_secret "отдельный-секрет-минимум-32-символа"
set gcore_ip_fingerprint_secret "ещё-один-отдельный-секрет-минимум-32-символа"
```

Секреты должны отличаться. Смена IP secret делает старые fingerprints
несопоставимыми, поэтому при следующем входе потребуется email code. При отказе
почты same-IP пользователь может войти, но регистрация и new-IP flow всегда
закрываются безопасно.

## Проверка и диагностика

```powershell
pnpm lint
pnpm test
pnpm build
```

- `MAIL-CONFIG-UNSAFE-HOST`: разрешён только `127.0.0.1`.
- `MAIL-UNAUTHORIZED`: tokens FXServer и сервиса не совпадают.
- `MAIL-SMTP-FAILED`: проверьте SMTP/TLS/auth/Mailpit/timeouts.

Логи маскируют email и не содержат code, token, SMTP credentials, FiveM
identifier, account ID или IP.
