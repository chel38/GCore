-- RU: Сервис проверки подключения игрока GreenCore.
-- EN: GreenCore player connection validation service.

-- RU: Таблица сервиса подключения.
-- EN: Connection service table.
GCConnection = {}

--- RU:
--- Возвращает язык игрока для сообщений.
--- Использует язык сессии, если она существует, иначе язык по умолчанию.
---
--- EN:
--- Returns the player language for messages.
--- Uses the session language if it exists, otherwise the default language.
---
--- @param playerSource number FiveM server player source
--- @return string locale Language code
function GCConnection.GetPlayerLocale(playerSource)
    -- RU: Проверяем корректность source.
    -- EN: Validate the source.
    if type(playerSource) ~= 'number' then
        return GCConfig.General.locale or 'en'
    end

    -- RU: Пытаемся получить локаль из сессии.
    -- EN: Try to get the locale from the session.
    local session = GCSessions.Get(playerSource)

    if session and session.metadata and session.metadata.locale then
        return session.metadata.locale
    end

    -- RU: Возвращаем локаль по умолчанию.
    -- EN: Return the default locale.
    return GCConfig.General.locale or 'en'
end

--- RU:
--- Проверяет корректность имени игрока.
---
--- EN:
--- Validates the player name.
---
--- @param playerName any Player name
--- @return boolean valid Whether the name is valid
--- @return string|nil errorCode Error code
local function validatePlayerName(playerName)
    -- RU: Имя должно быть строкой.
    -- EN: Name must be a string.
    if type(playerName) ~= 'string' then
        return false, 'GC-CONNECTION-001'
    end

    -- RU: Имя не должно быть пустым.
    -- EN: Name must not be empty.
    if #playerName < GCConstants.minPlayerNameLength then
        return false, 'GC-CONNECTION-001'
    end

    -- RU: Имя не должно превышать допустимую длину.
    -- EN: Name must not exceed the allowed length.
    if #playerName > GCConstants.maxPlayerNameLength then
        return false, 'GC-CONNECTION-001'
    end

    return true
end

--- RU:
--- Проверяет наличие обязательного идентификатора.
---
--- EN:
--- Validates the presence of the mandatory identifier.
---
--- @param identifiers table Player identifiers
--- @return boolean valid Whether the identifier is present
--- @return string|nil errorCode Error code
local function validateMandatoryIdentifier(identifiers)
    -- RU: Проверяем наличие license.
    -- EN: Check for the presence of license.
    local license = identifiers[GCConstants.primaryIdentifierType]

    if license then
        return true
    end

    -- RU: Проверяем наличие license2, если разрешено.
    -- EN: Check for the presence of license2 if allowed.
    if GCConfig.Connection.allowLicense2Fallback then
        local license2 = identifiers[GCConstants.fallbackIdentifierType]

        if license2 then
            return true
        end
    end

    return false, 'GC-CONNECTION-002'
end

--- RU:
--- Проверяет отсутствие дубликата подключения.
---
--- EN:
--- Checks for the absence of a duplicate connection.
---
--- @param identifiers table Player identifiers
--- @return boolean valid Whether there is no duplicate
--- @return string|nil errorCode Error code
local function validateNoDuplicate(identifiers)
    -- RU: Получаем основной идентификатор.
    -- EN: Get the primary identifier.
    local primary = identifiers[GCConstants.primaryIdentifierType]

    if not primary and GCConfig.Connection.allowLicense2Fallback then
        primary = identifiers[GCConstants.fallbackIdentifierType]
    end

    if not primary then
        return true
    end

    -- RU: Проверяем, есть ли активная сессия с этим идентификатором.
    -- EN: Check whether there is an active session with this identifier.
    local existingSession = GCSessions.GetByIdentifier(primary)

    if existingSession then
        return false, 'GC-CONNECTION-003'
    end

    return true
end

--- RU:
--- Обрабатывает подключение игрока.
---
--- EN:
--- Handles a player connection.
---
--- @param playerName string Player name
--- @param setKickReason function Function to set the kick reason
--- @param deferrals table Deferrals object
function GCConnection.HandleConnecting(playerName, setKickReason, deferrals)
    -- RU: Получаем source игрока.
    -- EN: Get the player source.
    local playerSource = source

    -- RU: Определяем язык для сообщений игроку.
    -- EN: Determine the language for player-facing messages.
    local locale = GCConfig.General.locale or 'en'

    -- RU: Флаг завершения deferrals. Защищает от повторного вызова done().
    -- EN: Deferral completion flag. Guards against calling done() twice.
    local deferralHandled = false

    -- RU: Локальная функция завершения deferrals с защитой от дублирования.
    -- EN: Local function to finish deferrals with duplicate protection.
    local function done(message)
        if deferralHandled then
            return
        end

        deferralHandled = true
        deferrals.done(message)
    end

    -- RU: Проверяем корректность source.
    -- EN: Validate the source.
    if type(playerSource) ~= 'number' then
        setKickReason('Invalid player source')
        done('Invalid player source')
        return
    end

    -- RU: Проверяем, не заблокированы ли подключения.
    -- EN: Check whether connections are blocked.
    if GCSecurity.AreConnectionsBlocked() then
        setKickReason(GC_T(locale, 'connection.server_stopping'))
        done(GC_T(locale, 'connection.server_stopping'))
        return
    end

    -- RU: Проверяем, не остановлен ли ресурс.
    -- EN: Check whether the resource is stopping.
    if GCSecurity.IsResourceStopping() then
        setKickReason(GC_T(locale, 'connection.server_stopping'))
        done(GC_T(locale, 'connection.server_stopping'))
        return
    end

    -- RU: Запускаем deferrals.
    -- EN: Start deferrals.
    deferrals.update(GC_T(locale, 'connection.checking'))

    -- RU: Добавляем тайм-аут для deferrals, чтобы не зависеть навсегда.
    -- EN: Add a timeout for deferrals to avoid hanging forever.
    SetTimeout(GCConfig.Connection.deferralTimeoutMs, function()
        -- RU: Если подключение уже обработано, ничего не делаем.
        -- EN: If the connection was already handled, do nothing.
        if deferralHandled then
            return
        end

        -- RU: Завершаем ожидание с сообщением об истечении времени.
        -- EN: End the wait with a timeout message.
        setKickReason(GC_T(locale, 'connection.timeout'))
        done(GC_T(locale, 'connection.timeout'))
    end)

    -- RU: Проверяем имя игрока.
    -- EN: Validate the player name.
    local nameValid, nameError = validatePlayerName(playerName)

    if not nameValid then
        setKickReason(GC_T(locale, 'connection.rejected'))
        done(GC_T(locale, 'connection.rejected'))
        return
    end

    -- RU: Собираем идентификаторы игрока.
    -- EN: Collect the player identifiers.
    local identifiers = GCIdentifiers.GetAll(playerSource)

    -- RU: Проверяем наличие обязательного идентификатора.
    -- EN: Validate the presence of the mandatory identifier.
    local licenseValid, licenseError = validateMandatoryIdentifier(identifiers)

    if not licenseValid then
        setKickReason(GC_T(locale, 'connection.license_missing'))
        done(GC_T(locale, 'connection.license_missing'))
        return
    end

    -- RU: Проверяем отсутствие дубликата подключения.
    -- EN: Check for the absence of a duplicate connection.
    if GCConfig.Connection.rejectDuplicateLicense then
        local duplicateValid, duplicateError = validateNoDuplicate(identifiers)

        if not duplicateValid then
            setKickReason(GC_T(locale, 'connection.duplicate'))
            done(GC_T(locale, 'connection.duplicate'))
            return
        end
    end

    -- RU: Создаём временную сессию.
    -- EN: Create a temporary session.
    local session, sessionError = GCSessions.Create(playerSource, playerName, identifiers)

    if not session then
        setKickReason(GC_T(locale, 'error.internal'))
        done(GC_T(locale, 'error.internal'))
        return
    end

    -- RU: Разрешаем подключение.
    -- EN: Allow the connection.
    done()

    -- RU: Переводим игрока в состояние validated.
    -- EN: Move the player to the validated state.
    GCStates.Set(playerSource, 'validated', 'connection_validated')

    -- RU: Переводим игрока в состояние joining.
    -- EN: Move the player to the joining state.
    GCStates.Set(playerSource, 'joining', 'connection_accepted')

    -- RU: Записываем диагностический лог.
    -- EN: Write a diagnostic log.
    if GCConfig.Diagnostics.enabled and GCConfig.Diagnostics.verboseConnection then
        local logData = {
            source = playerSource,
            playerName = playerName
        }

        -- RU: Добавляем маскированный идентификатор, если разрешено.
        -- EN: Add the masked identifier if allowed.
        if GCConfig.Diagnostics.printMaskedIdentifiers then
            logData.primaryIdentifier = GCIdentifiers.Mask(session.primaryIdentifier or '')
        end

        GCLogger.Debug('GC-CONNECTION-100', 'Connection accepted', logData)
    end
end

--- RU:
--- Обрабатывает готовность клиента.
---
--- EN:
--- Handles client readiness.
---
--- @param playerSource number FiveM server player source
--- @param payload table Client readiness payload
function GCConnection.HandleClientReady(playerSource, payload)
    -- RU: Проверяем, что сессия существует.
    -- EN: Verify that the session exists.
    local session = GCSessions.Get(playerSource)

    if not session then
        return
    end

    -- RU: Проверяем, что игрок находится в состоянии joining.
    -- EN: Verify that the player is in the joining state.
    if not GCStates.Is(playerSource, 'joining') then
        return
    end

    -- RU: Сохраняем метаданные клиента.
    -- EN: Save the client metadata.
    session.metadata.clientVersion = payload.clientVersion
    session.metadata.protocolVersion = payload.protocolVersion

    if payload.locale then
        session.metadata.locale = payload.locale
    end

    -- RU: Переводим игрока в состояние client_ready.
    -- EN: Move the player to the client_ready state.
    local success, errorCode = GCStates.Set(playerSource, 'client_ready', 'client_reported_ready')

    if not success then
        return
    end

    -- RU: Отправляем клиенту подтверждение подключения.
    -- EN: Send the connection acceptance to the client.
    TriggerClientEvent('gc_core:client:connectionAccepted', playerSource, {
        apiVersion = GCConfig.General.apiVersion,
        protocolVersion = GCConfig.General.protocolVersion
    })
end