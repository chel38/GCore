import './style.css'
import { createIdentityApp } from './app'
import { nuiBridge } from './bridge'
import type { NuiMessage } from './types'

const root = document.querySelector<HTMLElement>('#app')
if (!root) throw new Error('gc_identity NUI root is missing')

const app = createIdentityApp(root, nuiBridge)
window.addEventListener('message', (event: MessageEvent<NuiMessage>) => {
  if (event.data?.type === 'snapshot'
    || event.data?.type === 'rejected'
    || event.data?.type === 'lifecycleError'
    || event.data?.type === 'reset') {
    app.receive(event.data)
  }
})

void nuiBridge.invoke('ready', {}).then((response) => {
  if (!response.ok) {
    app.receive({
      type: 'lifecycleError',
      payload: { code: response.code ?? 'GC-IDENTITY-NUI-TRANSPORT' },
    })
  }
}).catch(() => {
  app.receive({ type: 'lifecycleError', payload: { code: 'GC-IDENTITY-NUI-TRANSPORT' } })
})
