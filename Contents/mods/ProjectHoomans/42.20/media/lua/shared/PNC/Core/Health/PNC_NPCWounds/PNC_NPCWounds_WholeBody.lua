-- Persistent abstract ailments that affect an NPC as a whole.

PNC = PNC or {}
PNC.NPCWounds = PNC.NPCWounds or {}
PNC.NPCWounds.WholeBody = PNC.NPCWounds.WholeBody or {}

local Wounds = PNC.NPCWounds
local WholeBody = Wounds.WholeBody
local Core = PNC.Core

function WholeBody.Ensure(record)
    local body = Wounds.Ensure(record)
    body.wholeBodyAilments = type(body.wholeBodyAilments) == "table"
        and body.wholeBodyAilments or {}
    return body.wholeBodyAilments
end

function WholeBody.Get(record, ailmentID)
    return WholeBody.Ensure(record)[tostring(ailmentID or "")]
end

function WholeBody.GetSeverity(record, ailmentID)
    local value = WholeBody.Get(record, ailmentID)
    if type(value) == "table" then
        return Core.Clamp(tonumber(value.severity) or 0, 0, 1)
    end
    return Core.Clamp(tonumber(value) or 0, 0, 1)
end

function WholeBody.SetSeverity(record, ailmentID, severity)
    local ailments = WholeBody.Ensure(record)
    local id = tostring(ailmentID or "")
    local value = Core.Clamp(tonumber(severity) or 0, 0, 1)
    local previous = ailments[id]
    local previousValue = type(previous) == "table"
        and tonumber(previous.severity) or tonumber(previous) or 0
    if value <= 0 then
        ailments[id] = nil
    else
        ailments[id] = { severity = value }
    end
    return value, math.abs(previousValue - value) > 0.000001
end

function WholeBody.SetFlag(record, ailmentID, active)
    local ailments = WholeBody.Ensure(record)
    local id = tostring(ailmentID or "")
    local previous = ailments[id]
    local wasActive = type(previous) == "table"
        and previous.active == true
    active = active == true
    if active then
        ailments[id] = { active = true, flavorOnly = true }
    elseif previous and previous.flavorOnly == true then
        ailments[id] = nil
    end
    return active, wasActive ~= active
end

function WholeBody.IsCurable(ailmentID)
    local definitions = PNC.NeedsDefinitions
    local definition = definitions and definitions.GetWholeBodyAilment
        and definitions.GetWholeBodyAilment(ailmentID)
    return not definition or definition.curable ~= false
end

return WholeBody
