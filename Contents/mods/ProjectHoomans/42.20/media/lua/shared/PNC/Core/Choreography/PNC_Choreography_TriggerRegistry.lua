-- Declarative gameplay trigger registry for Puppet Opera blueprints.
--
-- Blueprints can declare one or more `triggers` entries (e.g.
-- `teammate_incapacitated`, `social_kiss`, `camp_dance`, `escort_handhold`,
-- `conversation_beat`, `manual`). Gameplay systems query this registry by event
-- name in O(1) without hardcoding scene IDs.

PNC = PNC or {}
PNC.Choreography = PNC.Choreography or {}
PNC.Choreography.TriggerRegistry = PNC.Choreography.TriggerRegistry or {}

local TriggerRegistry = PNC.Choreography.TriggerRegistry

TriggerRegistry.ByEvent = TriggerRegistry.ByEvent or {}
TriggerRegistry.ByBlueprint = TriggerRegistry.ByBlueprint or {}

local VALID_EVENTS = {
    manual = true,
    teammate_incapacitated = true,
    social_kiss = true,
    social_hug = true,
    camp_dance = true,
    escort_handhold = true,
    conversation_beat = true,
    custom = true,
}

local function cleanText(value, maxLen)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    if string.find(value, "%c") then return "" end
    if maxLen then value = string.sub(value, 1, maxLen) end
    return value
end

local function copyFilters(raw)
    if type(raw) ~= "table" then return {} end
    local out = {}
    for k, v in pairs(raw) do
        local kt = type(k)
        local vt = type(v)
        if kt == "string" and (vt == "boolean" or vt == "number" or vt == "string") then
            out[k] = v
        end
    end
    return out
end

function TriggerRegistry.KnownEvents()
    local list = {}
    for name in pairs(VALID_EVENTS) do
        list[#list + 1] = name
    end
    table.sort(list)
    return list
end

function TriggerRegistry.NormalizeTriggers(rawTriggers)
    if type(rawTriggers) ~= "table" then return {} end
    local result = {}
    for index, raw in ipairs(rawTriggers) do
        if index > 16 then break end
        if type(raw) == "table" then
            local eventName = cleanText(raw.event, 64)
            if eventName ~= "" and string.match(eventName, "^[%w%._%-]+$") then
                local priority = tonumber(raw.priority) or 50
                if priority < 0 then priority = 0 end
                if priority > 1000 then priority = 1000 end
                local cooldownSec = tonumber(raw.cooldownSec) or 0
                if cooldownSec < 0 then cooldownSec = 0 end
                result[#result + 1] = {
                    event = eventName,
                    priority = math.floor(priority),
                    cooldownSec = cooldownSec,
                    filters = copyFilters(raw.filters),
                }
            end
        end
    end
    return result
end

function TriggerRegistry.Unregister(blueprintID)
    blueprintID = tostring(blueprintID or "")
    if blueprintID == "" then return end
    local prevEvents = TriggerRegistry.ByBlueprint[blueprintID]
    if type(prevEvents) == "table" then
        for _, eventName in ipairs(prevEvents) do
            local bucket = TriggerRegistry.ByEvent[eventName]
            if type(bucket) == "table" then
                for i = #bucket, 1, -1 do
                    if bucket[i].blueprintId == blueprintID then
                        table.remove(bucket, i)
                    end
                end
            end
        end
    end
    TriggerRegistry.ByBlueprint[blueprintID] = nil
end

function TriggerRegistry.IndexBlueprint(blueprint)
    if type(blueprint) ~= "table" or not blueprint.id then return end
    local id = tostring(blueprint.id)
    TriggerRegistry.Unregister(id)
    local triggers = blueprint.triggers
    if type(triggers) ~= "table" or #triggers == 0 then return end
    local indexedEvents = {}
    for _, trigger in ipairs(triggers) do
        local eventName = tostring(trigger.event or "")
        if eventName ~= "" then
            local bucket = TriggerRegistry.ByEvent[eventName]
            if not bucket then
                bucket = {}
                TriggerRegistry.ByEvent[eventName] = bucket
            end
            bucket[#bucket + 1] = {
                blueprintId = id,
                event = eventName,
                priority = tonumber(trigger.priority) or 50,
                cooldownSec = tonumber(trigger.cooldownSec) or 0,
                filters = copyFilters(trigger.filters),
            }
            table.sort(bucket, function(a, b)
                if a.priority ~= b.priority then
                    return a.priority > b.priority
                end
                return tostring(a.blueprintId) < tostring(b.blueprintId)
            end)
            indexedEvents[#indexedEvents + 1] = eventName
        end
    end
    TriggerRegistry.ByBlueprint[id] = indexedEvents
end

local function matchesFilters(filters, context)
    if type(filters) ~= "table" or type(context) ~= "table" then return true end
    if filters.sameFaction == true and context.sameFaction == false then
        return false
    end
    if filters.allowPlayer == false and context.hasPlayer == true then
        return false
    end
    if filters.requirePlayer == true and context.hasPlayer ~= true then
        return false
    end
    if filters.minAffinity ~= nil
        and tonumber(context.affinity) ~= nil
        and tonumber(context.affinity) < tonumber(filters.minAffinity)
    then
        return false
    end
    return true
end

function TriggerRegistry.FindForEvent(eventName, context)
    local bucket = TriggerRegistry.ByEvent[tostring(eventName or "")]
    if type(bucket) ~= "table" or #bucket == 0 then return {} end
    local matches = {}
    for _, entry in ipairs(bucket) do
        if matchesFilters(entry.filters, context) then
            matches[#matches + 1] = entry
        end
    end
    return matches
end

function TriggerRegistry.PickBest(eventName, context)
    local matches = TriggerRegistry.FindForEvent(eventName, context)
    return matches[1]
end

return TriggerRegistry
