import type { CharacterDto, IdentitySnapshot, NuiBridge, NuiMessage } from './types'

const errorMessages: Record<string, string> = {
  'GC-IDENTITY-REGISTRATION-INVALID': 'Укажите имя, фамилию латиницей и корректный email.',
  'GC-IDENTITY-REGISTRATION-NAME-INVALID': 'Имя и фамилия должны состоять только из латинских букв.',
  'GC-IDENTITY-NAME-INVALID': 'Имя и фамилия должны состоять только из латинских букв.',
  'GC-IDENTITY-REGISTRATION-NOT-VERIFIED': 'Сначала подтвердите адрес электронной почты.',
  'GC-IDENTITY-REGISTRATION-CHANGED': 'Данные регистрации изменились. Запросите новый код.',
  'GC-IDENTITY-SPAWN-MODE-MISCONFIGURED': 'Сервер не включил безопасный pre-spawn режим.',
  'GC-IDENTITY-EMAIL-TAKEN': 'Этот адрес уже используется.',
  'GC-IDENTITY-EMAIL-CODE-INVALID': 'Неверный код подтверждения.',
  'GC-IDENTITY-EMAIL-CODE-EXPIRED': 'Код истёк. Запросите новый.',
  'GC-IDENTITY-EMAIL-CODE-ATTEMPTS': 'Лимит попыток исчерпан. Запросите новый код.',
  'GC-IDENTITY-EMAIL-RESEND-COOLDOWN': 'Новый код пока нельзя отправить. Дождитесь таймера.',
  'GC-IDENTITY-MAIL-UNAVAILABLE': 'Отправка email временно недоступна.',
  'GC-IDENTITY-MAIL-TIMEOUT': 'Почтовый сервис не ответил вовремя.',
  'GC-IDENTITY-MAIL-SEND-FAILED': 'Письмо не удалось отправить. Попробуйте позже.',
  'GC-IDENTITY-ENDPOINT-UNAVAILABLE': 'Сервер не смог безопасно определить сетевой адрес.',
  'GC-IDENTITY-CHARACTER-INVALID': 'Имя или фамилия имеют недопустимый формат.',
  'GC-IDENTITY-CHARACTER-LIMIT': 'Достигнут лимит персонажей.',
  'GC-IDENTITY-CHARACTER-NOT-OWNED': 'Персонаж не принадлежит вашему аккаунту.',
  'GC-IDENTITY-RATE-LIMIT': 'Слишком много запросов. Подождите немного.',
  'GC-IDENTITY-DATABASE-UNAVAILABLE': 'Сервис профилей временно недоступен.',
  'GC-IDENTITY-DATABASE-QUERY-FAILED': 'Не удалось получить профиль из базы данных.',
  'GC-IDENTITY-CORE-UNAVAILABLE': 'Игровое ядро временно недоступно.',
  'GC-IDENTITY-HELLO-TIMEOUT': 'Сервер не подтвердил состояние профиля вовремя.',
  'GC-IDENTITY-NUI-NOT-READY': 'Интерфейс профиля не смог запуститься.',
  'GC-IDENTITY-CLIENT-REQUEST-PENDING': 'Предыдущий запрос ещё выполняется.',
  'GC-IDENTITY-NUI-TRANSPORT': 'Не удалось связаться с игровым клиентом.',
}

const errorMessagesEn: Record<string, string> = {
  'GC-IDENTITY-REGISTRATION-INVALID': 'Enter a Latin first and last name and a valid email.',
  'GC-IDENTITY-NAME-INVALID': 'First and last name may contain Latin letters only.',
  'GC-IDENTITY-EMAIL-TAKEN': 'This email is already in use.',
  'GC-IDENTITY-EMAIL-CODE-INVALID': 'The verification code is invalid.',
  'GC-IDENTITY-EMAIL-CODE-EXPIRED': 'The code expired. Request a new one.',
  'GC-IDENTITY-EMAIL-CODE-ATTEMPTS': 'The attempt limit was reached. Request a new code.',
  'GC-IDENTITY-EMAIL-RESEND-COOLDOWN': 'Please wait before requesting another code.',
  'GC-IDENTITY-MAIL-UNAVAILABLE': 'Email delivery is temporarily unavailable.',
  'GC-IDENTITY-MAIL-TIMEOUT': 'The mail service did not respond in time.',
  'GC-IDENTITY-DATABASE-UNAVAILABLE': 'The identity service is temporarily unavailable.',
  'GC-IDENTITY-CORE-UNAVAILABLE': 'The game core is temporarily unavailable.',
  'GC-IDENTITY-SPAWN-MODE-MISCONFIGURED': 'The server did not enable secure pre-spawn mode.',
  'GC-IDENTITY-HELLO-TIMEOUT': 'The server did not confirm identity state in time.',
  'GC-IDENTITY-NUI-NOT-READY': 'The identity interface failed to start.',
  'GC-IDENTITY-CLIENT-REQUEST-PENDING': 'The previous request is still running.',
  'GC-IDENTITY-NUI-TRANSPORT': 'The interface could not reach the game client.',
}

function escapeHtml(value: string): string {
  return value.replace(/[&<>'"]/g, (symbol) => ({
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    "'": '&#39;',
    '"': '&quot;',
  })[symbol] ?? symbol)
}

function characterName(character: CharacterDto): string {
  return `${character.firstName} ${character.lastName}`
}

export interface IdentityApp {
  receive(message: NuiMessage): void
  destroy(): void
}

export function createIdentityApp(root: HTMLElement, bridge: NuiBridge): IdentityApp {
  let snapshot: IdentitySnapshot | null = null
  let pendingAction: string | null = null
  let errorCode: string | null = null
  let exitConfirmation = false
  let snapshotReceivedAt = Date.now()
  const tr = (ru: string, en: string): string => snapshot?.locale === 'en' ? en : ru

  const remaining = (initial: number): number => Math.max(
    0,
    Math.ceil(initial - (Date.now() - snapshotReceivedAt) / 1000),
  )

  const renderLoading = (): string => `
    <section class="identity-shell" data-view="loading">
      <div class="panel panel--small text-center">
        <div class="brand-mark" aria-hidden="true">G</div>
        <p class="eyebrow">GCore Identity</p>
        <h1>${tr('Подготавливаем профиль', 'Preparing your profile')}</h1>
        <p class="muted">${tr('Проверяем аккаунт и доступных персонажей…', 'Checking your account and available characters…')}</p>
        <div class="loader" role="status" aria-label="${tr('Загрузка', 'Loading')}"></div>
      </div>
    </section>`

  const renderError = (): string => {
    const messages = snapshot?.locale === 'en' ? errorMessagesEn : errorMessages
    const message = messages[errorCode ?? ''] ?? tr('Запрос отклонён. Повторите попытку.', 'The request was rejected. Try again.')
    return `<div class="alert" role="alert"><span>${escapeHtml(message)}</span><button data-action="dismiss-error" aria-label="Закрыть">×</button></div>`
  }

  const renderLifecycleFailure = (): string => {
    const messages = snapshot?.locale === 'en' ? errorMessagesEn : errorMessages
    const message = messages[errorCode ?? ''] ?? tr('Не удалось подготовить профиль.', 'The profile could not be prepared.')
    return `
      <section class="identity-shell" data-view="lifecycle-error">
        <div class="panel panel--small text-center">
          <p class="eyebrow">GCore Identity</p>
          <h1>Профиль недоступен</h1>
          <p class="muted" role="alert">${escapeHtml(message)}</p>
          <p class="diagnostic-code">${escapeHtml(errorCode ?? 'GC-IDENTITY-UNKNOWN')}</p>
          <div class="actions actions--split">
            <button class="button button--secondary" data-action="refresh">Повторить</button>
            <button class="button button--danger" data-action="ask-exit">Выйти</button>
          </div>
        </div>
        ${renderExitModal()}
      </section>`
  }

  const renderExitModal = (): string => exitConfirmation ? `
    <div class="modal-backdrop" role="presentation">
      <section class="modal" role="dialog" aria-modal="true" aria-labelledby="exit-title">
        <p class="eyebrow">Выход</p>
        <h2 id="exit-title">Покинуть сервер?</h2>
        <p class="muted">Текущие сохранённые данные не будут потеряны.</p>
        <div class="actions actions--split">
          <button class="button button--ghost" data-action="cancel-exit">Остаться</button>
          <button class="button button--danger" data-action="confirm-exit">Выйти</button>
        </div>
      </section>
    </div>` : ''

  const renderRegistration = (): string => {
    const registration = snapshot?.registration
    return `
    <section class="identity-shell" data-view="registration">
      <div class="panel panel--form">
        <header class="panel-header">
          <div class="brand-mark" aria-hidden="true">G</div>
          <div><p class="eyebrow">${tr('Первый вход', 'First visit')}</p><h1>${tr('Регистрация', 'Registration')}</h1></div>
        </header>
        <p class="muted">${tr('Укажите имя и фамилию латиницей, затем email. Аккаунт и spawn будут разрешены только после подтверждения и финального шага.', 'Enter a Latin first and last name, then email. The account and spawn are allowed only after verification and finalization.')}</p>
        ${errorCode ? renderError() : ''}
        <form data-form="registration" novalidate>
          <label for="fullName">${tr('Имя Фамилия', 'First name Last name')}</label>
          <input id="fullName" name="fullName" type="text" autocomplete="name" minlength="5" maxlength="65" pattern="[A-Za-z]+ [A-Za-z]+" required placeholder="John Smith" value="${escapeHtml(registration?.fullName ?? '')}" />
          <label for="email">${tr('Электронная почта', 'Email')}</label>
          <input id="email" name="email" type="email" autocomplete="email" maxlength="254" required placeholder="player@example.com" value="${escapeHtml(registration?.email ?? '')}" />
          <p class="field-note">${tr('Мы не запрашиваем пароль и не показываем license в интерфейсе.', 'We do not request a password or expose your license in the UI.')}</p>
          <button class="button button--primary" type="submit" ${pendingAction ? 'disabled' : ''}>
            ${pendingAction === 'sendRegistrationCode' ? tr('Отправляем…', 'Sending…') : tr('Отправить код', 'Send code')}
          </button>
        </form>
        <button class="text-button" data-action="ask-exit">Выйти с сервера</button>
      </div>
      ${renderExitModal()}
    </section>`
  }

  const renderVerification = (): string => {
    const verification = snapshot?.verification
    if (!verification) return renderLifecycleFailure()
    const authentication = verification.type === 'authentication'
    const resendIn = remaining(verification.resendIn)
    return `
      <section class="identity-shell" data-view="verification">
        <div class="panel panel--form">
          <header class="panel-header">
            <div class="brand-mark" aria-hidden="true">G</div>
            <div><p class="eyebrow">${authentication ? tr('Безопасность входа', 'Login security') : tr('Подтверждение email', 'Email verification')}</p><h1>${authentication ? tr('Новый сетевой адрес', 'New network address') : tr('Проверьте почту', 'Check your inbox')}</h1></div>
          </header>
          <p class="muted">${tr('Код отправлен на', 'A code was sent to')} <strong>${escapeHtml(verification.maskedEmail)}</strong>. ${authentication ? tr('Подтвердите вход с нового сетевого адреса.', 'Confirm login from the new network address.') : tr('Проверка кода ещё не создаёт аккаунт и не разрешает spawn.', 'Code verification does not create the account or allow spawn yet.')}</p>
          ${errorCode ? renderError() : ''}
          <form data-form="verification" novalidate>
            <label for="verificationCode">${tr('Шестизначный код', 'Six-digit code')}</label>
            <input class="verification-code" id="verificationCode" name="code" type="text" inputmode="numeric" autocomplete="one-time-code" minlength="6" maxlength="6" pattern="[0-9]{6}" required placeholder="000000" />
            <p class="field-note">${tr('Код действует ещё', 'Code expires in')} <span data-expires-timer>${remaining(verification.expiresIn)}</span> ${tr('сек. Сервер проверяет срок и число попыток.', 'sec. The server checks expiry and attempts.')}</p>
            <button class="button button--primary" type="submit" ${pendingAction ? 'disabled' : ''}>${pendingAction === 'verifyEmail' ? tr('Проверяем…', 'Verifying…') : tr('Подтвердить', 'Verify')}</button>
          </form>
          <button class="text-button" data-action="resend-verification" data-resend-button ${pendingAction || resendIn > 0 ? 'disabled' : ''}>
            ${resendIn > 0 ? `${tr('Отправить снова через', 'Send again in')} <span data-resend-timer>${resendIn}</span> ${tr('сек.', 'sec.')}` : tr('Отправить новый код', 'Send a new code')}
          </button>
          ${authentication ? '' : `<button class="text-button" data-action="change-registration-email">${tr('Изменить email', 'Change email')}</button>`}
          <button class="text-button" data-action="ask-exit">Выйти с сервера</button>
        </div>
        ${renderExitModal()}
      </section>`
  }

  const renderRegistrationVerified = (): string => {
    const registration = snapshot?.registration
    if (!registration?.emailVerified) return renderLifecycleFailure()
    return `
      <section class="identity-shell" data-view="registration-verified">
        <div class="panel panel--form text-center">
          <div class="brand-mark" aria-hidden="true">G</div>
          <p class="eyebrow">${tr('Email подтверждён', 'Email verified')}</p>
          <h1>${tr('Завершите регистрацию', 'Finish registration')}</h1>
          <p class="muted"><strong>${escapeHtml(registration.fullName)}</strong><br />${escapeHtml(registration.email)}</p>
          <p class="field-note">${tr('Только этот шаг атомарно создаст аккаунт и разрешит серверу запросить spawn.', 'Only this step atomically creates the account and lets the server request spawn.')}</p>
          ${errorCode ? renderError() : ''}
          <button class="button button--primary" data-action="finalize-registration" ${pendingAction ? 'disabled' : ''}>
            ${pendingAction === 'finalizeRegistration' ? tr('Завершаем…', 'Finishing…') : tr('Завершить регистрацию', 'Finish registration')}
          </button>
          <button class="text-button" data-action="change-registration-email">${tr('Изменить email', 'Change email')}</button>
          <button class="text-button" data-action="ask-exit">Выйти с сервера</button>
        </div>
        ${renderExitModal()}
      </section>`
  }

  const renderProfileCompletion = (): string => `
    <section class="identity-shell" data-view="profile-completion">
      <div class="panel panel--form">
        <header class="panel-header">
          <div class="brand-mark" aria-hidden="true">G</div>
          <div><p class="eyebrow">${tr('Обновление профиля', 'Profile update')}</p><h1>${tr('Регистрация', 'Registration')}</h1></div>
        </header>
        <p class="muted">${tr('У этого существующего аккаунта ещё нет зарегистрированного имени. Укажите имя и фамилию латиницей до spawn.', 'This existing account has no registered name yet. Enter a Latin first and last name before spawn.')}</p>
        ${errorCode ? renderError() : ''}
        <form data-form="profile" novalidate>
          <label for="profileFullName">${tr('Имя Фамилия', 'First name Last name')}</label>
          <input id="profileFullName" name="fullName" type="text" autocomplete="name" minlength="5" maxlength="65" pattern="[A-Za-z]+ [A-Za-z]+" required placeholder="John Smith" />
          <button class="button button--primary" type="submit" ${pendingAction ? 'disabled' : ''}>
            ${pendingAction === 'completeProfile' ? tr('Сохраняем…', 'Saving…') : tr('Сохранить и продолжить', 'Save and continue')}
          </button>
        </form>
        <button class="text-button" data-action="ask-exit">Выйти с сервера</button>
      </div>
      ${renderExitModal()}
    </section>`

  const renderCharacters = (): string => {
    const characters = snapshot?.characters ?? []
    const maxCharacters = snapshot?.limits.maxCharacters ?? 0
    const canCreate = characters.length < maxCharacters
    const cards = characters.map((character) => `
      <article class="character-card">
        <div class="avatar" aria-hidden="true">${escapeHtml(character.firstName.charAt(0).toUpperCase())}</div>
        <div class="character-copy">
          <h3>${escapeHtml(characterName(character))}</h3>
          <p>ID ${character.id}</p>
        </div>
        <button class="button button--primary button--compact" data-action="select-character" data-character-id="${character.id}" ${pendingAction ? 'disabled' : ''}>
          ${pendingAction === `select:${character.id}` ? 'Выбираем…' : 'Играть'}
        </button>
      </article>`).join('')

    return `
      <section class="identity-shell" data-view="characters">
        <div class="panel panel--wide">
          <header class="panel-header panel-header--spread">
            <div><p class="eyebrow">Аккаунт ${escapeHtml(snapshot?.account?.email ?? '')}</p><h1>Выберите персонажа</h1></div>
            <button class="icon-button" data-action="ask-exit" aria-label="Выйти">↗</button>
          </header>
          ${errorCode ? renderError() : ''}
          <div class="character-grid">${cards || '<p class="empty-state">Персонажей пока нет. Создайте первого.</p>'}</div>
          <div class="divider"><span>${characters.length} / ${maxCharacters}</span></div>
          ${canCreate ? `
            <form class="create-form" data-form="character" novalidate>
              <div class="field"><label for="firstName">Имя</label><input id="firstName" name="firstName" maxlength="32" required /></div>
              <div class="field"><label for="lastName">Фамилия</label><input id="lastName" name="lastName" maxlength="32" required /></div>
              <button class="button button--secondary" type="submit" ${pendingAction ? 'disabled' : ''}>${pendingAction === 'createCharacter' ? 'Создаём…' : 'Создать'}</button>
            </form>` : '<p class="field-note">Достигнут доступный лимит персонажей.</p>'}
        </div>
        ${renderExitModal()}
      </section>`
  }

  const render = (): void => {
    // EN: A FiveM ui_page is loaded eagerly. Until Lua sends an authoritative
    // snapshot, the page must paint nothing and must not cover the game.
    // RU: FiveM загружает ui_page заранее. Пока Lua не прислал authoritative
    // snapshot, страница ничего не рисует и не перекрывает игру.
    if (!snapshot) {
      if (pendingAction === 'refresh') {
        root.innerHTML = renderLoading()
      } else if (errorCode) {
        root.innerHTML = renderLifecycleFailure()
      } else {
        root.innerHTML = ''
      }
    } else if (['uninitialized', 'loading', 'authorized', 'registering', 'registration_finalizing', 'spawn_releasing', 'post_spawn_identity', 'character_selected'].includes(snapshot.state)) {
      root.innerHTML = renderLoading()
    } else if (snapshot.state === 'registration_required') {
      root.innerHTML = renderRegistration()
    } else if (snapshot.state === 'email_verification_pending' || snapshot.state === 'auth_verification_required') {
      root.innerHTML = renderVerification()
    } else if (snapshot.state === 'registration_verified') {
      root.innerHTML = renderRegistrationVerified()
    } else if (snapshot.state === 'profile_completion_required') {
      root.innerHTML = renderProfileCompletion()
    } else if (snapshot.state === 'character_required') {
      root.innerHTML = renderCharacters()
    } else if (snapshot.state === 'error') {
      root.innerHTML = `<section class="identity-shell"><div class="panel panel--small text-center"><p class="eyebrow">Ошибка</p><h1>Профиль недоступен</h1>${renderError()}<button class="button button--secondary" data-action="refresh">Повторить</button></div></section>`
    } else {
      root.innerHTML = ''
    }

    // EN: FiveM keeps ui_page alive for the whole resource lifetime. The DOM
    // root therefore has an explicit visibility state instead of relying on an
    // empty transparent page and the browser's default canvas colour.
    // RU: FiveM держит ui_page загруженной всё время жизни ресурса. Поэтому у
    // DOM root есть явное состояние видимости, а не зависимость от пустой
    // страницы и фонового цвета canvas по умолчанию.
    root.hidden = root.innerHTML.length === 0
  }

  const invoke = async (action: string, payload: object): Promise<void> => {
    if (pendingAction) {
      errorCode = 'GC-IDENTITY-CLIENT-REQUEST-PENDING'
      render()
      return
    }

    pendingAction = action
    errorCode = null
    render()

    try {
      const result = await bridge.invoke(action.split(':')[0] ?? action, payload)
      if (!result.ok) {
        pendingAction = null
        errorCode = result.code ?? 'GC-IDENTITY-REQUEST-REJECTED'
        render()
      }
    } catch {
      pendingAction = null
      errorCode = 'GC-IDENTITY-NUI-TRANSPORT'
      render()
    }
  }

  const onSubmit = (event: SubmitEvent): void => {
    const form = event.target
    if (!(form instanceof HTMLFormElement)) return
    event.preventDefault()

    const values = new FormData(form)
    if (form.dataset.form === 'registration') {
      void invoke('sendRegistrationCode', {
        fullName: String(values.get('fullName') ?? '').trim(),
        email: String(values.get('email') ?? '').trim(),
      })
    } else if (form.dataset.form === 'verification') {
      void invoke('verifyEmail', { code: String(values.get('code') ?? '').trim() })
    } else if (form.dataset.form === 'profile') {
      void invoke('completeProfile', { fullName: String(values.get('fullName') ?? '').trim() })
    } else if (form.dataset.form === 'character') {
      void invoke('createCharacter', {
        firstName: String(values.get('firstName') ?? '').trim(),
        lastName: String(values.get('lastName') ?? '').trim(),
      })
    }
  }

  const onClick = (event: MouseEvent): void => {
    const target = event.target instanceof Element ? event.target.closest<HTMLElement>('[data-action]') : null
    if (!target) return
    const action = target.dataset.action

    if (action === 'select-character') {
      const characterId = Number(target.dataset.characterId)
      void invoke(`selectCharacter:${characterId}`, { characterId })
    } else if (action === 'ask-exit') {
      exitConfirmation = true
      render()
    } else if (action === 'cancel-exit') {
      exitConfirmation = false
      render()
    } else if (action === 'confirm-exit') {
      void invoke('exit', {})
    } else if (action === 'dismiss-error') {
      errorCode = null
      render()
    } else if (action === 'refresh') {
      void invoke('refresh', {})
    } else if (action === 'resend-verification') {
      void invoke('resendVerification', {})
    } else if (action === 'change-registration-email') {
      void invoke('changeRegistrationEmail', {})
    } else if (action === 'finalize-registration') {
      void invoke('finalizeRegistration', {})
    }
  }

  const onKeyDown = (event: KeyboardEvent): void => {
    if (event.key !== 'Escape' || snapshot?.state === 'ready') return
    exitConfirmation = !exitConfirmation
    render()
  }

  root.addEventListener('submit', onSubmit)
  root.addEventListener('click', onClick)
  document.addEventListener('keydown', onKeyDown)
  render()
  const timer = window.setInterval(() => {
    const verification = snapshot?.verification
    if (!verification) return
    const expires = root.querySelector<HTMLElement>('[data-expires-timer]')
    if (expires) expires.textContent = String(remaining(verification.expiresIn))
    const resend = root.querySelector<HTMLElement>('[data-resend-timer]')
    const resendButton = root.querySelector<HTMLButtonElement>('[data-resend-button]')
    const resendIn = remaining(verification.resendIn)
    if (resend) resend.textContent = String(resendIn)
    if (resendButton && resendIn === 0 && !pendingAction) {
      resendButton.disabled = false
      resendButton.textContent = tr('Отправить новый код', 'Send a new code')
    }
  }, 1000)

  return {
    receive(message) {
      if (message.type === 'snapshot') {
        snapshot = message.payload
        snapshotReceivedAt = Date.now()
        pendingAction = null
        errorCode = null
        exitConfirmation = false
      } else if (message.type === 'rejected') {
        pendingAction = null
        errorCode = message.payload.code
      } else if (message.type === 'lifecycleError') {
        snapshot = null
        pendingAction = null
        errorCode = message.payload.code
      } else if (message.type === 'reset') {
        snapshot = null
        pendingAction = null
        errorCode = null
        exitConfirmation = false
      }
      render()
    },
    destroy() {
      window.clearInterval(timer)
      root.removeEventListener('submit', onSubmit)
      root.removeEventListener('click', onClick)
      document.removeEventListener('keydown', onKeyDown)
    },
  }
}
