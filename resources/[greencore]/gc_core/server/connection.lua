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
--- @return string|nil primaryType Primary identifier type used
local function validateMandatoryIdentifier(identifiers)
    -- RU: Проверяем наличие license.
    -- EN: Check for the presence of license.
    local license = identifiers[GCConstants.primaryIdentifierType]

    if license then
        return true, nil, GCConstants.primaryIdentifierType
    end

    -- RU: Проверяем наличие license2, если разрешено.
    -- EN: Check for the presence of license2 if allowed.
    if GCConfig.Connection.allowLicense2Fallback then
        local license2 = identifiers[GCConstants.fallbackIdentifierType]

        if license2 then
            return true, nil, GCConstants.fallbackIdentifierType
        end
    end

    -- RU: Если обязательный license отключён, разрешаем подключение без primary ID.
    -- EN: If the mandatory license is disabled, allow a connection without a primary ID.
    if not GCConfig.Connection.requireLicense then
        return true, nil, nil
    end

    return false, 'GC-CONNECTION-002', nil
end

--- RU:
--- Проверяет отсутствие дубликата подключения.
--- Учитывает как активные сессии, так и pending connection.
---
--- EN:
--- Checks for the absence of a duplicate connection.
--- Considers both active sessions and pending connections.
---
--- @param identifiers table Player identifiers
--- @return boolean valid Whether there is no duplicate
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

    -- RU: Проверяем, используется ли идентификатор в активной или pending сессии.
    -- EN: Check whether the identifier is in use by an active or pending session.
    if GCSessions.IsIdentifierInUse(primary) then
        return false, 'GC-CONNECTION-003'
    end

    return true
end

--- RU:
--- Обрабатывает подключение игрока (playerConnecting).
--- Соблюдает корректный lifecycle FiveM deferrals:
---   1. deferrals.defer()
---   2. Wait(0) — пропускаем минимум один tick
---   3. deferrals.update(...)
---   4. Wait(0)
---   5. Валидация
---   6. deferrals.done()
---
--- ВАЖНО: source здесь является ВРЕМЕННЫМ. Создаётся pending connection,
--- которая позже (playerJoining) мигрируется в активную сессию с финальным source.
---
--- EN:
--- Handles a player connection (playerConnecting).
--- Follows the correct FiveM deferral lifecycle:
---   1. deferrals.defer()
---   2. Wait(0) — skip at least one tick
---   3. deferrals.update(...)
---   4. Wait(0)
---   5. Validation
---   6. deferrals.done()
---
--- IMPORTANT: the source here is TEMPORARY. A pending connection is created,
--- which later (playerJoining) migrates to an active session with the final source.
---
--- @param playerName string Player name
--- @param setKickReason function Function to set the kick reason
--- @param deferrals table Deferrals object
function GCConnection.HandleConnecting(playerName, setKickReason, deferrals)
    -- RU: Получаем временный source игрока.
    -- EN: Get the temporary player source.
    local temporarySource = source

    -- RU: Определяем язык для сообщений игроку.
    -- EN: Determine the language for player-facing messages.
    local locale = GCConfig.General.locale or 'en'
    -- EN: The temporary player source has a deliberately limited native lifetime.
    -- Read identifiers before the first yield, matching the official Cfx flow.
    -- RU: Временный source игрока имеет намеренно ограниченный lifetime native.
    -- Читаем идентификаторы до первого yield, как в официальном Cfx flow.
    local identifiers = type(temporarySource) == 'number'
        and GCIdentifiers.GetAll(temporarySource)
        or {}
    local deferralStartedAt = GCUtils.NowMs()
    local deferralTimeoutMs = GCConfig.Connection.deferralTimeoutMs or 15000

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

        -- EN: Cfx's runtime-owned function reference distinguishes no arguments
        -- from one explicit nil argument. The latter can crash the Mono bridge.
        -- RU: Runtime-owned function reference Cfx различает отсутствие аргументов
        -- и один явный nil; второй вариант может аварийно завершить Mono bridge.
        if message == nil then
            deferrals.done()
        else
            deferrals.done(message)
        end
    end

    -- EN: The Cfx deferrals object contains runtime-owned function references.
    -- Keeping those references in SetTimeout after playerConnecting returns can
    -- crash FXServer's Mono bridge. Validation below is synchronous and bounded,
    -- so the deadline is checked inside the original event coroutine instead.
    --
    -- RU: Объект Cfx deferrals содержит function reference, которыми владеет
    -- runtime. Их захват в SetTimeout после завершения playerConnecting может
    -- аварийно завершить Mono bridge FXServer. Проверки ниже синхронны и
    -- ограничены, поэтому deadline проверяется в исходной coroutine события.
    local function finishIfTimedOut()
        if GCUtils.NowMs() - deferralStartedAt < deferralTimeoutMs then
            return false
        end

        GCSessions.RemovePendingConnection(temporarySource)

        local message = GC_T(locale, 'connection.timeout')
        setKickReason(message)
        done(message)

        return true
    end

    -- RU: Шаг 1: начинаем deferrals.
    -- EN: Step 1: start deferrals.
    deferrals.defer()

    -- RU: Шаг 2: пропускаем минимум один tick, как требует FiveM.
    -- EN: Step 2: skip at least one tick, as FiveM requires.
    Wait(0)

    -- RU: Проверяем корректность source.
    -- EN: Validate the source.
    if type(temporarySource) ~= 'number' then
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

    -- RU: Шаг 3: обновляем статус deferrals.
    -- EN: Step 3: update the deferral status.
    deferrals.update(GC_T(locale, 'connection.checking'))

    -- RU: Шаг 4: пропускаем ещё один tick.
    -- EN: Step 4: skip another tick.
    Wait(0)

    if finishIfTimedOut() then
        return
    end


    -- RU: Проверяем имя игрока.
    -- EN: Validate the player name.
    local nameValid = validatePlayerName(playerName)

    if not nameValid then
        setKickReason(GC_T(locale, 'connection.rejected'))
        done(GC_T(locale, 'connection.rejected'))
        return
    end

    if finishIfTimedOut() then
        return
    end

    -- RU: Проверяем наличие обязательного идентификатора.
    -- EN: Validate the presence of the mandatory identifier.
    local licenseValid, licenseError, primaryType = validateMandatoryIdentifier(identifiers)

    if not licenseValid then
        setKickReason(GC_T(locale, 'connection.license_missing'))
        done(GC_T(locale, 'connection.license_missing'))
        return
    end

    -- RU: Проверяем отсутствие дубликата подключения.
    -- EN: Check for the absence of a duplicate connection.
    if GCConfig.Connection.rejectDuplicateLicense then
        local duplicateValid = validateNoDuplicate(identifiers)

        if not duplicateValid then
            setKickReason(GC_T(locale, 'connection.duplicate'))
            done(GC_T(locale, 'connection.duplicate'))
            return
        end
    end

    if finishIfTimedOut() then
        return
    end

    -- RU: Определяем основной идентификатор и его тип.
    -- EN: Determine the primary identifier and its type.
    local primaryIdentifier = primaryType and identifiers[primaryType] or nil

    -- RU: Создаём pending connection (НЕ активную сессию).
    -- EN: Create a pending connection (NOT an active session).
    local pending, pendingError = GCSessions.CreatePendingConnection(
        temporarySource,
        playerName,
        identifiers,
        primaryIdentifier,
        primaryType
    )

    if not pending then
        GCLogger.Warn('GC-CONNECTION-PENDING-001', 'Failed to create pending connection', {
            source = temporarySource,
            errorCode = pendingError
        })
        setKickReason(GC_T(locale, 'error.internal'))
        done(GC_T(locale, 'error.internal'))
        return
    end

    -- RU: Шаг 5/6: разрешаем подключение и завершаем deferrals.
    -- EN: Step 5/6: allow the connection and finish deferrals.
    done()

    -- RU: Записываем диагностический лог.
    -- EN: Write a diagnostic log.
    if GCConfig.Diagnostics.enabled and GCConfig.Diagnostics.verboseConnection then
        local logData = {
            source = temporarySource,
            playerName = playerName
        }

        -- RU: Добавляем маскированный идентификатор, если разрешено.
        -- EN: Add the masked identifier if allowed.
        if GCConfig.Diagnostics.printMaskedIdentifiers then
            logData.primaryIdentifier = GCIdentifiers.Mask(primaryIdentifier or '')
        end

        GCLogger.Debug('GC-CONNECTION-100', 'Pending connection created', logData)
    end
end

--- RU:
--- Обрабатывает завершение входа игрока (playerJoining).
--- FiveM передаёт oldSource (временный source) в качестве аргумента, а source
--- в контексте события уже является финальным runtime source. Здесь временная
--- pending connection мигрируется в активную сессию.
---
--- EN:
--- Handles a player joining (playerJoining).
--- FiveM passes oldSource (the temporary source) as the argument, while the source
--- in the event context is already the final runtime source. Here the temporary
--- pending connection migrates into an active session.
---
--- @param oldSource number|string|nil Temporary source from playerConnecting
--- @return boolean success Whether the promotion succeeded
function GCConnection.HandleJoining(oldSource)
    -- RU: Получаем финальный source из контекста события.
    -- EN: Get the final source from the event context.
    local finalSource = tonumber(source)

    if type(finalSource) ~= 'number' then
        return false
    end

    -- RU: Если oldSource не передан, ищем pending connection по final source.
    -- EN: If oldSource is not provided, look up the pending connection by final source.
    -- RU: FiveM передаёт oldSource как строку, хотя source в Lua является числом.
    -- EN: FiveM passes oldSource as a string even though source is numeric in Lua.
    local temporarySource = tonumber(oldSource)

    if type(temporarySource) ~= 'number' then
        local pending = GCSessions.GetPendingConnection(finalSource)

        if not pending then
            return false
        end

        temporarySource = pending.temporarySource
    end

    -- RU: Получаем pending connection.
    -- EN: Get the pending connection.
    local pending = GCSessions.GetPendingConnection(temporarySource)

    if not pending then
        -- RU: Возможно, игрок подключился до рестарта gc_core; обработаем как recovery.
        -- EN: The player may have connected before the gc_core restart; handle as recovery.
        GCLogger.Warn('GC-JOIN-001', 'No pending connection found for playerJoining', {
            temporarySource = temporarySource,
            finalSource = finalSource
        })
        return false
    end

    -- RU: Мигрируем pending connection в активную сессию.
    -- EN: Migrate the pending connection into an active session.
    local session, promoteError = GCSessions.PromotePendingConnection(temporarySource, finalSource)

    if not session then
        GCLogger.Error('GC-JOIN-002', 'Failed to promote pending connection', {
            temporarySource = temporarySource,
            finalSource = finalSource,
            errorCode = promoteError
        })
        return false
    end

    -- RU: Переводим игрока в состояние validated (валидация уже прошла).
    -- EN: Move the player to the validated state (validation already passed).
    local success, stateError = GCStates.Set(finalSource, 'validated', 'connection_validated')

    if not success then
        GCLogger.Warn('GC-JOIN-001', 'Failed to set validated state after promotion', {
            source = finalSource,
            errorCode = stateError
        })
    end

    -- RU: Переводим игрока в состояние joining.
    -- EN: Move the player to the joining state.
    local joinSuccess, joinError = GCStates.Set(finalSource, 'joining', 'connection_accepted')

    if not joinSuccess then
        GCLogger.Warn('GC-JOIN-001', 'Failed to set joining state after promotion', {
            source = finalSource,
            errorCode = joinError
        })
        GCSessions.Remove(finalSource, 'joining_state_failed')
        return false
    end

    -- RU: Сервер сам контролирует тайм-аут clientReady; клиенту доверять нельзя.
    -- EN: The server enforces the clientReady timeout; it must not trust the client.
    local sessionId = session.sessionId
    local readyTimeoutMs = GCConfig.Connection.clientReadyTimeoutMs or 30000

    SetTimeout(readyTimeoutMs, function()
        local currentSession = GCSessions.Get(finalSource)

        if not currentSession or currentSession.sessionId ~= sessionId then
            return
        end

        if GCStates.Is(finalSource, 'joining') then
            GCStates.Set(finalSource, 'error', 'client_ready_timeout')
            DropPlayer(finalSource, GC_T(GCConnection.GetPlayerLocale(finalSource), 'connection.timeout'))
        end
    end)

    return true
end

local function storeHandshakeMetadata(session, payload)
    session.metadata.clientVersion = payload.clientVersion
    session.metadata.protocolVersion = payload.protocolVersion

    if payload.locale then
        session.metadata.locale = payload.locale
    end

    if payload.isPedAlive ~= nil then
        -- RU: Это только диагностическая подсказка, а не authoritative state.
        -- EN: This is diagnostic metadata only, never authoritative state.
        session.metadata.clientPedAliveHint = payload.isPedAlive == true
    end
end

local function validateHandshakeProtocol(playerSource, payload)
    local matches, errorCode = GCValidation.ProtocolMatches(payload.protocolVersion)

    if matches then
        return true
    end

    GCLogger.Warn('GC-PROTOCOL-MISMATCH-001', '[GC][RECOVERY] Client protocol version is incompatible', {
        source = playerSource,
        clientProtocol = payload.protocolVersion,
        serverProtocol = GCVersion.GetProtocolVersion()
    })
    TriggerClientEvent(GCEvents.Client.spawnRejected, playerSource, {
        errorCode = 'GC-PROTOCOL-MISMATCH-001',
        retryable = false
    })
    return false, errorCode or 'GC-PROTOCOL-MISMATCH-001'
end

--- RU: Завершает recovery по фактическому состоянию server-side ped.
--- RU: Обычный clientReady и совместимый resyncReady используют одну функцию.
--- EN: Completes recovery from the actual server-side ped state. Both normal
--- EN: clientReady and the compatible resyncReady use this function.
local function handleRecoveryHandshake(playerSource, session, payload)
    storeHandshakeMetadata(session, payload)

    if GCPlayers.HasAuthoritativeLivePed(playerSource) then
        local success, errorCode = GCStates.Set(playerSource, 'spawned', 'recovery_server_ped_alive')

        if not success then
            GCLogger.Warn('GC-RESYNC-002', '[GC][RECOVERY] Failed to restore spawned state', {
                source = playerSource,
                errorCode = errorCode
            })
            return false, errorCode
        end

        session.recoveryCompletedAt = GCUtils.NowSec()
        TriggerClientEvent(GCEvents.Client.spawnConfirmed, playerSource, {
            decisionId = nil,
            state = 'spawned'
        })
        return true
    end

    local pendingOk, pendingError = GCStates.Set(playerSource, 'spawn_pending', 'recovery_requires_respawn')

    if not pendingOk then
        GCLogger.Warn('GC-RESYNC-001', '[GC][RECOVERY] Failed to enter safe spawn flow', {
            source = playerSource,
            errorCode = pendingError
        })
        return false, pendingError
    end

    session.recoveryCompletedAt = GCUtils.NowSec()
    return GCConnection.RequestSpawnForPlayer(playerSource)
end

--- RU: Идемпотентный handshake. Сервер сам выбирает normal/recovery/duplicate flow.
--- EN: Idempotent handshake. The server selects normal/recovery/duplicate flow.
--- @param playerSource number FiveM server player source
--- @param payload table Client readiness payload
--- @return boolean accepted
--- @return string|nil errorCode
function GCConnection.HandleClientReady(playerSource, payload)
    local session = GCSessions.Get(playerSource)

    if not session then
        return false, 'GC-SESSION-001'
    end

    local protocolOk, protocolError = validateHandshakeProtocol(playerSource, payload)

    if not protocolOk then
        return false, protocolError
    end

    if GCStates.Is(playerSource, 'resyncing') and session.recovered then
        return handleRecoveryHandshake(playerSource, session, payload)
    end

    if GCStates.Is(playerSource, 'spawned') then
        storeHandshakeMetadata(session, payload)

        if not GCPlayers.HasAuthoritativeLivePed(playerSource) then
            GCLogger.Warn('GC-RECOVERY-ENTITY-MISSING', '[GC][RECOVERY] Duplicate hello has no authoritative live ped', {
                source = playerSource
            })
            return false, 'GC-RECOVERY-ENTITY-MISSING'
        end

        -- RU: Восстанавливаем локальное состояние перезапущенного клиента.
        -- EN: Restore the local state of a restarted client resource.
        TriggerClientEvent(GCEvents.Client.spawnConfirmed, playerSource, {
            decisionId = nil,
            state = 'spawned'
        })
        return true
    end

    if GCStates.Is(playerSource, 'client_ready') then
        -- RU: Повторяем потерянный ACK; клиентский handler сам идемпотентен.
        -- EN: Re-send a lost ACK; the client handler is itself idempotent.
        TriggerClientEvent(GCEvents.Client.connectionAccepted, playerSource, {
            apiVersion = GCVersion.GetApiVersion(),
            protocolVersion = GCVersion.GetProtocolVersion()
        })
        return true
    end

    if not GCStates.Is(playerSource, 'joining') then
        -- RU: Duplicate/stale hello не меняет state и не продлевает timeout.
        -- EN: Duplicate/stale hello changes no state and extends no timeout.
        return true
    end

    storeHandshakeMetadata(session, payload)
    local success, errorCode = GCStates.Set(playerSource, 'client_ready', 'client_reported_ready')

    if not success then
        return false, errorCode
    end

    TriggerClientEvent(GCEvents.Client.connectionAccepted, playerSource, {
        apiVersion = GCVersion.GetApiVersion(),
        protocolVersion = GCVersion.GetProtocolVersion()
    })
    return true
end

--- RU: Backward-compatible resyncReady alias того же state-aware handshake.
--- EN: Backward-compatible resyncReady alias for the same state-aware handshake.
function GCConnection.HandleResyncReady(playerSource, payload)
    local session = GCSessions.Get(playerSource)

    if not session then
        return false, 'GC-SESSION-001'
    end

    local protocolOk, protocolError = validateHandshakeProtocol(playerSource, payload)

    if not protocolOk then
        return false, protocolError
    end

    if GCStates.Is(playerSource, 'resyncing') and session.recovered then
        return handleRecoveryHandshake(playerSource, session, payload)
    end

    -- RU: Старый/повторный resyncReady безопасно обрабатывается как hello.
    -- EN: A stale/duplicate resyncReady is safely handled as a hello.
    return GCConnection.HandleClientReady(playerSource, payload)
end

--- RU:
--- Запрашивает спавн для игрока (вызывается после client_ready или resync).
--- Выделено отдельно, чтобы и обычный, и восстановленный поток использовали
--- единую точку создания spawn decision.
---
--- EN:
--- Requests a spawn for a player (called after client_ready or resync).
--- Extracted so both the normal and recovered flows use a single point for
--- creating a spawn decision.
---
--- @param playerSource number FiveM server player source
function GCConnection.RequestSpawnForPlayer(playerSource)
    -- RU: Запрашиваем спавн.
    -- EN: Request the spawn.
    local decision, spawnError = GCSpawn.Request(playerSource)

    if not decision then
        TriggerClientEvent(GCEvents.Client.spawnRejected, playerSource, {
            errorCode = spawnError,
            retryable = false
        })
        return false, spawnError
    end

    return true
end
