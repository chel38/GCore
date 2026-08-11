import { createIdentityApp } from './app'
import { nuiBridge } from './bridge'
import type { IdentitySnapshot, NuiBridge } from './types'

const registration: IdentitySnapshot = {
  protocolVersion: 3,
  locale: 'ru',
  state: 'registration_required',
  account: null,
  characters: [],
  selectedCharacter: null,
  limits: { maxCharacters: 3 },
  passwordAuthentication: false,
  registration: {
    fullName: '',
    email: '',
    emailVerified: false,
    profileOnly: false,
  },
}

function deferred<T>() {
  let resolve!: (value: T) => void
  const promise = new Promise<T>((resolver) => { resolve = resolver })
  return { promise, resolve }
}

function createApp(bridge?: NuiBridge) {
  const root = document.querySelector<HTMLElement>('#app')!
  const app = createIdentityApp(root, bridge ?? { invoke: vi.fn().mockResolvedValue({ ok: true }) })
  return { root, app }
}

function verification(type: 'registration' | 'authentication'): IdentitySnapshot {
  return {
    ...registration,
    state: type === 'registration' ? 'email_verification_pending' : 'auth_verification_required',
    verification: {
      type,
      maskedEmail: 'u***@example.com',
      expiresIn: 300,
      resendIn: 60,
    },
  }
}

describe('gc_identity NUI', () => {
  beforeEach(() => { document.body.innerHTML = '<main id="app" aria-live="polite"></main>' })
  afterEach(() => { vi.useRealTimers() })

  it('keeps the inactive root transparent, hidden and without overlays', () => {
    const { root, app } = createApp()
    expect(root.innerHTML).toBe('')
    expect(root.hidden).toBe(true)
    expect(root.classList.contains('identity-root--active')).toBe(false)
    expect(root.querySelector('.identity-shell')).toBeNull()
    expect(getComputedStyle(root).backgroundColor).toBe('rgba(0, 0, 0, 0)')
    app.destroy()
  })

  it('keeps an already-ready identity hidden without a black flash', () => {
    const { root, app } = createApp()
    app.receive({ type: 'snapshot', payload: { ...registration, state: 'ready' } })
    expect(root.innerHTML).toBe('')
    expect(root.hidden).toBe(true)
    app.destroy()
  })

  it('mounts one opaque fixed fullscreen shell for registration', () => {
    const { root, app } = createApp()
    app.receive({ type: 'snapshot', payload: registration })
    const shell = root.querySelector<HTMLElement>('.identity-shell')!
    expect(root.hidden).toBe(false)
    expect(root.dataset.view).toBe('registration')
    expect(root.querySelectorAll('.identity-shell')).toHaveLength(1)
    expect(shell.dataset.shellView).toBe('registration')
    expect(root.querySelector('#fullName')).not.toBeNull()
    expect(root.querySelector('input[type="password"]')).toBeNull()
    app.destroy()
  })

  it('uses the same fullscreen shell for new-IP verification', () => {
    const { root, app } = createApp()
    app.receive({ type: 'snapshot', payload: verification('authentication') })
    expect(root.dataset.view).toBe('login-verification')
    expect(root.querySelectorAll('.identity-shell')).toHaveLength(1)
    expect(root.textContent).toContain('нового сетевого адреса')
    expect(root.textContent).toContain('u***@example.com')
    app.destroy()
  })

  it('keeps exactly one active view while changing registration email', () => {
    const { root, app } = createApp()
    app.receive({ type: 'snapshot', payload: registration })
    app.receive({ type: 'snapshot', payload: verification('registration') })
    app.receive({
      type: 'snapshot',
      payload: {
        ...registration,
        registration: { ...registration.registration!, fullName: 'John Smith' },
      },
    })
    expect(root.dataset.view).toBe('registration')
    expect(root.querySelectorAll('.identity-shell')).toHaveLength(1)
    expect(root.querySelector<HTMLInputElement>('#fullName')?.value).toBe('John Smith')
    expect(root.querySelector('#verificationCode')).toBeNull()
    app.destroy()
  })

  it('renders a controlled lifecycle failure and reset removes every layer', () => {
    const { root, app } = createApp()
    app.receive({ type: 'lifecycleError', payload: { code: 'GC-IDENTITY-HELLO-TIMEOUT' } })
    expect(root.hidden).toBe(false)
    expect(root.dataset.view).toBe('fatal-error')
    expect(root.textContent).toContain('GC-IDENTITY-HELLO-TIMEOUT')
    app.receive({ type: 'reset' })
    expect(root.innerHTML).toBe('')
    expect(root.hidden).toBe(true)
    expect(root.querySelector('.identity-shell')).toBeNull()
    app.receive({ type: 'reset' })
    expect(root.innerHTML).toBe('')
    app.destroy()
  })

  it('shows a protected spawn transition until the authoritative state changes', () => {
    const { root, app } = createApp()
    app.receive({ type: 'snapshot', payload: { ...registration, state: 'spawn_releasing' } })
    expect(root.dataset.view).toBe('spawn-transition')
    expect(root.textContent).toContain('Входим на сервер')
    expect(root.querySelectorAll('.identity-shell')).toHaveLength(1)
    app.receive({ type: 'snapshot', payload: { ...registration, state: 'ready' } })
    expect(root.hidden).toBe(true)
    expect(root.innerHTML).toBe('')
    app.destroy()
  })

  it('fails an unknown view closed instead of preserving a stale overlay', () => {
    const { root, app } = createApp()
    app.receive({
      type: 'snapshot',
      payload: { ...registration, state: 'future_state' } as unknown as IdentitySnapshot,
    })
    expect(root.dataset.view).toBe('fatal-error')
    expect(root.textContent).toContain('GC-IDENTITY-NUI-UNKNOWN-VIEW')
    expect(root.querySelectorAll('.identity-shell')).toHaveLength(1)
    app.destroy()
  })

  it('runs the countdown only while a verification view is active', () => {
    vi.useFakeTimers()
    const { root, app } = createApp()
    expect(vi.getTimerCount()).toBe(0)
    app.receive({ type: 'snapshot', payload: verification('registration') })
    expect(root.dataset.view).toBe('registration-verification')
    expect(vi.getTimerCount()).toBe(2)
    vi.advanceTimersByTime(20)
    expect(vi.getTimerCount()).toBe(1)
    app.receive({ type: 'reset' })
    expect(vi.getTimerCount()).toBe(0)
    app.destroy()
  })

  it('acknowledges presentation only after the fullscreen shell reaches a frame', () => {
    vi.useFakeTimers()
    const invoke = vi.fn().mockResolvedValue({ ok: true })
    const { app } = createApp({ invoke })
    app.receive({ type: 'snapshot', payload: registration })
    expect(invoke).not.toHaveBeenCalledWith('presented', expect.anything())
    vi.advanceTimersByTime(20)
    expect(invoke).toHaveBeenCalledWith('presented', { view: 'registration' })
    app.destroy()
  })

  it('sanitizes a pasted verification code and preserves Enter form submission', () => {
    const invoke = vi.fn().mockResolvedValue({ ok: true })
    const { root, app } = createApp({ invoke })
    app.receive({ type: 'snapshot', payload: verification('registration') })
    const input = root.querySelector<HTMLInputElement>('#verificationCode')!
    input.value = '48a39-21'
    input.dispatchEvent(new Event('input', { bubbles: true }))
    expect(input.value).toBe('483921')
    input.form!.dispatchEvent(new SubmitEvent('submit', { bubbles: true, cancelable: true }))
    expect(invoke).toHaveBeenCalledWith('verifyEmail', { code: '483921' })
    app.destroy()
  })

  it('uses an inert ready bridge in standalone browser development', async () => {
    await expect(nuiBridge.invoke('ready', {})).resolves.toEqual({ ok: true })
  })

  it('blocks duplicate registration while the first callback is pending', async () => {
    const pending = deferred<{ ok: boolean }>()
    const invoke = vi.fn().mockReturnValue(pending.promise)
    const { root, app } = createApp({ invoke })
    app.receive({ type: 'snapshot', payload: registration })
    const form = root.querySelector<HTMLFormElement>('[data-form="registration"]')!
    root.querySelector<HTMLInputElement>('#fullName')!.value = 'John Smith'
    root.querySelector<HTMLInputElement>('#email')!.value = 'player@example.test'
    form.dispatchEvent(new SubmitEvent('submit', { bubbles: true, cancelable: true }))
    form.dispatchEvent(new SubmitEvent('submit', { bubbles: true, cancelable: true }))
    expect(invoke).toHaveBeenCalledTimes(1)
    expect(invoke).toHaveBeenCalledWith('sendRegistrationCode', {
      fullName: 'John Smith',
      email: 'player@example.test',
    })
    pending.resolve({ ok: true })
    await pending.promise
    app.destroy()
  })

  it('requires confirmation before exit and unmounts before disconnect', () => {
    const invoke = vi.fn().mockResolvedValue({ ok: true })
    const { root, app } = createApp({ invoke })
    app.receive({ type: 'snapshot', payload: registration })
    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }))
    expect(root.querySelector('[role="dialog"]')).not.toBeNull()
    root.querySelector<HTMLElement>('[data-action="confirm-exit"]')!.click()
    expect(invoke).toHaveBeenCalledWith('exit', {})
    expect(root.hidden).toBe(true)
    expect(root.innerHTML).toBe('')
    app.destroy()
  })

  it('escapes character names received from the server boundary', () => {
    const { root, app } = createApp()
    app.receive({
      type: 'snapshot',
      payload: {
        ...registration,
        state: 'character_required',
        account: {
          id: 1,
          email: 'safe@example.test',
          firstName: 'John',
          lastName: 'Smith',
          displayName: 'John Smith',
          status: 'active',
          createdAt: 1,
        },
        characters: [{ id: 1, firstName: '<img src=x>', lastName: 'Player', createdAt: 1 }],
      },
    })
    expect(root.querySelector('img')).toBeNull()
    expect(root.textContent).toContain('<img src=x> Player')
    app.destroy()
  })

  it('requires explicit finalization after the registration code is verified', () => {
    const invoke = vi.fn().mockResolvedValue({ ok: true })
    const { root, app } = createApp({ invoke })
    app.receive({
      type: 'snapshot',
      payload: {
        ...registration,
        state: 'registration_verified',
        verification: null,
        registration: {
          fullName: 'John Smith',
          email: 'player@example.test',
          emailVerified: true,
          profileOnly: false,
        },
      },
    })
    expect(root.dataset.view).toBe('registration-verified')
    expect(invoke).not.toHaveBeenCalled()
    root.querySelector<HTMLElement>('[data-action="finalize-registration"]')!.click()
    expect(invoke).toHaveBeenCalledWith('finalizeRegistration', {})
    app.destroy()
  })
})
