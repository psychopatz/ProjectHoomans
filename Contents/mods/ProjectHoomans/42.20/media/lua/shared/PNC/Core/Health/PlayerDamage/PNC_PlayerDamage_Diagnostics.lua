-- Optional per-record trace for the bounded player-hit request lifecycle.

PNC = PNC or {}
PNC.PlayerDamage = PNC.PlayerDamage or {}
PNC.PlayerDamage.Internal = PNC.PlayerDamage.Internal or {}

local Internal = PNC.PlayerDamage.Internal
local Core = PNC.Core
local MAX_FIELD_LENGTH = 64

local function safeField(value)
    local valueType = type(value)
    local text
    if value == nil then
        return "-"
    end
    if valueType ~= "string" and valueType ~= "number"
        and valueType ~= "boolean"
    then
        return "unsupported"
    end
    text = tostring(value):gsub("[%c]", " ")
    return text:sub(1, MAX_FIELD_LENGTH)
end

function Internal.Audit(record, eventName, status, reason,
    playerID, weaponFullType, damage)
    if not record or not Core
        or type(Core.IsRecordDebugEnabled) ~= "function"
        or type(Core.LogRecordDebug) ~= "function"
        or not Core.IsRecordDebugEnabled(record)
    then
        return false
    end
    Core.LogRecordDebug(record,
        "health.player_hit event=" .. safeField(eventName)
            .. " npc=" .. safeField(record.id)
            .. " player=" .. safeField(playerID)
            .. " status=" .. safeField(status)
            .. " reason=" .. safeField(reason)
            .. " weapon=" .. safeField(weaponFullType)
            .. " damage=" .. safeField(damage))
    return true
end
