-- RU: Английская локализация GreenCore.
-- EN: English localization for GreenCore.

-- RU: Корневая таблица локализации.
-- EN: Root localization table.
GCLocales = GCLocales or {}

-- RU: Английские переводы.
-- EN: English translations.
GCLocales.en = {
    -- RU: Сообщения подключения.
    -- EN: Connection messages.
    ['connection.checking'] = 'Checking connection...',
    ['connection.accepted'] = 'Connection accepted.',
    ['connection.rejected'] = 'Connection rejected.',
    ['connection.duplicate'] = 'This connection is already active on the server.',
    ['connection.license_missing'] = 'Failed to verify the FiveM license.',
    ['connection.timeout'] = 'Connection wait time expired.',
    ['connection.server_stopping'] = 'Server is stopping. Connection rejected.',

    -- RU: Сообщения спавна.
    -- EN: Spawn messages.
    ['spawn.preparing'] = 'Preparing player spawn...',
    ['spawn.success'] = 'Player spawned successfully.',
    ['spawn.failed'] = 'Failed to spawn the player.',
    ['spawn.rejected'] = 'Spawn request rejected.',
    ['spawn.expired'] = 'Spawn wait time expired.',

    -- RU: Сообщения состояний.
    -- EN: State messages.
    ['state.connecting'] = 'Player is connecting',
    ['state.validated'] = 'Validation completed',
    ['state.joining'] = 'Player is joining',
    ['state.client_ready'] = 'Client is ready',
    ['state.spawn_pending'] = 'Spawn is being prepared',
    ['state.spawning'] = 'Spawn is in progress',
    ['state.spawned'] = 'Player has spawned',
    ['state.disconnecting'] = 'Player is disconnecting',
    ['state.disconnected'] = 'Player disconnected',
    ['state.rejected'] = 'Connection rejected',
    ['state.error'] = 'An error occurred',

    -- RU: Сообщения ошибок.
    -- EN: Error messages.
    ['error.internal'] = 'An internal GreenCore error occurred.',
    ['error.license_missing'] = 'Failed to verify the FiveM license.',
    ['error.invalid_payload'] = 'Received invalid data.',
    ['error.rate_limited'] = 'Too many requests. Please wait.',
    ['error.session_not_found'] = 'Player session was not found.',
    ['error.spawn_denied'] = 'Player spawn is denied.',
    ['error.not_ready'] = 'Player is not ready yet.',

    -- RU: Сообщения игрока.
    -- EN: Player messages.
    ['player.connected'] = 'Player {playerName} connected.',
    ['player.disconnected'] = 'Player {playerName} disconnected.',

    -- RU: Типы уведомлений.
    -- EN: Notification types.
    ['notification.info'] = 'Info',
    ['notification.success'] = 'Success',
    ['notification.warning'] = 'Warning',
    ['notification.error'] = 'Error'
}