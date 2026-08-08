-- RU: Русская локализация GreenCore.
-- EN: Russian localization for GreenCore.

-- RU: Корневая таблица локализации.
-- EN: Root localization table.
GCLocales = GCLocales or {}

-- RU: Русские переводы.
-- EN: Russian translations.
GCLocales.ru = {
    -- RU: Сообщения подключения.
    -- EN: Connection messages.
    ['connection.checking'] = 'Проверяем подключение...',
    ['connection.accepted'] = 'Подключение подтверждено.',
    ['connection.rejected'] = 'Подключение отклонено.',
    ['connection.duplicate'] = 'Это подключение уже активно на сервере.',
    ['connection.license_missing'] = 'Не удалось подтвердить лицензию FiveM.',
    ['connection.timeout'] = 'Время ожидания подключения истекло.',
    ['connection.server_stopping'] = 'Сервер останавливается. Подключение отклонено.',

    -- RU: Сообщения спавна.
    -- EN: Spawn messages.
    ['spawn.preparing'] = 'Подготавливаем появление игрока...',
    ['spawn.success'] = 'Игрок успешно появился.',
    ['spawn.failed'] = 'Не удалось создать игрока.',
    ['spawn.rejected'] = 'Запрос на появление отклонён.',
    ['spawn.expired'] = 'Время ожидания появления истекло.',

    -- RU: Сообщения состояний.
    -- EN: State messages.
    ['state.connecting'] = 'Игрок подключается',
    ['state.validated'] = 'Проверка завершена',
    ['state.joining'] = 'Игрок входит',
    ['state.client_ready'] = 'Клиент готов',
    ['state.spawn_pending'] = 'Спавн подготавливается',
    ['state.spawning'] = 'Выполняется спавн',
    ['state.spawn_confirming'] = 'Спавн подтверждается',
    ['state.spawned'] = 'Игрок появился',
    ['state.resyncing'] = 'Игрок синхронизируется',
    ['state.disconnecting'] = 'Игрок отключается',
    ['state.disconnected'] = 'Игрок отключён',
    ['state.rejected'] = 'Подключение отклонено',
    ['state.error'] = 'Произошла ошибка',

    -- RU: Сообщения ошибок.
    -- EN: Error messages.
    ['error.internal'] = 'Произошла внутренняя ошибка GreenCore.',
    ['error.license_missing'] = 'Не удалось подтвердить лицензию FiveM.',
    ['error.invalid_payload'] = 'Получены некорректные данные.',
    ['error.rate_limited'] = 'Слишком много запросов. Подождите.',
    ['error.session_not_found'] = 'Сессия игрока не найдена.',
    ['error.spawn_denied'] = 'Появление игрока запрещено.',
    ['error.not_ready'] = 'Игрок ещё не готов.',

    -- RU: Сообщения протокола.
    -- EN: Protocol messages.
    ['protocol.mismatch'] = 'Версия протокола клиента несовместима с текущей версией сервера.',

    -- RU: Сообщения игрока.
    -- EN: Player messages.
    ['player.connected'] = 'Игрок {playerName} подключился.',
    ['player.disconnected'] = 'Игрок {playerName} отключился.',

    -- RU: Типы уведомлений.
    -- EN: Notification types.
    ['notification.info'] = 'Информация',
    ['notification.success'] = 'Успех',
    ['notification.warning'] = 'Предупреждение',
    ['notification.error'] = 'Ошибка'
}