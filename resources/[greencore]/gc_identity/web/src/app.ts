import type { CharacterDto, IdentitySnapshot, NuiBridge, NuiMessage } from './types'

const errorMessages: Record<string, string> = {
  'GC-IDENTITY-REGISTRATION-INVALID': 'Проверьте адрес электронной почты.',
  'GC-IDENTITY-EMAIL-TAKEN': 'Этот адрес уже используется.',
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

  const renderLoading = (): string => `
    <section class="identity-shell" data-view="loading">
      <div class="panel panel--small text-center">
        <div class="brand-mark" aria-hidden="true">G</div>
        <p class="eyebrow">GCore Identity</p>
        <h1>Подготавливаем профиль</h1>
        <p class="muted">Проверяем аккаунт и доступных персонажей…</p>
        <div class="loader" role="status" aria-label="Загрузка"></div>
      </div>
    </section>`

  const renderError = (): string => {
    const message = errorMessages[errorCode ?? ''] ?? 'Запрос отклонён. Повторите попытку.'
    return `<div class="alert" role="alert"><span>${escapeHtml(message)}</span><button data-action="dismiss-error" aria-label="Закрыть">×</button></div>`
  }

  const renderLifecycleFailure = (): string => {
    const message = errorMessages[errorCode ?? ''] ?? 'Не удалось подготовить профиль.'
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

  const renderRegistration = (): string => `
    <section class="identity-shell" data-view="registration">
      <div class="panel panel--form">
        <header class="panel-header">
          <div class="brand-mark" aria-hidden="true">G</div>
          <div><p class="eyebrow">Первый вход</p><h1>Создайте профиль</h1></div>
        </header>
        <p class="muted">Ваш FiveM license уже подтверждает вход. Email нужен для уникального игрового профиля; пароль на этом этапе не используется.</p>
        ${errorCode ? renderError() : ''}
        <form data-form="registration" novalidate>
          <label for="email">Электронная почта</label>
          <input id="email" name="email" type="email" autocomplete="email" maxlength="254" required placeholder="player@example.com" />
          <p class="field-note">Мы не запрашиваем пароль и не показываем license в интерфейсе.</p>
          <button class="button button--primary" type="submit" ${pendingAction ? 'disabled' : ''}>
            ${pendingAction === 'registerAccount' ? 'Создаём…' : 'Продолжить'}
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
    } else if (['uninitialized', 'loading', 'authorized', 'registering', 'character_selected'].includes(snapshot.state)) {
      root.innerHTML = renderLoading()
    } else if (snapshot.state === 'registration_required') {
      root.innerHTML = renderRegistration()
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
      void invoke('registerAccount', { email: String(values.get('email') ?? '').trim() })
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

  return {
    receive(message) {
      if (message.type === 'snapshot') {
        snapshot = message.payload
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
      root.removeEventListener('submit', onSubmit)
      root.removeEventListener('click', onClick)
      document.removeEventListener('keydown', onKeyDown)
    },
  }
}
