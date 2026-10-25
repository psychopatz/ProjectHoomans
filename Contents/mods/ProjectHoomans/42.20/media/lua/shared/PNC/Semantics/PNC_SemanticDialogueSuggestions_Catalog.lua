-- Static and projected definition lookup for semantic suggestions.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Suggestions = PNC.Semantics.DialogueSuggestions
local Internal = Suggestions.Internal

local StaticProvider = Internal.StaticProvider
local CapabilityProvider = Internal.CapabilityProvider
local normalized = Internal.normalized
local copyValue = Internal.copyValue

local function definitionFor(id)
    return StaticProvider.Find(id)
end

local function capabilityDefinitionFor(id)
    local action
    for action, definition in pairs(CapabilityProvider.Definitions) do
        if definition.id == id then return action, definition end
    end
    return nil, nil
end

local function projectedCapabilityFor(id, view)
    local projection = view and view.semanticSuggestions or nil
    if type(projection) ~= "table" then return nil, nil end
    local function inspect(rows)
        for _, row in ipairs(rows or {}) do
            if type(row) == "table"
                and tostring(row.id or "") == tostring(id or "")
            then
                local frame = row.frame or row.semanticFrame
                local action = row.action
                    or row.capability and row.capability.action
                    or frame and frame.action
                if type(frame) == "table" and action ~= nil then
                    return normalized(action), {
                        id = id,
                        topic = frame.topic,
                        utteranceKey = frame.textKey,
                        utteranceFallback = frame.textFallback
                            or row.text,
                        target = copyValue(frame.target),
                        destination = copyValue(frame.destination),
                        slots = copyValue(frame.slots) or {},
                    }
                end
            end
        end
        return nil, nil
    end
    local action, definition = inspect(projection.permittedCapabilities)
    if action then return action, definition end
    for _, group in ipairs(projection.groups or {}) do
        action, definition = inspect(group.capabilities)
        if action then return action, definition end
    end
    return nil, nil
end

local function definitionForSubject(subject, followUp)
    subject = normalized(subject)
    if followUp == true and subject == "WELLBEING" then
        return definitionFor("question.wellbeing_detail")
    end
    if subject == "WELLBEING" then return definitionFor("question.wellbeing") end
    if subject == "NEEDS" then return definitionFor("question.needs") end
    if subject == "IDENTITY" then return definitionFor("question.identity") end
    if subject == "NPC_HEALTH_STATE" then return definitionFor("question.health") end
    if subject == "TIME" then return definitionFor("question.time") end
    if subject == "DATE" then return definitionFor("question.date") end
    if subject == "WEATHER" then return definitionFor("question.weather") end
    return nil
end

Internal.definitionFor = definitionFor
Internal.capabilityDefinitionFor = capabilityDefinitionFor
Internal.projectedCapabilityFor = projectedCapabilityFor
Internal.definitionForSubject = definitionForSubject

return Suggestions

