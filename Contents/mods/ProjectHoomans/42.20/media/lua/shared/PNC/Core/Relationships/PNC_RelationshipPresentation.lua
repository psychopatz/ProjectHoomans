-- Shared, player-safe relationship presentation data.  Both the conversation
-- overlay and developer inspector use this instead of maintaining parallel
-- attitude/score formatting rules.

PNC = PNC or {}
PNC.RelationshipPresentation = PNC.RelationshipPresentation or {}

local Presentation = PNC.RelationshipPresentation

Presentation.DebugStandingPresets = {
    admire = { label = "Admire", approval = 65, respect = 65 },
    pity = { label = "Pity", approval = 65, respect = -65 },
    fear = { label = "Fear", approval = -65, respect = 65 },
    despise = { label = "Despise", approval = -65, respect = -65 },
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
    local summary = {
        exists = exists == true,
        approval = number(relationship.approval),
        respect = number(relationship.respect),
        familiarity = number(relationship.familiarity),
        state = tostring(relationship.state or "unknown"),
        previousState = tostring(relationship.previousState or "unknown"),
        revision = math.max(0, math.floor(number(relationship.revision))),
    }
    if PNC.RelationshipTypes
        and PNC.RelationshipTypes.NormalizeInteractionJournal
    then
        summary.interactionRevision = math.max(
            0,
            math.floor(number(relationship.interactionRevision))
        )
        summary.interactionJournal = PNC.RelationshipTypes
            .NormalizeInteractionJournal(relationship.interactionJournal)
    end
    return summary
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

local function buildRecruitmentPreview(record, relationship)
    local graph = PNC.RelationshipGraph
    if not graph or not graph.EvaluateRecruitment then return nil end
    local personality = graph.ResolveNPCPersonality
        and graph.ResolveNPCPersonality(record) or {}
    local evaluation = graph.EvaluateRecruitment(
        relationship and relationship.approval,
        relationship and relationship.respect,
        personality
    )
    if not evaluation then return nil end
    return {
        -- This is a derived adjustment only; personality fields are not sent
        -- to the client. The graph uses it to mirror the server score.
        graphContext = { bonus = evaluation.contextBonus },
        score = evaluation.score,
        threshold = evaluation.threshold,
        margin = evaluation.margin,
        personalityBreakdown = evaluation.personalityBreakdown
            and PNC.RecruitmentPersonalityPolicy
            and PNC.RecruitmentPersonalityPolicy.CopyBreakdown
            and PNC.RecruitmentPersonalityPolicy.CopyBreakdown(
                evaluation.personalityBreakdown
            ) or nil,
        approvalMinimum = evaluation.requirement.minimumApproval,
        respectMinimum = evaluation.requirement.minimumRespect,
        meetsMinimums = evaluation.meetsMinimums == true,
        normalEligible = evaluation.normal == true,
        fearEligible = evaluation.fear == true,
    }
end

local function buildDeparturePreview(record, relationship)
    local policy = PNC.ColonistDeparturePolicy
    local graph = PNC.RelationshipGraph
    if not policy or not policy.Evaluate then return nil end
    local personality = graph and graph.ResolveNPCPersonality
        and graph.ResolveNPCPersonality(record) or {}
    local evaluation = policy.Evaluate(
        relationship and relationship.approval,
        relationship and relationship.respect,
        personality
    )
    return policy.CopyPreview and policy.CopyPreview(evaluation) or evaluation
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
    summary.recruitmentPreview = buildRecruitmentPreview(
        record,
        relationship
    )
    summary.departurePreview = buildDeparturePreview(record, relationship)
    -- These fields are intentionally part of the player's own presentation
    -- response. They make SP/MP identity drift diagnosable without exposing
    -- another player's relationship data.
    summary.identityKey = targetKey
    summary.relationshipLookup = relationship and "matched" or "missing"
    summary.socialRevision = record.social
        and tonumber(record.social.revision) or 0
    summary.identityDiagnostics = {
        accountIdentity = targetKey
            and tostring(string.match(targetKey, "^player:([^:]+):") or "")
            or nil,
        characterUUID = targetKey
            and tostring(string.match(targetKey, ":([^:]+)$") or "")
            or nil,
        relationshipRevision = summary.revision,
        interactionRevision = summary.interactionRevision or 0,
    }
    return summary
end

return Presentation
