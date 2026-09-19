PNC = PNC or {}
PNC.Treatment = PNC.Treatment or {}
PNC.Treatment.Internal = PNC.Treatment.Internal or {}

local Internal = PNC.Treatment.Internal
local Core = PNC.Core
local MAX_FIELD_LENGTH = 64

function Internal.IsAuthority()
    return Core and type(Core.IsAuthority) == "function"
        and Core.IsAuthority() == true
end

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

function Internal.LogDebug(
    record,
    eventName,
    route,
    status,
    reason,
    actorId,
    targetId,
    partId,
    itemType,
    mode,
    firstAidLevel
)
    if not record or not Core
        or type(Core.IsRecordDebugEnabled) ~= "function"
        or type(Core.LogRecordDebug) ~= "function"
        or not Core.IsRecordDebugEnabled(record)
    then
        return false
    end
    Core.LogRecordDebug(record,
        "health.treatment event=" .. safeField(eventName)
            .. " route=" .. safeField(route)
            .. " npc=" .. safeField(record.id)
            .. " actor=" .. safeField(actorId)
            .. " target=" .. safeField(targetId)
            .. " status=" .. safeField(status)
            .. " reason=" .. safeField(reason)
            .. " part=" .. safeField(partId)
            .. " item=" .. safeField(itemType)
            .. " mode=" .. safeField(mode)
            .. " firstAid=" .. safeField(firstAidLevel))
    return true
end

return Internal
