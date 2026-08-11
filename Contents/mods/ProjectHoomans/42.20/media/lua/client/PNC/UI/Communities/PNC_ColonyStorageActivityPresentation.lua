local Presentation = {}
local Journal = require "PNC/Core/Colony/Storage/PNC_ColonyStorageJournal"
local Inventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local F = Journal.FIELD

local function text(key, fallback, ...)
    local translated = getText and getText(key, ...) or nil
    if translated and translated ~= key then return translated end
    return string.format(fallback, ...)
end

local function itemName(typeID)
    local fullType = Inventory.getItemFullType(typeID)
        or ("type:" .. tostring(typeID))
    if getItemNameFromFullType then
        local translated = getItemNameFromFullType(fullType)
        if translated and translated ~= "" then return translated end
    end
    return string.match(fullType, "%.(.+)$") or fullType
end

local function reasonName(reason)
    reason = tostring(reason or "")
    if reason == "" then return nil end
    local key = "UI_PNC_Storage_Reason_" .. reason
    local translated = getText and getText(key) or nil
    if translated and translated ~= key then return translated end
    return reason
end

local function timeLabel(worldMinute)
    worldMinute = math.max(0, math.floor(tonumber(worldMinute) or 0))
    local day = math.floor(worldMinute / 1440) + 1
    local minuteOfDay = worldMinute % 1440
    local hour = math.floor(minuteOfDay / 60)
    local minute = minuteOfDay % 60
    return text("UI_PNC_Storage_ActivityTime", "Day %s %s:%s",
        tostring(day), string.format("%02d", hour),
        string.format("%02d", minute))
end

function Presentation.Row(entry)
    if type(entry) ~= "table" then return nil end
    local actor = tostring(entry[F.ACTOR] or "")
    if actor == "" then
        actor = text("UI_PNC_Storage_ActorUnknown", "Someone")
    end
    local quantity = math.max(1, math.floor(tonumber(entry[F.QUANTITY]) or 1))
    local item = itemName(entry[F.TYPE_ID])
    local message
    if entry[F.OPERATION] == Journal.OPERATION.TAKE then
        message = text("UI_PNC_Storage_ActivityTake", "%s grabbed %s x %s",
            actor, tostring(quantity), item)
    elseif entry[F.OPERATION] == Journal.OPERATION.STORE then
        message = text("UI_PNC_Storage_ActivityStore", "%s stored %s x %s",
            actor, tostring(quantity), item)
    else
        return nil
    end
    local reason = reasonName(entry[F.REASON])
    if reason then
        message = text("UI_PNC_Storage_ActivityReason", "%s (%s)",
            message, reason)
    end
    return {
        message = message,
        time = timeLabel(entry[F.WORLD_MINUTE]),
        operation = entry[F.OPERATION],
    }
end

function Presentation.Rows(entries)
    local output = {}
    for index = #(entries or {}), 1, -1 do
        local row = Presentation.Row(entries[index])
        if row then output[#output + 1] = row end
    end
    return output
end

return Presentation
