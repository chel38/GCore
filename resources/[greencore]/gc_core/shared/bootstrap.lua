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

-- RU: Единый сервис определения runtime-контекста.
-- EN: Single runtime-context service.
GCRuntime = GCRuntime or {}

-- RU: Реестр сетевого протокола и генератор корреляционных ID.
-- EN: Network protocol registry and correlation ID generator.
GCEvents = GCEvents or {}
GCIds = GCIds or {}

-- RU: Сервис диагностики.
-- EN: Diagnostics service.
GCDiagnostics = GCDiagnostics or {}

-- Side-specific services are initialized by server/bootstrap.lua and
-- client/bootstrap.lua after GCRuntime has asserted the execution context.
