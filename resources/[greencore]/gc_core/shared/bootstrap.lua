-- RU: Инициализация общих глобальных таблиц GreenCore.
-- EN: Initialization of shared GreenCore global tables.

-- RU: Этот файл загружается первым среди shared-скриптов.
-- EN: This file is loaded first among the shared scripts.

-- RU: Корневая таблица конфигурации.
-- EN: Root configuration table.
GCConfig = GCConfig or {}

-- RU: Корневая таблица локализации.
-- EN: Root localization table.
GCLocales = GCLocales or {}

-- RU: Версия ядра.
-- EN: Core version.
GCVersion = GCVersion or {}

-- RU: Константы ядра.
-- EN: Core constants.
GCConstants = GCConstants or {}

-- RU: Таблица ошибок ядра.
-- EN: Core error table.
GCErrors = GCErrors or {}

-- RU: Утилиты ядра.
-- EN: Core utilities.
GCUtils = GCUtils or {}

-- RU: Сервис локализации.
-- EN: Localization service.
GCLocale = GCLocale or {}

-- RU: Сервис логирования.
-- EN: Logging service.
GCLogger = GCLogger or {}

-- RU: Сервис валидации.
-- EN: Validation service.
GCValidation = GCValidation or {}

-- RU: Сервис диагностики.
-- EN: Diagnostics service.
GCDiagnostics = GCDiagnostics or {}

-- RU: Серверные сервисы (доступны только на сервере).
-- EN: Server services (available only on the server).
if IsDuplicityVersion then
    GCConnection = GCConnection or {}
    GCIdentifiers = GCIdentifiers or {}
    GCSessions = GCSessions or {}
    GCStates = GCStates or {}
    GCSpawn = GCSpawn or {}
    GCRateLimit = GCRateLimit or {}
    GCSecurity = GCSecurity or {}
    GCPedProvider = GCPedProvider or {}
    GCSpawnLocationProvider = GCSpawnLocationProvider or {}
end

-- RU: Клиентские сервисы (доступны только на клиенте).
-- EN: Client services (available only on the client).
if not IsDuplicityVersion then
    GCClientState = GCClientState or {}
    GCClientReadiness = GCClientReadiness or {}
    GCClientSpawn = GCClientSpawn or {}
    GCClientDiagnostics = GCClientDiagnostics or {}
end