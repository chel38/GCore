-- RU: Тесты уведомлений GreenCore.
-- EN: GreenCore notification tests.

-- RU: Тест отправки уведомления невалидному source.
-- EN: Test of sending a notification to an invalid source.
GCTest.Register('notifications.invalid_source', function()
    local success, errorCode = GCNotifications.SendToPlayer('not-a-number', 'Hello')

    GCTest.ExpectFalse(success, 'notification fails for invalid source')
    GCTest.ExpectEqual(errorCode, 'GC-NOTIFY-001', 'invalid source returns GC-NOTIFY-001')
end)

-- RU: Тест отправки уведомления с невалидным сообщением.
-- EN: Test of sending a notification with an invalid message.
GCTest.Register('notifications.invalid_message', function()
    local success, errorCode = GCNotifications.SendToPlayer(30, 123)

    GCTest.ExpectFalse(success, 'notification fails for non-string message')
    GCTest.ExpectEqual(errorCode, 'GC-NOTIFY-002', 'invalid message returns GC-NOTIFY-002')
end)

-- RU: Тест отправки уведомления с пустым сообщением.
-- EN: Test of sending a notification with an empty message.
GCTest.Register('notifications.empty_message', function()
    local success, errorCode = GCNotifications.SendToPlayer(30, '')

    GCTest.ExpectFalse(success, 'notification fails for empty message')
    GCTest.ExpectEqual(errorCode, 'GC-NOTIFY-002', 'empty message returns GC-NOTIFY-002')
end)

-- RU: Тест отправки уведомления с недопустимым типом.
-- EN: Test of sending a notification with an invalid type.
GCTest.Register('notifications.invalid_type', function()
    local success, errorCode = GCNotifications.SendToPlayer(30, 'Hello', 'bogus')

    GCTest.ExpectFalse(success, 'notification fails for invalid type')
    GCTest.ExpectEqual(errorCode, 'GC-NOTIFY-003', 'invalid type returns GC-NOTIFY-003')
end)

-- RU: Тест отправки уведомления игроку без сессии.
-- EN: Test of sending a notification to a player without a session.
GCTest.Register('notifications.no_session', function()
    local success, errorCode = GCNotifications.SendToPlayer(999, 'Hello')

    GCTest.ExpectFalse(success, 'notification fails for player without a session')
    GCTest.ExpectEqual(errorCode, 'GC-NOTIFY-004', 'missing session returns GC-NOTIFY-004')
end)

-- RU: Тест отправки уведомления всем с невалидным сообщением.
-- EN: Test of sending a notification to all with an invalid message.
GCTest.Register('notifications.send_to_all_invalid_message', function()
    local success, errorCode = GCNotifications.SendToAll(123)

    GCTest.ExpectFalse(success, 'send to all fails for non-string message')
    GCTest.ExpectEqual(errorCode, 'GC-NOTIFY-002', 'send to all invalid message returns GC-NOTIFY-002')
end)

-- RU: Тест отправки уведомления всем с недопустимым типом.
-- EN: Test of sending a notification to all with an invalid type.
GCTest.Register('notifications.send_to_all_invalid_type', function()
    local success, errorCode = GCNotifications.SendToAll('Hello', 'bogus')

    GCTest.ExpectFalse(success, 'send to all fails for invalid type')
    GCTest.ExpectEqual(errorCode, 'GC-NOTIFY-003', 'send to all invalid type returns GC-NOTIFY-003')
end)