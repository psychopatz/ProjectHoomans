local Presentation = {}
local EventTypes = require "PNC/Core/Events/PNC_EventDefinitions"

local function text(key, fallback, ...)
    local translated = getText and getText(key, ...) or nil
    if translated and translated ~= "" and translated ~= key then
        return translated
    end
    return string.format(fallback, ...)
end

local function humanize(value)
    value = tostring(value or "")
    local base, side = string.match(value, "^(.-)_([LR])$")
    if base and side then
        value = (side == "L" and "Left " or "Right ") .. base
    end
    value = string.gsub(value, "_", " ")
    value = string.gsub(value, "(%l)(%u)", "%1 %2")
    value = string.gsub(value, "^%l", string.upper)
    return value ~= "" and value or "Unknown"
end

local function itemName(fullType)
    fullType = tostring(fullType or "")
    if getItemNameFromFullType then
        local translated = getItemNameFromFullType(fullType)
        if translated and translated ~= "" then return translated end
    end
    return string.match(fullType, "%.(.+)$") or humanize(fullType)
end

local function percent(value)
    return tostring(math.max(0, math.floor((tonumber(value) or 0) * 100 + 0.5)))
end

local function timeLabel(worldMinute)
    worldMinute = math.max(0, math.floor(tonumber(worldMinute) or 0))
    local day = math.floor(worldMinute / 1440) + 1
    local minuteOfDay = worldMinute % 1440
    local hour = math.floor(minuteOfDay / 60)
    local minute = minuteOfDay % 60
    return text("UI_PNC_Journal_Time", "Day %s %s:%s", tostring(day),
        string.format("%02d", hour), string.format("%02d", minute))
end

function Presentation.Row(entry)
    if type(entry) ~= "table" then return nil end
    local eventType = tostring(entry[1] or "")
    local message
    if eventType == EventTypes.NPC_FOOD_CONSUMED then
        message = text("UI_PNC_Journal_FoodConsumed", "Ate %s (+%s%% hunger)",
            itemName(entry[3]), percent(entry[4]))
    elseif eventType == EventTypes.NPC_DRINK_CONSUMED then
        message = text("UI_PNC_Journal_DrinkConsumed",
            "Drank %s (+%s%% hydration)", itemName(entry[3]),
            percent(entry[4]))
    elseif eventType == EventTypes.NPC_SKILL_LEVEL_UP then
        message = text("UI_PNC_Journal_SkillLevelUp", "Reached %s level %s",
            humanize(entry[3]), tostring(math.floor(tonumber(entry[4]) or 0)))
    elseif eventType == EventTypes.NPC_WOUNDED then
        message = text("UI_PNC_Journal_Wounded",
            "Received %s to %s (%s damage)", humanize(entry[4]),
            humanize(entry[3]), tostring(math.max(0,
                math.floor(tonumber(entry[5]) or 0))))
    else
        local shortType = string.match(eventType, "([^.]+)$") or eventType
        message = text("UI_PNC_Journal_Unknown", "Recorded event: %s",
            humanize(shortType))
    end
    return { message = message, time = timeLabel(entry[2]) }
end

function Presentation.Rows(entries)
    local output = {}
    for _, entry in ipairs(entries or {}) do
        local row = Presentation.Row(entry)
        if row then output[#output + 1] = row end
    end
    return output
end

return Presentation
