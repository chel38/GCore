import type { NuiBridge, NuiResponse } from './types'

declare global {
  interface Window {
    GetParentResourceName?: () => string
  }
}

function resourceName(): string {
  return window.GetParentResourceName?.() ?? 'gc_identity'
}

export const nuiBridge: NuiBridge = {
  async invoke<TPayload extends object>(callback: string, payload: TPayload): Promise<NuiResponse> {
    // EN: Browser development has no FiveM callback endpoint. Keep the transport
    // inert there; production uses GetParentResourceName and the real NUI bridge.
    // RU: В браузерной разработке нет FiveM callback endpoint. Там transport
    // остаётся inert; production использует GetParentResourceName и реальный NUI.
    if (typeof window.GetParentResourceName !== 'function') {
      return { ok: true }
    }

    const response = await fetch(`https://${resourceName()}/${callback}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(payload),
    })

    if (!response.ok) {
      return { ok: false, code: 'GC-IDENTITY-NUI-TRANSPORT' }
    }

    return (await response.json()) as NuiResponse
  },
}
