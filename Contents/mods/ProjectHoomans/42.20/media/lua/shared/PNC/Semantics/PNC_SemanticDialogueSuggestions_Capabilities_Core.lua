PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Suggestions = PNC.Semantics.DialogueSuggestions
local Internal = Suggestions.Internal

local copyValue = Internal.copyValue

local function isActiveHubDefinition(definition, activeHubID)
    if type(definition) ~= "table" or activeHubID == nil then return false end
    local extensions = type(definition.extensions) == "table"
        and definition.extensions or {}
    return extensions.route == "semantic_hub"
        and tostring(extensions.hubID or "") == activeHubID
end

local function isActiveHubCandidate(candidate, activeHubID)
    if type(candidate) ~= "table" or activeHubID == nil then return false end
    local frame = type(candidate.frame) == "table" and candidate.frame or {}
    local extensions = type(frame.extensions) == "table"
        and frame.extensions or {}
    return extensions.route == "semantic_hub"
        and tostring(extensions.hubID or "") == activeHubID
end

local function sourceRecord(kind, revision, reason)
    return {
        kind = kind,
        revision = revision,
        reason = reason,
    }
end

local function capabilityFrame(action, definition, revision)
    return {
        schemaVersion = Suggestions.VERSION,
        kind = "semantic_click_frame",
        candidateID = definition.id,
        topic = definition.topic,
        intent = "REQUEST",
        speechAct = "REQUEST",
        action = action,
        groupID = definition.groupID,
        textKey = definition.utteranceKey,
        textFallback = definition.utteranceFallback,
        labelKey = definition.labelKey,
        target = copyValue(definition.target)
            or { kind = "conversation_actor", ref = "npc" },
        destination = copyValue(definition.destination),
        slots = {
            npcID = { kind = "conversation_actor", ref = "npc" },
        },
        requestRevision = revision,
    }
end


Internal.isActiveHubDefinition = isActiveHubDefinition
Internal.isActiveHubCandidate = isActiveHubCandidate
Internal.sourceRecord = sourceRecord
Internal.capabilityFrame = capabilityFrame

return Suggestions
