-- RU: Инициализация серверной части GreenCore.
-- EN: GreenCore server-side initialization.

-- RU: Этот файл загружается первым среди server-скриптов.
-- EN: This file is loaded first among the server scripts.

-- RU: Инициализируем генератор случайных чисел.
-- EN: Initialize the random number generator.
math.randomseed(os.time())

GCRuntime.AssertServer('gc_core server/bootstrap.lua')

-- RU: Инициализируем серверные сервисы.
-- EN: Initialize the server services.
GCConnection = GCConnection or {}
GCIdentifiers = GCIdentifiers or {}
GCSessions = GCSessions or {}
GCStates = GCStates or {}
GCSpawn = GCSpawn or {}
GCRateLimit = GCRateLimit or {}
GCSecurity = GCSecurity or {}
GCNotifications = GCNotifications or {}
GCDiagnostics = GCDiagnostics or {}
GCPedProvider = GCPedProvider or {}
GCSpawnLocationProvider = GCSpawnLocationProvider or {}
GCPlayers = GCPlayers or {}
GCAPI = GCAPI or {}
GCServerRuntime = GCServerRuntime or {}

-- RU: Имя текущего ресурса.
-- EN: Current resource name.
local currentResource = GetCurrentResourceName()

-- RU: Проверяем, что ресурс называется gc_core.
-- EN: Verify that the resource is named gc_core.
if currentResource ~= GCConstants.resourceName then
    GCLogger.Warn('GC-BOOT-001', 'Resource name mismatch', {
        expected = GCConstants.resourceName,
        actual = currentResource
    })
end

-- RU: Логируем запуск серверной части.
-- EN: Log the server-side startup.
GCLogger.Info('GC-BOOT-100', 'gc_core server bootstrap loaded', {
    version = GCVersion.GetString()
})

-- RU: Проверки конфигурации и фоновые задачи запускаются из server/main.lua,
-- RU: когда все серверные сервисы уже загружены манифестом.
-- EN: Configuration validation and background jobs are started from
-- EN: server/main.lua after all server services have been loaded by the manifest.
