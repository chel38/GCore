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
