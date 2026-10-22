-- Semantic precedence and contextual ordering for normalized dialogue choices.
--
-- This module ranks already-eligible projections. It does not discover facts,
-- decide authority, change click frames, or execute gameplay effects.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Ranking = PNC.Semantics.DialogueChoiceRanking or {}
PNC.Semantics.DialogueChoiceRanking = Ranking

Ranking.VERSION = 1
Ranking.SCHEMA = "semantic.choice.ranking.v1"

local Style = PNC.Semantics.SpeechStyleContext
    or require "PNC/Semantics/PNC_SpeechStyleContext"
local ActorContext = PNC.Semantics.ActorConversationContext
    or require "PNC/Semantics/PNC_ActorConversationContext"

local CLASSES = {
    "BRANCH_CONTINUATION",
    "DIRECT_RESPONSE",
    "CONTEXTUAL_SOCIAL",
    "ACTIVE_TOPIC",
    "GAMEPLAY_ACTION",
    "GENERAL_TOPIC",
    "UTILITY",
}

local CLASS_ORDER = {}
for index = 1, #CLASSES do CLASS_ORDER[CLASSES[index]] = index end

local function text(value)
    return string.lower(tostring(value or ""))
end

local function copy(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 3 then return nil end
    local output = {}
    local count = 0
    for key, item in pairs(value) do
        if count >= 16 then break end
        if type(key) == "string" or type(key) == "number" then
            output[key] = copy(item, depth + 1)
            count = count + 1
        end
    end
    return output
end

local function sourceKind(candidate)
    return text(candidate and candidate.source and candidate.source.kind)
end

local function route(candidate)
    local frame = candidate and candidate.frame or {}
    local extensions = type(frame.extensions) == "table"
        and frame.extensions or {}
    return text(extensions.route)
end

local function injured(actor)
    local situation = type(actor.situation) == "table"
        and actor.situation or {}
    local healthState = text(situation.healthState)
    return healthState == "injured" or healthState == "wounded"
        or healthState == "critical"
end

local function severeNeeds(actor)
    local situation = type(actor.situation) == "table"
        and actor.situation or {}
    local needs = type(situation.needs) == "table" and situation.needs or {}
    return (tonumber(needs.hunger) or 0) >= 0.75
        or (tonumber(needs.thirst) or 0) >= 0.75
        or (tonumber(needs.fatigue) or 0) >= 0.75
end

function Ranking.ClassFor(candidate, actor, currentTopic)
    local kind = sourceKind(candidate)
    local candidateID = text(candidate and candidate.id)
    actor = type(actor) == "table" and actor or {}
    currentTopic = text(currentTopic)
    if kind == "active_flow" or kind == "conversation_registry"
        or route(candidate) == "conversation_choice"
    then
        return "BRANCH_CONTINUATION"
    end
    if kind == "npc_response_plan" then return "DIRECT_RESPONSE" end
    if kind == "permitted_capability" or kind == "dynamic_trading"
        or candidate and candidate.providerID == "dynamictrading.trader"
        or candidate and candidate.action ~= nil
    then
        return "GAMEPLAY_ACTION"
    end
    if kind == "social_context" then return "CONTEXTUAL_SOCIAL" end
    if kind == "typed_input" then
        if currentTopic == "whats_up"
            and candidateID == "question.health" and injured(actor)
        then
            return "CONTEXTUAL_SOCIAL"
        end
        if currentTopic == "whats_up"
            and candidateID == "question.needs" and severeNeeds(actor)
        then
            return "CONTEXTUAL_SOCIAL"
        end
        if candidateID == "question.wellbeing_detail" then
            return "CONTEXTUAL_SOCIAL"
        end
        return "ACTIVE_TOPIC"
    end
    if kind == "conversation_root" then return "GENERAL_TOPIC" end
    if kind == "conversation_registry" then return "BRANCH_CONTINUATION" end
    if kind == "conversation_category" then return "GENERAL_TOPIC" end
    return "UTILITY"
end

local function contextFit(candidate, actor, style, currentTopic)
    local fit = 0
    local topic = text(candidate and candidate.topic)
    currentTopic = text(currentTopic)
    if currentTopic ~= "" and topic == currentTopic then fit = fit + 4 end

    local situation = actor.situation or {}
    local roles = actor.roles or {}
    local needs = situation.needs or {}
    local healthState = text(situation.healthState)
    if topic == "medical"
        and (healthState == "injured" or healthState == "wounded"
            or healthState == "critical")
    then
        fit = fit + (currentTopic == "whats_up" and 12 or 6)
    end
    if topic == "needs"
        and (tonumber(needs.hunger) or 0) >= 0.75
            or topic == "needs"
            and (tonumber(needs.thirst) or 0) >= 0.75
            or topic == "needs"
            and (tonumber(needs.fatigue) or 0) >= 0.75
    then
        fit = fit + (currentTopic == "whats_up" and 8 or 6)
    end
    if roles.companion == true and candidate and candidate.action ~= nil then
        fit = fit + 2
    end
    if style.variant == "warm" and candidate
        and candidate.id == "question.wellbeing_detail"
    then
        fit = fit + 2
    elseif style.variant == "guarded" and candidate
        and candidate.id == "question.health"
    then
        fit = fit + 2
    end
    if situation.activeBehavior == "busy"
        and candidate and candidate.id == "question.health"
    then
        fit = fit + 1
    end
    return fit
end

local function annotate(candidate, actor, style, currentTopic, orderHint)
    local class = Ranking.ClassFor(candidate, actor, currentTopic)
    local classOrder = CLASS_ORDER[class] or CLASS_ORDER.UTILITY
    local id = tostring(candidate and candidate.id or "")
    local fit = contextFit(candidate, actor, style, currentTopic)
    candidate.ranking = {
        schema = Ranking.SCHEMA,
        class = class,
        classOrder = classOrder,
        orderHint = tonumber(orderHint) or 0,
        stableTieBreak = id,
    }
    return {
        candidate = candidate,
        classOrder = classOrder,
        fit = fit,
        providerOrder = tonumber(candidate.providerOrder) or 0,
        orderHint = tonumber(orderHint) or 0,
        stableTieBreak = id,
    }
end

local function before(left, right)
    if left.classOrder ~= right.classOrder then
        return left.classOrder < right.classOrder
    end
    if left.fit ~= right.fit then return left.fit > right.fit end
    if left.providerOrder ~= right.providerOrder then
        return left.providerOrder < right.providerOrder
    end
    if left.orderHint ~= right.orderHint then
        return left.orderHint < right.orderHint
    end
    return left.stableTieBreak < right.stableTieBreak
end

local function applyRankOrder(candidates, actor, style, currentTopic)
    local rows = {}
    for index, candidate in ipairs(candidates or {}) do
        rows[#rows + 1] = annotate(
            candidate, actor, style, currentTopic, candidate.rank or index
        )
    end
    table.sort(rows, before)
    local output = {}
    for index, row in ipairs(rows) do
        row.candidate.rank = index
        row.candidate.ranking.order = index
        output[index] = row.candidate
    end
    return output
end

function Ranking.Apply(candidates, capabilities, context, currentTopic)
    context = type(context) == "table" and context or {}
    local actor = context.actorConversationContext
    if type(actor) ~= "table" then actor = ActorContext.Build(context) end
    local style = Style.Resolve(context)
    local ordered = applyRankOrder(candidates, actor, style, currentTopic)
    for index, capability in ipairs(capabilities or {}) do
        annotate(capability, actor, style, currentTopic, capability.rank or index)
    end
    return {
        schema = Ranking.SCHEMA,
        classOrder = copy(CLASS_ORDER),
        candidateCount = #ordered,
        privacy = {
            privateFieldsInspected = false,
            privateRelationshipScoresExposed = false,
            undiscoveredFactsExposed = false,
        },
    }, ordered
end

function Ranking.Classes()
    local output = {}
    for index = 1, #CLASSES do output[index] = CLASSES[index] end
    return output
end

return Ranking
