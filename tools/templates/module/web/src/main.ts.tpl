import './style.css'

const root = document.querySelector<HTMLElement>('#app')
if (!root) throw new Error('{{MODULE_NAME}} NUI root is missing')

// EN: Lua must explicitly authorize visibility through the module protocol.
// RU: Lua явно разрешает видимость через protocol этого module.
root.hidden = true
