-- Normalized read-only context for generic interaction arbitration.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Providers = require "PNC/Semantics/PNC_SemanticInteractionProviders"
local ValueBounds = require "PNC/Semantics/PNC_SemanticValueBounds"

local Context = PNC.Semantics.InteractionContext or {}
PNC.Semantics.InteractionContext = Context

local HOSTILE_ACTS = {
    INSULT = true,
    HOSTILE_REMARK = true,
    THREATEN = true,
}

local function copy(value)
    return ValueBounds.Copy(value)
end

local function semanticOf(value)
    if type(value) ~= "table" then return {} end
    if type(value.semantic) == "table" then return value.semantic end
    return value
end

local function hostileAct(value)
    local semantic = semanticOf(value)
    return HOSTILE_ACTS[tostring(
        semantic.speechAct or semantic.intent or ""
    )] == true
end

local function currentAlreadyRecorded(stimulus, state)
    local event = state and state.lastEvent or nil
    if type(event) ~= "table" or type(stimulus) ~= "table" then return false end
    local semantic = semanticOf(stimulus)
    return tostring(event.rawText or "") == tostring(stimulus.text or "")
        and tostring(event.intent or "") == tostring(semantic.intent or "")
        and tostring(event.speechAct or "")
            == tostring(semantic.speechAct or "")
end

local function hostilityCount(stimulus, state)
    local count = 0
    local recent = state and type(state.Recent) == "function"
        and state:Recent(8, true) or {}
    for index = 1, #recent do
        if hostileAct(recent[index]) then count = count + 1 end
    end
    if hostileAct(stimulus)
        and not currentAlreadyRecorded(stimulus, state)
    then
        count = count + 1
    end
    return count
end

function Context.StateSnapshot(context)
    local live = type(context) == "table"
        and context.semanticContextState or nil
    if live and type(live.GetDirectorState) == "function" then
        return live:GetDirectorState()
    end
    local projected = type(context) == "table"
        and context.semanticDialogueContext or nil
    if type(projected) == "table"
        and type(projected.director) == "table"
    then
        return copy(projected.director)
    end
    return {
        active = nil,
        recent = {},
        cooldowns = {},
        revision = 0,
    }
end

function Context.Project(stimulus, state, context, snapshot)
    context = type(context) == "table" and context or {}
    snapshot = type(snapshot) == "table" and snapshot or {}
    stimulus = type(stimulus) == "table" and stimulus or {}
    local providers = type(context.interactionProjection) == "table"
        and context.interactionProjection
        or Providers.ProjectDialogue(context)
    local relationship = type(providers.relationship) == "table"
        and providers.relationship or {}
    local sequence = tonumber(state and state.sequence) or 0
    local active = type(snapshot.active) == "table" and snapshot.active or {}
    local familiarity = tonumber(relationship.familiarity) or 0
    return {
        schemaVersion = 1,
        stimulus = stimulus,
        actor = providers.actor or {},
        relationship = relationship,
        world = providers.world or {},
        knowledge = providers.knowledge or {},
        evidence = type(context.interactionProjection) == "table"
            and Providers.QueryEvidence(context, context.evidenceQuery)
            or providers.evidence or { rows = {}, providers = {} },
        providers = providers.provenance or {},
        scene = {
            firstContact = familiarity <= 0 and sequence <= 1,
            ended = type(context.interactionScene) == "table"
                and context.interactionScene.ended == true
                or context.conversationEnded == true,
            currentTopic = type(context.interactionScene) == "table"
                and context.interactionScene.currentTopic
                or context.currentTopic
                or context.conversationTopic,
            id = type(context.interactionScene) == "table"
                and context.interactionScene.id or nil,
            participantIDs = type(context.interactionScene) == "table"
                and copy(context.interactionScene.participantIDs) or {},
            sourceActorID = type(context.interactionScene) == "table"
                and context.interactionScene.sourceActorID or nil,
            responderActorID = type(context.interactionScene) == "table"
                and context.interactionScene.responderActorID or nil,
        },
        history = {
            hostilityCount = hostilityCount(stimulus, state),
        },
        beat = {
            turnsInBeat = tonumber(active.turns) or 0,
            activeBeatID = active.id,
        },
    }
end

return Context
