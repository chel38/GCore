-- RU: Пример пользовательской локализации GreenCore.
-- EN: Example custom localization for GreenCore.

-- RU: Скопируйте этот файл и переименуйте его, например, в de.lua.
-- EN: Copy this file and rename it, for example, to de.lua.

-- RU: Затем укажите новый язык в config/general.lua (поле locale).
-- EN: Then set the new language in config/general.lua (the locale field).

-- RU: Корневая таблица локализации.
-- EN: Root localization table.
GCLocales = GCLocales or {}

-- RU: Пример немецкой локализации. Замените 'de' на нужный код языка.
-- EN: Example German localization. Replace 'de' with the desired language code.
GCLocales.de = {
    -- RU: Сообщения подключения.
    -- EN: Connection messages.
    ['connection.checking'] = 'Verbindung wird geprüft...',
    ['connection.accepted'] = 'Verbindung akzeptiert.',
    ['connection.rejected'] = 'Verbindung abgelehnt.',
    ['connection.duplicate'] = 'Diese Verbindung ist bereits auf dem Server aktiv.',
    ['connection.license_missing'] = 'FiveM-Lizenz konnte nicht verifiziert werden.',
    ['connection.timeout'] = 'Verbindungszeit abgelaufen.',
    ['connection.server_stopping'] = 'Server wird gestoppt. Verbindung abgelehnt.',

    -- RU: Сообщения спавна.
    -- EN: Spawn messages.
    ['spawn.preparing'] = 'Spawn wird vorbereitet...',
    ['spawn.success'] = 'Spieler erfolgreich gespawnt.',
    ['spawn.failed'] = 'Spieler konnte nicht gespawnt werden.',
    ['spawn.rejected'] = 'Spawn-Anfrage abgelehnt.',
    ['spawn.expired'] = 'Spawn-Zeit abgelaufen.',

    -- RU: Сообщения состояний.
    -- EN: State messages.
    ['state.connecting'] = 'Spieler verbindet sich',
    ['state.validated'] = 'Validierung abgeschlossen',
    ['state.joining'] = 'Spieler tritt bei',
    ['state.client_ready'] = 'Client bereit',
    ['state.spawn_pending'] = 'Spawn wird vorbereitet',
    ['state.spawning'] = 'Spawn läuft',
    ['state.spawned'] = 'Spieler gespawnt',
    ['state.disconnecting'] = 'Spieler trennt sich',
    ['state.disconnected'] = 'Spieler getrennt',
    ['state.rejected'] = 'Verbindung abgelehnt',
    ['state.error'] = 'Ein Fehler ist aufgetreten',

    -- RU: Сообщения ошибок.
    -- EN: Error messages.
    ['error.internal'] = 'Ein interner GreenCore-Fehler ist aufgetreten.',
    ['error.license_missing'] = 'FiveM-Lizenz konnte nicht verifiziert werden.',
    ['error.invalid_payload'] = 'Ungültige Daten empfangen.',
    ['error.rate_limited'] = 'Zu viele Anfragen. Bitte warten.',
    ['error.session_not_found'] = 'Spielersitzung nicht gefunden.',
    ['error.spawn_denied'] = 'Spieler-Spawn verweigert.',
    ['error.not_ready'] = 'Spieler ist noch nicht bereit.',

    -- RU: Сообщения игрока.
    -- EN: Player messages.
    ['player.connected'] = 'Spieler {playerName} verbunden.',
    ['player.disconnected'] = 'Spieler {playerName} getrennt.'
}