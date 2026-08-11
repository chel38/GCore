import { createIdentityApp } from './app'
import { nuiBridge } from './bridge'
import type { IdentitySnapshot, NuiBridge } from './types'

const registration: IdentitySnapshot = {
  protocolVersion: 1,
  state: 'registration_required',
  account: null,
  characters: [],
  selectedCharacter: null,
  limits: { maxCharacters: 3 },
  passwordAuthentication: false,
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
    expect(root.querySelector('input[type="password"]')).toBeNull()
    app.destroy()
  })

  it('blocks duplicate registration while the first callback is pending', async () => {
    const pending = deferred<{ ok: boolean }>()
    const invoke = vi.fn().mockReturnValue(pending.promise)
    const root = document.querySelector<HTMLElement>('#app')!
    const app = createIdentityApp(root, { invoke })
    app.receive({ type: 'snapshot', payload: registration })
    const form = root.querySelector<HTMLFormElement>('[data-form="registration"]')!
    root.querySelector<HTMLInputElement>('#email')!.value = 'player@example.test'
    form.dispatchEvent(new SubmitEvent('submit', { bubbles: true, cancelable: true }))
    form.dispatchEvent(new SubmitEvent('submit', { bubbles: true, cancelable: true }))
    expect(invoke).toHaveBeenCalledTimes(1)
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
        account: { id: 1, email: 'safe@example.test', status: 'active', createdAt: 1 },
        characters: [{ id: 1, firstName: '<img src=x>', lastName: 'Player', createdAt: 1 }],
      },
    })
    expect(root.querySelector('img')).toBeNull()
    expect(root.textContent).toContain('<img src=x> Player')
    app.destroy()
  })
})
