# Подтверждение email и проверка сетевого адреса в gc_identity

Версия `0.4.0-alpha` сохраняет backward-compatible Identity API v1 и использует
network protocol v3. Код подтверждает email, но намеренно не создаёт account и
не разрешает spawn: после него требуется явная server-validated финализация.

## Владение данными и trust boundary

```text
FiveM license       server export gc_core        primary trusted identity
текущий IP          server GetPlayerEndpoint     secondary risk signal
email/code          NUI -> client -> server       untrusted input
challenge/state     gc_identity server + DB       authoritative
результат отправки  localhost mail service        infrastructure result only
```

Клиент никогда не отправляет IP. `gc_identity` удаляет source port, приводит
IPv4/IPv6/IPv4-mapped IPv6 к стабильному виду и хранит только
`HMAC-SHA256(gcore_ip_fingerprint_secret, normalizedIP)`. IP не доказывает
владение аккаунтом, а только включает дополнительную email-проверку.

## Регистрация

```text
registration_required -> registered name + email -> registering
  -> secure шестизначный code из MariaDB RANDOM_BYTES
  -> в DB-backed challenge сохраняется только HMAC
  -> локальная mail-служба принимает письмо
  -> email_verification_pending
  -> сервер проверяет code, TTL, attempts, binding и текущий endpoint
  -> registration_verified (account и spawn всё ещё отсутствуют)
  -> explicit finalize повторно проверяет license/IP/name/email/challenge
  -> одна transaction consumes challenge, создаёт account, связывает license,
     отмечает email verified и сохраняет первый IP fingerprint
  -> authorized -> trusted Core spawn release -> post-spawn character flow
```

До явной финализации активный account не создаётся. TTL — 10 минут, максимум пять
попыток, resend cooldown — 60 секунд. Resend погашает предыдущий challenge.
Значения находятся в config; NUI timer только отображает время, а решение всегда
принимает сервер.

## Повторный вход

- Тот же license и fingerprint: автоматическая авторизация без почты.
- Тот же license, другой fingerprint: `auth_verification_required`, письмо типа
  `authentication`, вход только после правильного кода.
- Успешная проверка заменяет единственный trusted fingerprint.
- Legacy account без `email_verified_at` обязан подтвердить email; migration не
  объявляет старые данные проверенными автоматически.

## Ошибки и restart

Challenges хранятся в MariaDB и переживают restart `gc_identity` до TTL.
Session generation и challenge ID отбрасывают stale HTTP callbacks. HTTP timeout
ограничен. Если письмо не отправлено, challenge погашается. Ошибка mail-service
не блокирует same-IP вход, но registration и new-IP flow всегда fail-closed и
остаются доступными для контролируемого retry.

## Public/NUI boundary

Identity API v1 по-прежнему возвращает copy Account/Character DTO и не раскрывает
challenge, digest, attempts, fingerprint или secrets. NUI получает только type,
masked email, `expiresIn` и `resendIn`; ожидаемый code в NUI не попадает. Новые
protocol-v3 ingress events `verifyEmail`, `resendVerification`,
`changeRegistrationEmail` и `finalizeRegistration` имеют strict schema
validation и отдельные rate limits.

Настройка процесса и SMTP описана в [README mail-service](../../../../mail-service/README.ru.md).
