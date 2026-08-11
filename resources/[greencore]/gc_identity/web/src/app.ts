import type { CharacterDto, IdentitySnapshot, NuiBridge, NuiMessage } from './types'

const errorMessages: Record<string, { ru: string; en: string }> = {
  'GC-IDENTITY-REGISTRATION-INVALID': {
    ru: 'Укажите имя, фамилию латиницей и корректный email.',
    en: 'Enter a Latin first and last name and a valid email.',
  },
  'GC-IDENTITY-REGISTRATION-NAME-INVALID': {
    ru: 'Имя и фамилия должны состоять только из латинских букв.',
    en: 'First and last name may contain Latin letters only.',
  },
  'GC-IDENTITY-NAME-INVALID': {
    ru: 'Имя и фамилия должны состоять только из латинских букв.',
    en: 'First and last name may contain Latin letters only.',
  },
  'GC-IDENTITY-REGISTRATION-NOT-VERIFIED': {
    ru: 'Сначала подтвердите адрес электронной почты.',
    en: 'Verify the email address first.',
  },
  'GC-IDENTITY-REGISTRATION-CHANGED': {
    ru: 'Данные регистрации изменились. Запросите новый код.',
    en: 'Registration details changed. Request a new code.',
  },
  'GC-IDENTITY-SPAWN-MODE-MISCONFIGURED': {
    ru: 'Сервер не включил безопасный pre-spawn режим.',
    en: 'The server did not enable secure pre-spawn mode.',
  },
  'GC-IDENTITY-EMAIL-TAKEN': {
    ru: 'Эта почта уже используется.',
    en: 'This email is already in use.',
  },
  'GC-IDENTITY-EMAIL-CODE-INVALID': {
    ru: 'Неверный код подтверждения.',
    en: 'The verification code is invalid.',
  },
  'GC-IDENTITY-EMAIL-CODE-EXPIRED': {
    ru: 'Код истёк. Запросите новый.',
    en: 'The code expired. Request a new one.',
  },
  'GC-IDENTITY-EMAIL-CODE-ATTEMPTS': {
    ru: 'Лимит попыток исчерпан. Запросите новый код.',
    en: 'The attempt limit was reached. Request a new code.',
  },
  'GC-IDENTITY-EMAIL-RESEND-COOLDOWN': {
    ru: 'Новый код пока нельзя отправить. Дождитесь таймера.',
    en: 'Please wait before requesting another code.',
  },
  'GC-IDENTITY-MAIL-UNAVAILABLE': {
    ru: 'Отправка email временно недоступна.',
    en: 'Email delivery is temporarily unavailable.',
  },
  'GC-IDENTITY-MAIL-TIMEOUT': {
    ru: 'Почтовый сервис не ответил вовремя.',
    en: 'The mail service did not respond in time.',
  },
  'GC-IDENTITY-MAIL-SEND-FAILED': {
    ru: 'Письмо не удалось отправить. Попробуйте позже.',
    en: 'The email could not be sent. Try again later.',
  },
  'GC-IDENTITY-ENDPOINT-UNAVAILABLE': {
    ru: 'Сервер не смог безопасно определить сетевой адрес.',
    en: 'The server could not securely resolve the network address.',
  },
  'GC-IDENTITY-CHARACTER-INVALID': {
    ru: 'Имя или фамилия имеют недопустимый формат.',
    en: 'The first or last name has an invalid format.',
  },
  'GC-IDENTITY-CHARACTER-LIMIT': {
    ru: 'Достигнут лимит персонажей.',
    en: 'The character limit has been reached.',
  },
  'GC-IDENTITY-CHARACTER-NOT-OWNED': {
    ru: 'Персонаж не принадлежит вашему аккаунту.',
    en: 'The character does not belong to your account.',
  },
  'GC-IDENTITY-RATE-LIMIT': {
    ru: 'Слишком много запросов. Подождите немного.',
    en: 'Too many requests. Please wait a moment.',
  },
  'GC-IDENTITY-DATABASE-UNAVAILABLE': {
    ru: 'Сервис профилей временно недоступен.',
    en: 'The identity service is temporarily unavailable.',
  },
  'GC-IDENTITY-DATABASE-QUERY-FAILED': {
    ru: 'Не удалось получить профиль из базы данных.',
    en: 'The profile could not be loaded from the database.',
  },
  'GC-IDENTITY-CORE-UNAVAILABLE': {
    ru: 'Игровое ядро временно недоступно.',
    en: 'The game core is temporarily unavailable.',
  },
  'GC-IDENTITY-HELLO-TIMEOUT': {
    ru: 'Сервер не подтвердил состояние профиля вовремя.',
    en: 'The server did not confirm identity state in time.',
  },
  'GC-IDENTITY-NUI-NOT-READY': {
    ru: 'Интерфейс профиля не смог запуститься.',
    en: 'The identity interface failed to start.',
  },
  'GC-IDENTITY-CLIENT-REQUEST-PENDING': {
    ru: 'Предыдущий запрос ещё выполняется.',
    en: 'The previous request is still running.',
  },
  'GC-IDENTITY-NUI-TRANSPORT': {
    ru: 'Не удалось связаться с игровым клиентом.',
    en: 'The interface could not reach the game client.',
  },
}

type IdentityView =
  | 'hidden'
  | 'loading'
  | 'registration'
  | 'registration-verification'
  | 'login-verification'
  | 'registration-verified'
  | 'profile-completion'
  | 'spawn-transition'
  | 'characters'
  | 'fatal-error'

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
  let activeView: IdentityView = 'hidden'
  let countdownTimer: number | null = null
  let presentationFrame: number | null = null
  let registrationDraft = { fullName: '', email: '' }

  const tr = (ru: string, en: string): string => snapshot?.locale === 'en' ? en : ru
  const remaining = (initial: number): number => Math.max(
    0,
    Math.ceil(initial - (Date.now() - snapshotReceivedAt) / 1000),
  )

  const clearCountdown = (): void => {
    if (countdownTimer !== null) {
      window.clearTimeout(countdownTimer)
      countdownTimer = null
    }
  }

  // EN: Cleanup is state-driven and idempotent. Hidden NUI has no DOM overlay,
  // timer, active root class, pointer surface, or browser background of its own.
  // RU: Cleanup управляется состоянием и идемпотентен. У скрытого NUI нет DOM
  // overlay, таймера, active-класса, pointer surface или собственного фона.
  const cleanupVisualState = (): void => {
    clearCountdown()
    if (presentationFrame !== null) {
      window.cancelAnimationFrame(presentationFrame)
      presentationFrame = null
    }
    root.innerHTML = ''
    root.hidden = true
    root.classList.remove('identity-root--active')
    root.removeAttribute('data-view')
    root.setAttribute('aria-hidden', 'true')
    activeView = 'hidden'
  }

  const errorText = (): string => {
    const messages = errorMessages[errorCode ?? '']
    if (messages) return snapshot?.locale === 'en' ? messages.en : messages.ru
    return tr('Запрос отклонён. Повторите попытку.', 'The request was rejected. Try again.')
  }

  const renderError = (): string => `
    <div class="alert" role="alert">
      <span>${escapeHtml(errorText())}</span>
      <button data-action="dismiss-error" aria-label="${tr('Закрыть ошибку', 'Dismiss error')}">×</button>
    </div>`

  const renderExitModal = (): string => exitConfirmation ? `
    <div class="modal-backdrop" role="presentation">
      <section class="modal" role="dialog" aria-modal="true" aria-labelledby="exit-title">
        <p class="eyebrow">${tr('Выход', 'Exit')}</p>
        <h2 id="exit-title">${tr('Покинуть сервер?', 'Leave the server?')}</h2>
        <p class="muted">${tr('Текущие сохранённые данные не будут потеряны.', 'Your saved data will not be lost.')}</p>
        <div class="actions actions--split">
          <button class="button button--ghost" data-action="cancel-exit">${tr('Остаться', 'Stay')}</button>
          <button class="button button--danger" data-action="confirm-exit">${tr('Выйти', 'Exit')}</button>
        </div>
      </section>
    </div>` : ''

  const renderShell = (view: IdentityView, content: string): string => `
    <section class="identity-shell" data-shell-view="${view}" aria-label="GCore Identity">
      <div class="identity-background" aria-hidden="true">
        <div class="identity-background__grid"></div>
        <div class="identity-background__glow identity-background__glow--left"></div>
        <div class="identity-background__glow identity-background__glow--right"></div>
      </div>
      <div class="identity-layout">
        <header class="shell-brand" aria-label="GCore">
          <span class="brand-mark" aria-hidden="true">G</span>
          <span><strong>GCore</strong><small>Identity</small></span>
        </header>
        <main class="identity-content">${content}</main>
        <footer class="shell-footer">${tr('Безопасная авторизация GCore', 'Secure GCore authorization')}</footer>
      </div>
      ${renderExitModal()}
    </section>`

  const scheduleCountdown = (): void => {
    clearCountdown()
    if (activeView !== 'registration-verification' && activeView !== 'login-verification') return

    const tick = (): void => {
      if (activeView !== 'registration-verification' && activeView !== 'login-verification') {
        clearCountdown()
        return
      }

      const verification = snapshot?.verification
      if (!verification) {
        clearCountdown()
        return
      }

      const expires = root.querySelector<HTMLElement>('[data-expires-timer]')
      if (expires) expires.textContent = String(remaining(verification.expiresIn))

      const resendIn = remaining(verification.resendIn)
      const resend = root.querySelector<HTMLElement>('[data-resend-timer]')
      const resendButton = root.querySelector<HTMLButtonElement>('[data-resend-button]')
      if (resend) resend.textContent = String(resendIn)
      if (resendButton && resendIn === 0 && !pendingAction) {
        resendButton.disabled = false
        resendButton.textContent = tr('Отправить новый код', 'Send a new code')
      }

      countdownTimer = window.setTimeout(tick, 1000)
    }

    countdownTimer = window.setTimeout(tick, 1000)
  }

  const mount = (view: IdentityView, content: string): void => {
    cleanupVisualState()
    root.innerHTML = renderShell(view, content)
    root.hidden = false
    root.classList.add('identity-root--active')
    root.dataset.view = view
    root.setAttribute('aria-hidden', 'false')
    activeView = view
    scheduleCountdown()

    // EN: Loading is handed off only after the opaque shell was committed to a
    // browser frame. JS-ready alone is not proof that the world is covered.
    // RU: Loading передаётся только после commit непрозрачного shell в browser
    // frame. Одного JS-ready недостаточно, чтобы считать мир перекрытым.
    presentationFrame = window.requestAnimationFrame(() => {
      presentationFrame = null
      if (activeView === view && !root.hidden) {
        void bridge.invoke('presented', { view })
      }
    })
  }

  const renderLoading = (): string => `
    <article class="panel panel--small text-center">
      <p class="eyebrow">GCore Identity</p>
      <h1>${tr('Подготавливаем профиль', 'Preparing your profile')}</h1>
      <p class="muted">${tr('Проверяем состояние аккаунта…', 'Checking your account state…')}</p>
      <div class="loader" role="status" aria-label="${tr('Загрузка', 'Loading')}"></div>
    </article>`

  const renderSpawnTransition = (): string => `
    <article class="panel panel--small text-center" aria-busy="true">
      <div class="success-mark" aria-hidden="true">✓</div>
      <p class="eyebrow">GCore</p>
      <h1>${tr('Входим на сервер…', 'Entering the server…')}</h1>
      <p class="muted">${tr('Подготавливаем игровой мир. Экран откроется после подтверждения spawn сервером.', 'Preparing the game world. The screen opens after the server confirms spawn.')}</p>
      <div class="loader" role="status" aria-label="${tr('Spawn выполняется', 'Spawn in progress')}"></div>
    </article>`

  const renderLifecycleFailure = (): string => `
    <article class="panel panel--small text-center">
      <p class="eyebrow">GCore Identity</p>
      <h1>${tr('Профиль недоступен', 'Profile unavailable')}</h1>
      <p class="muted" role="alert">${escapeHtml(errorText())}</p>
      <p class="diagnostic-code">${escapeHtml(errorCode ?? 'GC-IDENTITY-UNKNOWN')}</p>
      <div class="actions actions--split">
        <button class="button button--secondary" data-action="refresh">${tr('Повторить', 'Retry')}</button>
        <button class="button button--danger" data-action="ask-exit">${tr('Выйти', 'Exit')}</button>
      </div>
    </article>`

  const renderRegistration = (): string => `
    <article class="panel panel--form">
      <header class="panel-header">
        <div><p class="eyebrow">${tr('Первый вход', 'First visit')}</p><h1>${tr('Регистрация', 'Registration')}</h1></div>
      </header>
      <p class="muted">${tr('Создайте профиль GCore перед первым входом.', 'Create your GCore profile before entering the server.')}</p>
      <form data-form="registration" novalidate>
        <div class="field">
          <label for="fullName">${tr('Имя Фамилия', 'First name Last name')}</label>
          <input id="fullName" name="fullName" type="text" autocomplete="name" minlength="5" maxlength="65" pattern="[A-Za-z]+ [A-Za-z]+" required placeholder="John Smith" value="${escapeHtml(registrationDraft.fullName)}" />
          <p class="field-note">${tr('Введите имя и фамилию английскими буквами через пробел.', 'Enter your first and last name in Latin letters, separated by a space.')}</p>
        </div>
        <div class="field">
          <label for="email">${tr('Электронная почта', 'Email')}</label>
          <input id="email" name="email" type="email" autocomplete="email" spellcheck="false" maxlength="254" required placeholder="user@example.com" value="${escapeHtml(registrationDraft.email)}" />
          <p class="field-note">${tr('На эту почту будет отправлен шестизначный код подтверждения.', 'A six-digit verification code will be sent to this address.')}</p>
        </div>
        ${errorCode ? renderError() : ''}
        <button class="button button--primary" type="submit" ${pendingAction ? 'disabled' : ''}>
          ${pendingAction === 'sendRegistrationCode' ? tr('Отправляем…', 'Sending…') : tr('Отправить код', 'Send code')}
        </button>
      </form>
      <button class="text-button text-button--quiet" data-action="ask-exit">${tr('Выйти с сервера', 'Leave the server')}</button>
    </article>`

  const renderVerification = (): string => {
    const verification = snapshot?.verification
    if (!verification) return renderLifecycleFailure()
    const authentication = verification.type === 'authentication'
    const resendIn = remaining(verification.resendIn)
    return `
      <article class="panel panel--form">
        <header class="panel-header">
          <div>
            <p class="eyebrow">${authentication ? tr('Безопасность входа', 'Login security') : tr('Регистрация', 'Registration')}</p>
            <h1>${authentication ? tr('Подтверждение входа', 'Login verification') : tr('Проверьте почту', 'Check your inbox')}</h1>
          </div>
        </header>
        <p class="muted">${authentication
          ? tr('Мы обнаружили вход с нового сетевого адреса. Код необходим для безопасного продолжения.', 'We detected a login from a new network address. The code is required to continue securely.')
          : tr('Код отправлен на указанную почту. Подтверждение ещё не создаёт аккаунт — после него останется финальный шаг.', 'The code was sent to your email. Verification does not create the account yet; one final step remains.')}</p>
        <div class="masked-email"><span>${tr('Код отправлен на', 'Code sent to')}</span><strong>${escapeHtml(verification.maskedEmail)}</strong></div>
        <form data-form="verification" novalidate>
          <label for="verificationCode">${tr('Код подтверждения', 'Verification code')}</label>
          <input class="verification-code" id="verificationCode" name="code" type="text" inputmode="numeric" autocomplete="one-time-code" minlength="6" maxlength="6" pattern="[0-9]{6}" required placeholder="000000" aria-describedby="verification-help" />
          <p class="field-note" id="verification-help">${tr('Код действует ещё', 'Code expires in')} <span data-expires-timer>${remaining(verification.expiresIn)}</span> ${tr('сек.', 'sec.')}</p>
          ${errorCode ? renderError() : ''}
          <button class="button button--primary" type="submit" ${pendingAction ? 'disabled' : ''}>
            ${pendingAction === 'verifyEmail' ? tr('Проверяем…', 'Verifying…') : tr('Подтвердить код', 'Verify code')}
          </button>
        </form>
        <button class="text-button" data-action="resend-verification" data-resend-button ${pendingAction || resendIn > 0 ? 'disabled' : ''}>
          ${resendIn > 0 ? `${tr('Отправить повторно через', 'Send again in')} <span data-resend-timer>${resendIn}</span> ${tr('сек.', 'sec.')}` : tr('Отправить новый код', 'Send a new code')}
        </button>
        ${authentication ? '' : `<button class="text-button text-button--secondary" data-action="change-registration-email">${tr('Изменить email', 'Change email')}</button>`}
        <button class="text-button text-button--quiet" data-action="ask-exit">${tr('Выйти с сервера', 'Leave the server')}</button>
      </article>`
  }

  const renderRegistrationVerified = (): string => {
    const registration = snapshot?.registration
    if (!registration?.emailVerified) return renderLifecycleFailure()
    return `
      <article class="panel panel--form text-center">
        <div class="success-mark" aria-hidden="true">✓</div>
        <p class="eyebrow">${tr('Email подтверждён', 'Email verified')}</p>
        <h1>${tr('Завершите регистрацию', 'Finish registration')}</h1>
        <dl class="profile-summary">
          <div><dt>${tr('Имя', 'Name')}</dt><dd>${escapeHtml(registration.fullName)}</dd></div>
          <div><dt>Email</dt><dd>${escapeHtml(registration.email)}</dd></div>
        </dl>
        ${errorCode ? renderError() : ''}
        <button class="button button--primary" data-action="finalize-registration" ${pendingAction ? 'disabled' : ''}>
          ${pendingAction === 'finalizeRegistration' ? tr('Завершаем…', 'Finishing…') : tr('Завершить регистрацию', 'Finish registration')}
        </button>
        <button class="text-button text-button--secondary" data-action="change-registration-email">${tr('Изменить email', 'Change email')}</button>
        <button class="text-button text-button--quiet" data-action="ask-exit">${tr('Выйти с сервера', 'Leave the server')}</button>
      </article>`
  }

  const renderProfileCompletion = (): string => `
    <article class="panel panel--form">
      <header class="panel-header"><div><p class="eyebrow">${tr('Обновление профиля', 'Profile update')}</p><h1>${tr('Регистрация', 'Registration')}</h1></div></header>
      <p class="muted">${tr('У существующего аккаунта ещё нет зарегистрированного имени. Укажите имя и фамилию до spawn.', 'This existing account has no registered name yet. Enter your first and last name before spawn.')}</p>
      <form data-form="profile" novalidate>
        <label for="profileFullName">${tr('Имя Фамилия', 'First name Last name')}</label>
        <input id="profileFullName" name="fullName" type="text" autocomplete="name" minlength="5" maxlength="65" pattern="[A-Za-z]+ [A-Za-z]+" required placeholder="John Smith" value="${escapeHtml(registrationDraft.fullName)}" />
        <p class="field-note">${tr('Введите имя и фамилию английскими буквами через пробел.', 'Enter your first and last name in Latin letters, separated by a space.')}</p>
        ${errorCode ? renderError() : ''}
        <button class="button button--primary" type="submit" ${pendingAction ? 'disabled' : ''}>
          ${pendingAction === 'completeProfile' ? tr('Сохраняем…', 'Saving…') : tr('Сохранить и продолжить', 'Save and continue')}
        </button>
      </form>
      <button class="text-button text-button--quiet" data-action="ask-exit">${tr('Выйти с сервера', 'Leave the server')}</button>
    </article>`

  const renderCharacters = (): string => {
    const characters = snapshot?.characters ?? []
    const maxCharacters = snapshot?.limits.maxCharacters ?? 0
    const canCreate = characters.length < maxCharacters
    const cards = characters.map((character) => `
      <article class="character-card">
        <div class="avatar" aria-hidden="true">${escapeHtml(character.firstName.charAt(0).toUpperCase())}</div>
        <div class="character-copy"><h3>${escapeHtml(characterName(character))}</h3><p>ID ${character.id}</p></div>
        <button class="button button--primary button--compact" data-action="select-character" data-character-id="${character.id}" ${pendingAction ? 'disabled' : ''}>
          ${pendingAction === `select:${character.id}` ? tr('Выбираем…', 'Selecting…') : tr('Играть', 'Play')}
        </button>
      </article>`).join('')

    return `
      <article class="panel panel--wide">
        <header class="panel-header panel-header--spread">
          <div><p class="eyebrow">${tr('Аккаунт', 'Account')} ${escapeHtml(snapshot?.account?.email ?? '')}</p><h1>${tr('Выберите персонажа', 'Choose a character')}</h1></div>
          <button class="icon-button" data-action="ask-exit" aria-label="${tr('Выйти', 'Exit')}">↗</button>
        </header>
        ${errorCode ? renderError() : ''}
        <div class="character-grid">${cards || `<p class="empty-state">${tr('Персонажей пока нет. Создайте первого.', 'There are no characters yet. Create your first one.')}</p>`}</div>
        <div class="divider"><span>${characters.length} / ${maxCharacters}</span></div>
        ${canCreate ? `
          <form class="create-form" data-form="character" novalidate>
            <div class="field"><label for="firstName">${tr('Имя', 'First name')}</label><input id="firstName" name="firstName" maxlength="32" required /></div>
            <div class="field"><label for="lastName">${tr('Фамилия', 'Last name')}</label><input id="lastName" name="lastName" maxlength="32" required /></div>
            <button class="button button--secondary" type="submit" ${pendingAction ? 'disabled' : ''}>${pendingAction === 'createCharacter' ? tr('Создаём…', 'Creating…') : tr('Создать', 'Create')}</button>
          </form>` : `<p class="field-note">${tr('Достигнут доступный лимит персонажей.', 'The available character limit has been reached.')}</p>`}
      </article>`
  }

  const resolveView = (): IdentityView => {
    if (!snapshot) {
      if (pendingAction === 'refresh') return 'loading'
      return errorCode ? 'fatal-error' : 'hidden'
    }

    switch (snapshot.state) {
      case 'uninitialized':
      case 'loading':
      case 'registering':
        return 'loading'
      case 'registration_required':
        return 'registration'
      case 'email_verification_pending':
        return 'registration-verification'
      case 'auth_verification_required':
        return 'login-verification'
      case 'registration_verified':
        return 'registration-verified'
      case 'profile_completion_required':
        return 'profile-completion'
      case 'authorized':
      case 'registration_finalizing':
      case 'spawn_releasing':
      case 'post_spawn_identity':
      case 'character_selected':
        return 'spawn-transition'
      case 'character_required':
        return 'characters'
      case 'error':
        return 'fatal-error'
      case 'ready':
      case 'disconnecting':
        return 'hidden'
      default:
        errorCode = 'GC-IDENTITY-NUI-UNKNOWN-VIEW'
        return 'fatal-error'
    }
  }

  const render = (): void => {
    const view = resolveView()
    if (view === 'hidden') {
      cleanupVisualState()
      return
    }

    if (view === 'loading') mount(view, renderLoading())
    else if (view === 'registration') mount(view, renderRegistration())
    else if (view === 'registration-verification' || view === 'login-verification') mount(view, renderVerification())
    else if (view === 'registration-verified') mount(view, renderRegistrationVerified())
    else if (view === 'profile-completion') mount(view, renderProfileCompletion())
    else if (view === 'spawn-transition') mount(view, renderSpawnTransition())
    else if (view === 'characters') mount(view, renderCharacters())
    else mount('fatal-error', renderLifecycleFailure())
  }

  const invoke = async (action: string, payload: object, renderPending = true): Promise<void> => {
    if (pendingAction) {
      errorCode = 'GC-IDENTITY-CLIENT-REQUEST-PENDING'
      render()
      return
    }

    pendingAction = action
    errorCode = null
    if (renderPending) render()

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
      registrationDraft = {
        fullName: String(values.get('fullName') ?? '').trim(),
        email: String(values.get('email') ?? '').trim(),
      }
      void invoke('sendRegistrationCode', registrationDraft)
    } else if (form.dataset.form === 'verification') {
      const code = String(values.get('code') ?? '').replace(/\D/g, '').slice(0, 6)
      void invoke('verifyEmail', { code })
    } else if (form.dataset.form === 'profile') {
      registrationDraft.fullName = String(values.get('fullName') ?? '').trim()
      void invoke('completeProfile', { fullName: registrationDraft.fullName })
    } else if (form.dataset.form === 'character') {
      void invoke('createCharacter', {
        firstName: String(values.get('firstName') ?? '').trim(),
        lastName: String(values.get('lastName') ?? '').trim(),
      })
    }
  }

  const onInput = (event: Event): void => {
    const input = event.target
    if (!(input instanceof HTMLInputElement) || input.id !== 'verificationCode') return
    input.value = input.value.replace(/\D/g, '').slice(0, 6)
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
      cleanupVisualState()
      void invoke('exit', {}, false)
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
    if (event.key !== 'Escape' || activeView === 'hidden') return
    exitConfirmation = !exitConfirmation
    render()
  }

  root.addEventListener('submit', onSubmit)
  root.addEventListener('input', onInput)
  root.addEventListener('click', onClick)
  document.addEventListener('keydown', onKeyDown)
  cleanupVisualState()

  return {
    receive(message) {
      if (message.type === 'snapshot') {
        snapshot = message.payload
        snapshotReceivedAt = Date.now()
        pendingAction = null
        errorCode = null
        exitConfirmation = false
        if (message.payload.registration) {
          registrationDraft = {
            fullName: message.payload.registration.fullName,
            email: message.payload.registration.email,
          }
        }
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
        registrationDraft = { fullName: '', email: '' }
      }
      render()
    },
    destroy() {
      cleanupVisualState()
      root.removeEventListener('submit', onSubmit)
      root.removeEventListener('input', onInput)
      root.removeEventListener('click', onClick)
      document.removeEventListener('keydown', onKeyDown)
    },
  }
}
