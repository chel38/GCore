-- RU: Версия GreenCore.
-- EN: GreenCore version.

-- RU: Таблица версии ядра.
-- EN: Core version table.
GCVersion = {
    -- RU: Мажорная версия.
    -- EN: Major version.
    major = 0,

    -- RU: Минорная версия.
    -- EN: Minor version.
    minor = 1,

    -- RU: Патч-версия.
    -- EN: Patch version.
    patch = 0,

    -- RU: Метка стадии разработки.
    -- EN: Development stage label.
    label = 'development',

    -- RU: Версия публичного API.
    -- EN: Public API version.
    api = 1,

    -- RU: Версия сетевого протокола.
    -- EN: Network protocol version.
    protocol = 1
}

--- RU:
--- Возвращает строковое представление версии ядра.
---
--- EN:
--- Returns the string representation of the core version.
---
--- @return string version Version string like "0.1.0"
function GCVersion.GetString()
    return ('%d.%d.%d'):format(
        GCVersion.major,
        GCVersion.minor,
        GCVersion.patch
    )
end

--- RU:
--- Возвращает полную строку версии с меткой стадии.
---
--- EN:
--- Returns the full version string with the stage label.
---
--- @return string fullVersion Full version string
function GCVersion.GetFullString()
    return ('%s-%s'):format(GCVersion.GetString(), GCVersion.label)
end