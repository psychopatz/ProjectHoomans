PNC = PNC or {}

local Protocol = PNC.ColonyJournalProtocol or {}
PNC.ColonyJournalProtocol = Protocol

local EventTypes = require "PNC/Core/Events/PNC_EventDefinitions"

Protocol.VERSION = 1
Protocol.MAX_BATCH = 32
Protocol.MAX_SERVER_ENTRIES = 512
Protocol.SOURCE_NPC = 1
Protocol.SOURCE_STORAGE = 2

-- Event names stay in the shared schema once. Wire rows carry the compact
-- numeric code instead of repeating a long event string for every entry.
Protocol.EVENT_CODES = Protocol.EVENT_CODES or {
    [EventTypes.STORAGE_ITEM_DEPOSITED] = 1,
    [EventTypes.STORAGE_ITEM_WITHDRAWN] = 2,
    [EventTypes.NPC_FOOD_CONSUMED] = 3,
    [EventTypes.NPC_DRINK_CONSUMED] = 4,
    [EventTypes.NPC_NEED_SEVERITY_CHANGED] = 5,
    [EventTypes.NPC_NEED_CRITICAL_DAMAGE] = 6,
    [EventTypes.NPC_WEIGHT_CATEGORY_CHANGED] = 7,
    [EventTypes.NPC_SKILL_LEVEL_UP] = 8,
    [EventTypes.NPC_WOUNDED] = 9,
}

Protocol.EVENT_TYPES = Protocol.EVENT_TYPES or {}
for eventType, code in pairs(Protocol.EVENT_CODES) do
    Protocol.EVENT_TYPES[code] = eventType
end

function Protocol.EventCode(eventType)
    return tonumber(Protocol.EVENT_CODES[tostring(eventType or "")]) or 0
end

function Protocol.EventType(code)
    return Protocol.EVENT_TYPES[tonumber(code) or 0]
end

local function primitive(value, maxLength)
    local valueType = type(value)
    if value == nil then return "" end
    if valueType == "string" then
        return string.sub(value, 1, maxLength or 96)
    end
    if valueType == "number" then return tonumber(value) or 0 end
    if valueType == "boolean" then return value end
    return ""
end

-- Fixed row layout:
-- [1] sequence, [2] world minute, [3] source, [4] event code,
-- [5] subject id, [6] display label, [7..10] event arguments,
-- [11] unknown event name (only used for forward-compatible events).
function Protocol.ToWire(entry)
    local args = entry and entry.args or {}
    local row = {
        math.floor(tonumber(entry and entry.sequence) or 0),
        math.floor(tonumber(entry and entry.at) or 0),
        math.floor(tonumber(entry and entry.source) or 0),
        math.floor(tonumber(entry and entry.eventCode) or 0),
        primitive(entry and entry.subjectID, 96),
        primitive(entry and entry.label, 64),
        primitive(args[1]), primitive(args[2]),
        primitive(args[3]), primitive(args[4]),
    }
    if row[4] == 0 then
        row[11] = primitive(entry and entry.eventType, 96)
    end
    return row
end

return Protocol
