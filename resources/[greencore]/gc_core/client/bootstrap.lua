-- RU: Инициализация клиентской части GreenCore.
-- EN: GreenCore client-side initialization.

-- RU: Этот файл загружается первым среди client-скриптов.
-- EN: This file is loaded first among the client scripts.

GCRuntime.AssertClient('gc_core client/bootstrap.lua')

-- RU: Инициализируем клиентские сервисы.
-- EN: Initialize the client services.
GCClientState = GCClientState or {}
GCClientReadiness = GCClientReadiness or {}
GCClientSpawn = GCClientSpawn or {}
GCClientDiagnostics = GCClientDiagnostics or {}

-- RU: Логируем запуск клиентской части.
-- EN: Log the client-side startup.
GCLogger.Info('GC-CLIENT-100', 'gc_core client bootstrap loaded', {
    version = GCVersion.GetString()
})
