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

    -- RU: Добавляем тайм-аут для deferrals, чтобы не зависнуть навсегда.
    -- EN: Add a timeout for deferrals to avoid hanging forever.
    SetTimeout(GCConfig.Connection.deferralTimeoutMs, function()
        -- RU: Если подключение уже обработано, ничего не делаем.
        -- EN: If the connection was already handled, do nothing.
        if deferralHandled then
            return
        end

        -- RU: Удаляем pending connection, если она была создана.
        -- EN: Remove the pending connection if it was created.
        GCSessions.RemovePendingConnection(temporarySource)

        -- RU: Завершаем ожидание с сообщением об истечении времени.
        -- EN: End the wait with a timeout message.
        setKickReason(GC_T(locale, 'connection.timeout'))
        done(GC_T(locale, 'connection.timeout'))
    end)

    -- RU: Проверяем имя игрока.
    -- EN: Validate the player name.
    local nameValid = validatePlayerName(playerName)

    if not nameValid then
        setKickReason(GC_T(locale, 'connection.rejected'))
        done(GC_T(locale, 'connection.rejected'))
        return
    end

    -- RU: Собираем идентификаторы игрока.
    -- EN: Collect the player identifiers.
    local identifiers = GCIdentifiers.GetAll(temporarySource)

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

--- RU:
--- Обрабатывает готовность клиента (clientReady).
--- Проверяет строгое совпадение версии протокола перед продолжением lifecycle.
---
--- EN:
--- Handles client readiness (clientReady).
--- Verifies strict protocol version match before continuing the lifecycle.
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

    -- RU: Строгая проверка версии протокола.
    -- RU: Недостаточно проверить тип — версия должна точно совпадать.
    -- EN: Strict protocol version check.
    -- EN: Checking the type is not enough — the version must match exactly.
    local protocolMatches, protocolError = GCValidation.ProtocolMatches(payload.protocolVersion)

    if not protocolMatches then
        GCLogger.Warn('GC-PROTOCOL-MISMATCH-001', 'Client protocol version is incompatible', {
            source = playerSource,
            clientProtocol = payload.protocolVersion,
            serverProtocol = GCVersion.GetProtocolVersion()
        })

        -- RU: Не продолжаем spawn при несовместимом протоколе.
        -- EN: Do not continue the spawn with an incompatible protocol.
        TriggerClientEvent(GCEvents.Client.spawnRejected, playerSource, {
            errorCode = 'GC-PROTOCOL-MISMATCH-001',
            retryable = false
        })
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
    TriggerClientEvent(GCEvents.Client.connectionAccepted, playerSource, {
        apiVersion = GCVersion.GetApiVersion(),
        protocolVersion = GCVersion.GetProtocolVersion()
    })
end

--- RU:
--- Обрабатывает ответ о готовности к resync после рестарта (resyncReady).
--- Payload не доверяется полностью — используется только как информация.
--- Если игрок уже существует в мире (isPedAlive=true), сессия переходит
--- resyncing -> spawned без повторной телепортации. В противном случае
--- запускается нормальный spawn flow (resyncing -> spawn_pending).
---
--- EN:
--- Handles the resync-ready response after a restart (resyncReady).
--- The payload is not fully trusted — it is used only as information.
--- If the player already exists in the world (isPedAlive=true), the session moves
--- resyncing -> spawned without re-teleporting. Otherwise the normal spawn flow
--- is started (resyncing -> spawn_pending).
---
--- @param playerSource number FiveM server player source
--- @param payload table Resync-ready payload
function GCConnection.HandleResyncReady(playerSource, payload)
    -- RU: Проверяем, что сессия существует.
    -- EN: Verify that the session exists.
    local session = GCSessions.Get(playerSource)

    if not session then
        return
    end

    -- RU: Проверяем, что сессия восстановлена после рестарта и в resyncing.
    -- EN: Verify that the session was recovered and is in resyncing.
    if not session.recovered or not GCStates.Is(playerSource, 'resyncing') then
        return
    end

    -- RU: Сохраняем метаданные клиента.
    -- EN: Save the client metadata.
    session.metadata.clientVersion = payload.clientVersion
    session.metadata.protocolVersion = payload.protocolVersion

    -- Client isPedAlive is retained as diagnostic metadata only. OneSync state is authoritative.
    session.metadata.clientPedAliveHint = payload.isPedAlive == true
    local authoritativePedAlive = GCPlayers.HasAuthoritativeLivePed(playerSource)

    if authoritativePedAlive then
        local success, errorCode = GCStates.Set(playerSource, 'spawned', 'resync_server_ped_alive')

        if not success then
            GCLogger.Warn('GC-RESYNC-002', 'Failed to transition recovered session to spawned', {
                source = playerSource,
                errorCode = errorCode
            })
            return
        end

        -- RU: Сообщаем клиенту, что он уже заспавнен, без повторной телепортации.
        -- EN: Notify the client that it is already spawned, without re-teleporting.
        TriggerClientEvent(GCEvents.Client.spawnConfirmed, playerSource, {
            decisionId = nil,
            state = 'spawned'
        })
        return
    end

    -- RU: Ped отсутствует — запускаем нормальный spawn flow.
    -- EN: The ped is missing — start the normal spawn flow.
    local success, errorCode = GCStates.Set(playerSource, 'spawn_pending', 'resync_requires_respawn')

    if not success then
        GCLogger.Warn('GC-RESYNC-001', 'Failed to transition recovered session to spawn_pending', {
            source = playerSource,
            errorCode = errorCode
        })
        return
    end

    -- RU: Создаём и отправляем новое решение о спавне.
    -- EN: Create and send a new spawn decision.
    GCConnection.RequestSpawnForPlayer(playerSource)
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
    end
end
