require "PsychopatzCore/UI/PsychopatzNotificationWindow"

PNC = PNC or {}
PNC.ScavengeNotifications = PNC.ScavengeNotifications or {}

local Presentation = PNC.ScavengeNotifications
Presentation.Shown = Presentation.Shown or {}

local function tr(key, fallback, ...)
    local value = getText and getText(key, ...) or nil
    if value and value ~= "" and value ~= key then return value end
    if select("#", ...) > 0 then return string.format(fallback, ...) end
    return fallback
end

local function itemSummary(entries)
    local byType, order = {}, {}
    for _, entry in ipairs(entries or {}) do
        local key = tostring(entry.fullType or entry.displayName or "item")
        local bucket = byType[key]
        if not bucket then
            bucket = { name = tostring(entry.displayName or entry.fullType),
                quantity = 0 }
            byType[key] = bucket
            order[#order + 1] = bucket
        end
        bucket.quantity = bucket.quantity + (tonumber(entry.quantity) or 1)
    end
    table.sort(order, function(left, right)
        return string.lower(left.name) < string.lower(right.name)
    end)
    local output = {}
    for _, bucket in ipairs(order) do
        output[#output + 1] = bucket.name .. " x"
            .. tostring(bucket.quantity)
    end
    return table.concat(output, ", ")
end

local function findings(snapshot)
    local names, groups, order = {}, {}, {}
    for _, scavenger in ipairs(snapshot.scavengers or {}) do
        names[tostring(scavenger.npcId)] = tostring(
            scavenger.npcName or scavenger.npcId)
    end
    for _, entry in ipairs(snapshot.manifest or {}) do
        local npcId = tostring(entry.discoveredByNpcId or "team")
        local source = tostring(entry.sourceToken or "unknown")
        local key = npcId .. "\31" .. source
        local group = groups[key]
        if not group then
            group = { npcId = npcId,
                sourceLabel = tostring(entry.sourceLabel or entry.sourceType
                    or "Unknown source"), entries = {} }
            groups[key] = group
            order[#order + 1] = group
        end
        group.entries[#group.entries + 1] = entry
    end
    table.sort(order, function(left, right)
        local leftName = names[left.npcId] or left.npcId
        local rightName = names[right.npcId] or right.npcId
        if leftName ~= rightName then return leftName < rightName end
        return left.sourceLabel < right.sourceLabel
    end)
    local details = {}
    for _, group in ipairs(order) do
        details[#details + 1] = tostring(names[group.npcId]
            or tr("UI_PNC_Scavenge_Team", "Scavenging team"))
            .. " — " .. group.sourceLabel .. ": "
            .. itemSummary(group.entries)
    end
    if #details < 1 then
        details[1] = tr("UI_PNC_Scavenge_NothingFound",
            "No items were found.")
    end
    return details
end

function Presentation.Receive(previous, snapshot)
    if type(snapshot) ~= "table" or snapshot.requestFailed == true
        or snapshot.state ~= "WAITING_FOR_SELECTION"
        or not snapshot.sessionId
    then return false end
    local sessionId = tostring(snapshot.sessionId)
    if Presentation.Shown[sessionId] == true then return false end
    Presentation.Shown[sessionId] = true
    local quantity = 0
    for _, entry in ipairs(snapshot.manifest or {}) do
        quantity = quantity + (tonumber(entry.quantity) or 1)
    end
    return PsychopatzCore.Notifications.Show({
        id = "scavenge_complete:" .. sessionId,
        title = tr("UI_PNC_Scavenge_SearchComplete",
            "Scavenge Search Complete"),
        message = tr("UI_PNC_Scavenge_SearchCompleteSummary",
            "%s scavengers exhausted %s sources and found %s items.",
            #(snapshot.scavengers or {}),
            tonumber(snapshot.processedCount) or 0, quantity),
        details = findings(snapshot),
    })
end

function Presentation.Reset()
    Presentation.Shown = {}
end

return Presentation
