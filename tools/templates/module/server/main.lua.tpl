-- EN: Check the public contract at startup; never import gc_core internals.
-- RU: Проверяйте Public Contract при старте; не импортируйте internals gc_core.

{{CORE_CHECK}}

print(('[GC][{{MODULE_NAME}}] resource ready / core API >= 1'))
