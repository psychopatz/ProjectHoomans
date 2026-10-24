-- Small deterministic response composer for high-confidence semantic turns.
--
-- This is intentionally a response-layer extension, not parser logic. It
-- reads an observation snapshot and produces a presentation-safe fallback;
-- it does not mutate the world or perform an NPC action.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Response = PNC.Semantics.LocalResponse or {}
PNC.Semantics.LocalResponse = Response

Response.VERSION = 1
Response.Internal = Response.Internal or {}
local Catalog = PNC.Semantics.ResponseCatalog
if type(Catalog) ~= "table" then
    local loaded = require
        "PNC/Semantics/PNC_SemanticDialogueResponseCatalog"
    Catalog = type(loaded) == "table" and loaded or nil
end

local function identityKnown(context)
    context = type(context) == "table" and context or {}
    if context.identityState == "known"
        or context.identityKnown == true
    then
        return true
    end
    local actor = type(context.actorConversationContext) == "table"
        and context.actorConversationContext or {}
    local identity = type(actor.identity) == "table"
        and actor.identity or {}
    if identity.state == "known" then return true end
    -- Companion authority does not disclose NPC identity. Identity is a
    -- player-scoped knowledge fact and becomes known only through the
    -- authoritative identity presentation below.
    local clientState = PNC.Network and PNC.Network.ClientState or nil
    local presentations = clientState and clientState.npcPresentations
        or nil
    local presentation = presentations
        and presentations[tostring(context.npcID or "")] or nil
    return type(presentation) == "table"
        and (presentation.state == "known"
            or presentation.canAskName == false)
end

Response.Internal.IdentityKnown = identityKnown
local ResponsePlan = PNC.Semantics.ResponsePlan
if type(ResponsePlan) ~= "table" then
    local loaded = require
        "PNC/Semantics/PNC_SemanticDialogueResponsePlan"
    ResponsePlan = type(loaded) == "table" and loaded or nil
end

local LEGACY_TEXT_FALLBACKS = {
    ["semantic.question.time"] = "I can't tell the exact time.",
    ["semantic.question.date"] = "I don't know today's date.",
    ["semantic.question.weather"] =
        "I can't tell what the weather's doing right now.",
    ["semantic.question.identity"] = "I'm a survivor.",
    ["semantic.identity.exchange"] = "Nice to meet you. I'm a survivor.",
    ["semantic.identity.evasion"] =
        "I asked you your name. Don't just change the subject.",
    ["semantic.social.self_reflection"] =
        "Don't talk about yourself like that.",
    ["semantic.question.location"] =
        "I know where they are, but not exactly.",
    ["semantic.question.location_unknown"] = "I don't know where they are.",
    ["semantic.question.seen_yes"] = "Yes, I saw them.",
    ["semantic.question.seen_no"] = "No, I haven't seen them.",
    ["semantic.question.seen_unknown"] =
        "I don't know if I've seen them.",
    ["semantic.question.fact_clarification"] =
        "I'm not sure which person you mean.",
}

function Response.RegisterTextFallbacks()
    local text = PsychopatzCore
        and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.Text
    if not text or type(text.RegisterFallback) ~= "function" then
        return 0
    end
    local count = 0
    for key, fallback in pairs(LEGACY_TEXT_FALLBACKS) do
        text.RegisterFallback(key, fallback)
        count = count + 1
    end
    return count
end

Response.RegisterTextFallbacks()

local function copyArgs(values)
    local output = {}
    if type(values) ~= "table" then return output end
    local key
    local value
    for key, value in pairs(values) do output[key] = value end
    return output
end

local function copyList(values)
    local output = {}
    if type(values) ~= "table" then return output end
    for index = 1, #values do output[index] = values[index] end
    return output
end

local FALLBACK_ARGUMENT_ORDER = {
    "content", "topic", "location", "npcName", "playerName", "activity",
    "kind", "factStatus", "weather", "needType", "hour", "minute",
    "gameDay", "state",
}

local function renderFallback(fallback, args, translationArgs)
    local values = {}
    local index
    local key
    local value
    if type(fallback) ~= "string" or type(args) ~= "table" then
        return fallback
    end
    for index = 1, #FALLBACK_ARGUMENT_ORDER do
        key = FALLBACK_ARGUMENT_ORDER[index]
        value = args[key]
        if value ~= nil then values[index] = tostring(value) end
    end
    -- Keep generated typed argument bindings useful in a headless/local
    -- fallback too. The Core translation manager receives the original args
    -- separately; this only prevents a numbered placeholder from leaking into
    -- the response plan when a catalog key is not yet registered.
    if type(translationArgs) == "table" then
        for key, _ in pairs(translationArgs) do
            if type(key) == "string" and args[key] ~= nil then
                for index = 1, #FALLBACK_ARGUMENT_ORDER do
                    if FALLBACK_ARGUMENT_ORDER[index] == key then
                        values[index] = tostring(args[key])
                        break
                    end
                end
            end
        end
    end
    return string.gsub(fallback, "%%([1-9][0-9]*)", function(number)
        local position = tonumber(number)
        return values[position] or "%" .. tostring(number)
    end)
end

local function socialCounts(state)
    local hostilityCount = 0
    local insultCount = 0
    local lastSpeechAct
    local events = state and type(state.Recent) == "function"
        and state:Recent(8, true) or {}
    local index
    local event
    for index = 1, #events do
        event = events[index]
        if index == 1 then lastSpeechAct = event.speechAct end
        if event.speechAct == "INSULT"
            or event.speechAct == "HOSTILE_REMARK"
            or event.speechAct == "THREATEN"
        then
            hostilityCount = hostilityCount + 1
        end
        if event.speechAct == "INSULT" then insultCount = insultCount + 1 end
    end
    return hostilityCount, insultCount, lastSpeechAct
end

local function selectorContext(ir, state, context)
    context = type(context) == "table" and context or {}
    local world = type(context.worldContext) == "table"
        and context.worldContext or {}
    local time = type(world.time) == "table" and world.time or {}
    local situation = type(context.dialogueSituation) == "table"
        and context.dialogueSituation or {}
    local npc = type(situation.npc) == "table" and situation.npc or {}
    local activity = type(npc.activity) == "table" and npc.activity or {}
    local needs = type(npc.needs) == "table" and npc.needs or {}
    local emotion = type(npc.emotion) == "table" and npc.emotion or {}
    local social = type(situation.social) == "table" and situation.social or {}
    local hostilityCount, insultCount, lastSpeechAct = socialCounts(state)
    local previousAction
    local dialogue = type(context.semanticDialogueContext) == "table"
        and context.semanticDialogueContext or nil
    local recentTurns = dialogue and dialogue.recentTurns or nil
    local currentSequence = dialogue and tonumber(dialogue.sequence) or nil
    local skippedCurrent = false
    if type(recentTurns) == "table" then
        for index = 1, math.min(#recentTurns, 8) do
            local turn = recentTurns[index]
            if type(turn) == "table" and turn.speaker == "player"
                and type(turn.action) == "string"
            then
                if currentSequence ~= nil
                    and tonumber(turn.sequence) == currentSequence
                then
                    skippedCurrent = true
                elseif not skippedCurrent then
                    skippedCurrent = true
                else
                    previousAction = turn.action
                    break
                end
            end
        end
    end
    local topic = ir and ir.extensions and ir.extensions.topic or nil
    if type(topic) == "table" then
        topic = topic.id or topic.key
    end
    return {
        npcID = context.npcID,
        currentTopic = topic or state and state.currentTopic
            or context.currentTopic,
        previousTopic = state and state.previousTopic
            or context.previousTopic,
        previousAction = previousAction,
        lastIntent = state and state.lastIntent or context.lastIntent,
        lastAction = state and state.lastAction or context.lastAction,
        lastSpeaker = state and state.lastSpeaker or context.lastSpeaker,
        intent = ir and ir.intent,
        action = ir and ir.action,
        subject = ir and ir.subject,
        pattern = ir and ir.provenance and ir.provenance.pattern,
        relationshipState = context.relationshipState
            or context.conversationRelationshipID,
        identityTrust = context.identityTrust,
        pendingRequest = state and state.pendingRequest
            or context.pendingRequest,
        worldContext = world,
        timeBand = world.timeBand or time.band or context.timeBand,
        activity = activity.id,
        busy = activity.busy,
        memoryAvailable = type(context.npcGossip) == "table"
            and type(context.npcGossip.statements) == "table"
            and #context.npcGossip.statements > 0 or false,
        needType = needs.highest,
        needUrgency = needs.urgency,
        emotionType = emotion.highest,
        emotionUrgency = emotion.urgency,
        healthState = npc.healthState,
        relationshipAttitude = social.attitude,
        socialStyle = context.socialStyle or social.style,
        hostilityCount = hostilityCount,
        insultCount = insultCount,
        lastSpeechAct = lastSpeechAct,
    }
end

local function catalogResponse(poolID, ir, state, context, args)
    if not Catalog or type(Catalog.Select) ~= "function" then return nil end
    local selected = Catalog.Select(
        poolID,
        selectorContext(ir, state, context),
        tostring(state and state.sequence or 0) .. ":"
            .. tostring(ir and ir.rawText or "")
    )
    if type(selected) ~= "table" then return nil end
    local plan
    if type(selected.plan) == "table"
        and ResponsePlan and type(ResponsePlan.Build) == "function"
    then
        local valid, normalized = ResponsePlan.Build(selected.plan)
        if valid then plan = normalized end
    end
    return {
        templateID = selected.templateID or selected.id,
        fallback = renderFallback(
            selected.fallback, args, selected.translationArgs
        ),
        args = copyArgs(args),
        sourcePoolID = poolID,
        plan = plan,
        dialogueAct = selected.dialogueAct,
        topic = selected.topic,
        groundedFactRefs = copyList(selected.groundedFactRefs),
        uncertainty = selected.uncertainty,
        tone = selected.tone,
        personalityStyle = selected.personalityStyle,
        translationArgs = copyArgs(selected.translationArgs),
        selectionSource = "catalog",
        selectionID = selected.id,
    }
end


Response.Internal = Response.Internal or {}
local Internal = Response.Internal
Internal.CopyArgs = copyArgs
Internal.CopyList = copyList
Internal.RenderFallback = renderFallback
Internal.SocialCounts = socialCounts
Internal.SelectorContext = selectorContext
Internal.CatalogResponse = catalogResponse
Internal.ResponsePlan = ResponsePlan

return Response
