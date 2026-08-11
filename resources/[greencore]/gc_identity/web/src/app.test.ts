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

describe('gc_identity NUI', () => {
  beforeEach(() => { document.body.innerHTML = '<main id="app"></main>' })

  it('stays visually hidden until Lua sends an authoritative state', () => {
    const root = document.querySelector<HTMLElement>('#app')!
    const app = createIdentityApp(root, { invoke: vi.fn().mockResolvedValue({ ok: true }) })
    expect(root.innerHTML).toBe('')
    expect(root.hidden).toBe(true)
    expect(root.querySelector('.identity-shell')).toBeNull()
    app.destroy()
  })

  it('keeps an already-ready identity hidden without a black flash', () => {
    const root = document.querySelector<HTMLElement>('#app')!
    const app = createIdentityApp(root, { invoke: vi.fn().mockResolvedValue({ ok: true }) })
    app.receive({ type: 'snapshot', payload: { ...registration, state: 'ready' } })
    expect(root.innerHTML).toBe('')
    expect(root.hidden).toBe(true)
    app.destroy()
  })

  it('renders a terminal lifecycle error with retry instead of an empty black layer', () => {
    const root = document.querySelector<HTMLElement>('#app')!
    const app = createIdentityApp(root, { invoke: vi.fn().mockResolvedValue({ ok: true }) })
    app.receive({ type: 'lifecycleError', payload: { code: 'GC-IDENTITY-HELLO-TIMEOUT' } })
    expect(root.hidden).toBe(false)
    expect(root.querySelector('[data-view="lifecycle-error"]')).not.toBeNull()
    expect(root.textContent).toContain('GC-IDENTITY-HELLO-TIMEOUT')
    app.receive({ type: 'reset' })
    expect(root.innerHTML).toBe('')
    expect(root.hidden).toBe(true)
    app.destroy()
  })

  it('uses an inert ready bridge in standalone browser development', async () => {
    await expect(nuiBridge.invoke('ready', {})).resolves.toEqual({ ok: true })
  })

  it('renders registration without a password field', () => {
    const bridge: NuiBridge = { invoke: vi.fn().mockResolvedValue({ ok: true }) }
    const root = document.querySelector<HTMLElement>('#app')!
    const app = createIdentityApp(root, bridge)
    app.receive({ type: 'snapshot', payload: registration })
    expect(root.hidden).toBe(false)
    expect(root.querySelector('[data-view="registration"]')).not.toBeNull()
    expect(root.querySelector('#fullName')).not.toBeNull()
    expect(root.querySelector('input[type="password"]')).toBeNull()
    app.destroy()
  })

  it('renders verification without exposing the expected code', () => {
    const root = document.querySelector<HTMLElement>('#app')!
    const app = createIdentityApp(root, { invoke: vi.fn().mockResolvedValue({ ok: true }) })
    app.receive({
      type: 'snapshot',
      payload: {
        ...registration,
        state: 'email_verification_pending',
        verification: {
          type: 'registration',
          maskedEmail: 'u***@example.com',
          expiresIn: 300,
          resendIn: 60,
        },
      },
    })
    expect(root.querySelector('[data-view="verification"]')).not.toBeNull()
    expect(root.textContent).toContain('u***@example.com')
    expect(root.querySelector<HTMLInputElement>('#verificationCode')?.value).toBe('')
    app.destroy()
  })

  it('blocks duplicate registration while the first callback is pending', async () => {
    const pending = deferred<{ ok: boolean }>()
    const invoke = vi.fn().mockReturnValue(pending.promise)
    const root = document.querySelector<HTMLElement>('#app')!
    const app = createIdentityApp(root, { invoke })
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

  it('requires confirmation before exit and supports Escape', () => {
    const invoke = vi.fn().mockResolvedValue({ ok: true })
    const root = document.querySelector<HTMLElement>('#app')!
    const app = createIdentityApp(root, { invoke })
    app.receive({ type: 'snapshot', payload: registration })
    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }))
    expect(root.querySelector('[role="dialog"]')).not.toBeNull()
    root.querySelector<HTMLElement>('[data-action="confirm-exit"]')!.click()
    expect(invoke).toHaveBeenCalledWith('exit', {})
    app.destroy()
  })

  it('escapes character names received from the server boundary', () => {
    const root = document.querySelector<HTMLElement>('#app')!
    const app = createIdentityApp(root, { invoke: vi.fn().mockResolvedValue({ ok: true }) })
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

  it('requires an explicit finalization after a registration code was verified', () => {
    const invoke = vi.fn().mockResolvedValue({ ok: true })
    const root = document.querySelector<HTMLElement>('#app')!
    const app = createIdentityApp(root, { invoke })
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
    expect(root.querySelector('[data-view="registration-verified"]')).not.toBeNull()
    expect(invoke).not.toHaveBeenCalled()
    root.querySelector<HTMLElement>('[data-action="finalize-registration"]')!.click()
    expect(invoke).toHaveBeenCalledWith('finalizeRegistration', {})
    app.destroy()
  })
})
