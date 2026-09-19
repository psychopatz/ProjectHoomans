PNC = PNC or {}
local Internal = PNC.NPCWounds.Internal
local Core = PNC.Core
local MAX_FIELD_LENGTH = 64

local function safeField(value)
    local valueType = type(value)
    if value == nil then return "-" end
    if valueType ~= "string" and valueType ~= "number"
        and valueType ~= "boolean"
    then
        return "unsupported"
    end
    return tostring(value):gsub("[%c]", " ")
        :sub(1, MAX_FIELD_LENGTH)
end

local function logRecord(record, message)
    if not record or not Core
        or type(Core.IsRecordDebugEnabled) ~= "function"
        or type(Core.LogRecordDebug) ~= "function"
        or not Core.IsRecordDebugEnabled(record)
    then
        return false
    end
    Core.LogRecordDebug(record, message)
    return true
end

function Internal.LogInfectionDebug(
    record,
    eventName,
    status,
    reason,
    stage,
    progress,
    fever
)
    return logRecord(record,
        "health.infection event=" .. safeField(eventName)
            .. " npc=" .. safeField(record and record.id)
            .. " status=" .. safeField(status)
            .. " reason=" .. safeField(reason)
            .. " stage=" .. safeField(stage)
            .. " progress=" .. safeField(progress)
            .. " fever=" .. safeField(fever))
end

function Internal.LogZombieAttackDebug(
    record,
    route,
    status,
    reason,
    attackerZombieId,
    partId,
    woundType,
    damage
)
    return logRecord(record,
        "health.zombie_attack route=" .. safeField(route)
            .. " npc=" .. safeField(record and record.id)
            .. " attacker=" .. safeField(attackerZombieId)
            .. " status=" .. safeField(status)
            .. " reason=" .. safeField(reason)
            .. " part=" .. safeField(partId)
            .. " wound=" .. safeField(woundType)
            .. " damage=" .. safeField(damage))
end

return Internal
