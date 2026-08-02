-- Shared, player-safe relationship presentation data.  Both the conversation
-- overlay and developer inspector use this instead of maintaining parallel
-- attitude/score formatting rules.

PNC = PNC or {}
PNC.RelationshipPresentation = PNC.RelationshipPresentation or {}

local Presentation = PNC.RelationshipPresentation

Presentation.DebugStandingPresets = {
    admire = { label = "Admire", approval = 70, respect = 70 },
    pity = { label = "Pity", approval = 70, respect = -70 },
    fear = { label = "Fear", approval = -70, respect = 70 },
    despise = { label = "Despise", approval = -70, respect = -70 },
    indifferent = { label = "Indifferent", approval = 0, respect = 0 },
}

function Presentation.GetDebugStandingPreset(id)
    local preset = Presentation.DebugStandingPresets[tostring(id or "")]
    if not preset then return nil end
    return {
        id = tostring(id),
        label = preset.label,
        approval = preset.approval,
        respect = preset.respect,
    }
end

local function number(value)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return 0
    end
    return value
end

function Presentation.Summarize(relationship, exists)
    relationship = type(relationship) == "table" and relationship or {}
    return {
        exists = exists == true,
        approval = number(relationship.approval),
        respect = number(relationship.respect),
        familiarity = number(relationship.familiarity),
        state = tostring(relationship.state or "unknown"),
        previousState = tostring(relationship.previousState or "unknown"),
        revision = math.max(0, math.floor(number(relationship.revision))),
    }
end

function Presentation.BuildEvaluation(summary, requirement, context)
    local graph = PNC.RelationshipGraph
    if not graph or not graph.Evaluate then return nil end
    summary = Presentation.Summarize(
        summary,
        type(summary) == "table" and summary.exists == true
    )
    return graph.Evaluate(
        summary.approval,
        summary.respect,
        requirement or "inspect",
        context
    )
end

-- This only exposes the current player's directed relationship with the
-- requested NPC.  Detailed memories/personality remain debug-only.
function Presentation.BuildForConversation(player, npcID)
    local registry = PNC.Registry
    local playerCharacters = PNC.PlayerCharacters
    local relationships = PNC.Relationships
    local record = registry and registry.Get
        and registry.Get(tostring(npcID or "")) or nil
    if not record or record.alive == false then
        return nil, "npc_not_found"
    end
    if not playerCharacters or not playerCharacters.GetEntityKey then
        return nil, "player_identity_unavailable"
    end
    local targetKey, reason = playerCharacters.GetEntityKey(player, {
        callback = "conversation_relationship",
    })
    if not targetKey then return nil, reason end
    local relationship = relationships and relationships.Get
        and relationships.Get(record.id, targetKey) or nil
    local summary = Presentation.Summarize(
        relationship,
        relationship ~= nil
    )
    summary.npcID = tostring(record.id)
    return summary
end

return Presentation
