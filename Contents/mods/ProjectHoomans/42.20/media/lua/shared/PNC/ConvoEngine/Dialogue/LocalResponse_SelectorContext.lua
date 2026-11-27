-- Deterministic response selector context and social turn counter helpers.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Response = PNC.ConvoEngine.LocalResponse or {}
PNC.ConvoEngine.LocalResponse = Response
Response.Internal = Response.Internal or {}
local Internal = Response.Internal

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

local function resolveInjury(context)
    local sit = PNC.ConvoEngine.DialogueSituation
    local fn = sit and sit.Internal and sit.Internal.ResolveInjuryState
    if type(fn) == "function" then
        return fn(context)
    end
    return type(context) == "table" and context.npcState or nil
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
    local injury = type(npc.injury) == "table" and npc.injury or resolveInjury(context) or {}
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
        action = (ir and ir.action) or context.action,
        subject = ir and ir.subject,
        stateValue = ir and (ir.stateValue or (ir.slots and ir.slots.state and ir.slots.state.value)),
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
        healthState = npc.healthState or injury.healthState,
        knoxExposure = injury.knoxExposure,
        salivaTransmissible = injury.salivaTransmissible,
        isBitten = injury.isBitten,
        hasOpenWounds = injury.hasOpenWounds,
        relationshipAttitude = social.attitude,
        socialStyle = (function()
            local base = context.socialStyle or social.style
            local sc = type(ir) == "table" and type(ir.socialContext) == "table"
                and ir.socialContext or nil
            if not sc then return base end
            local tone = tostring(sc.playerTone or "neutral")
            if sc.selfDirected ~= true and (sc.playerRude == true or tone == "hostile") then
                if base == nil or base == "neutral" or base == "warm" or base == "friendly" then
                    return "guarded"
                end
            elseif sc.playerShouting == true or tone == "urgent" then
                if base == nil or base == "neutral" then
                    return "terse"
                end
            elseif sc.playerPolite == true then
                if base == nil or base == "neutral" then
                    return "warm"
                end
            end
            return base
        end)(),
        playerTone = type(ir) == "table" and type(ir.socialContext) == "table"
            and ir.socialContext.playerTone or nil,
        playerRude = type(ir) == "table" and type(ir.socialContext) == "table"
            and ir.socialContext.playerRude == true or false,
        playerShouting = type(ir) == "table" and type(ir.socialContext) == "table"
            and ir.socialContext.playerShouting == true or false,
        playerPolite = type(ir) == "table" and type(ir.socialContext) == "table"
            and ir.socialContext.playerPolite == true or false,
        hostilityCount = hostilityCount,
        insultCount = insultCount,
        lastSpeechAct = lastSpeechAct,
        socialRole = context.socialRole or social.role,
        farewellSpeaker = context.farewellSpeaker,
        worldRaiderSurge = context.worldRaiderSurge,
        npcAnnoyed = context.npcAnnoyed,
        npcFedUp = context.npcFedUp,
    }
end

Internal.SocialCounts = socialCounts
Internal.SelectorContext = selectorContext

return Response
