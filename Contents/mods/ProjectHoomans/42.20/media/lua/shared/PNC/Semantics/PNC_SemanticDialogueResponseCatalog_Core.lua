-- Shared bounds, normalization, and condition matching helpers.

local ResponsePlan = require
    "PNC/Semantics/PNC_SemanticDialogueResponsePlan"

local Core = {}

Core.CONDITION_FIELDS = {
    "topic", "previousTopic", "previousAction", "lastIntent", "lastAction", "lastSpeaker",
    "intent", "action", "subject", "pattern",
    "relationshipState", "identityTrust", "timeBand", "raining", "foggy", "snowing",
    "indoors", "hasPendingRequest", "npcID", "activity", "busy",
    "memoryAvailable",
    "needType", "needUrgency", "relationshipAttitude", "healthState",
    "socialStyle", "emotionType", "emotionUrgency", "hostilityCount",
    "insultCount", "lastSpeechAct",
    "eventType", "commandID", "commandReason",
    "downedAudience", "downedNeed", "downedThreat",
    "leaderGrief", "leaderSuccession", "corpseRevenge",
}

function Core.copy(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 6 then return nil end
    local output = {}
    local key
    local item
    for key, item in pairs(value) do
        if type(key) == "string" or type(key) == "number" then
            output[key] = Core.copy(item, depth + 1)
        end
    end
    return output
end

function Core.validID(value)
    value = tostring(value or "")
    return value ~= ""
        and #value <= 96
        and string.find(value, "[^%w_%.%-]") == nil
end

function Core.boundedText(value)
    value = tostring(value or "")
    if #value > 256 then return string.sub(value, 1, 256) end
    return value
end

function Core.registerTextFallback(templateID, fallback)
    local text = PsychopatzCore
        and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.Text
    if text and type(text.RegisterFallback) == "function" then
        text.RegisterFallback(templateID, fallback)
    end
end

function Core.hash(value)
    local output = 0
    value = tostring(value or "")
    for index = 1, #value do
        output = (output * 31 + string.byte(value, index)) % 2147483647
    end
    return output
end

local function scalarMatches(expected, actual)
    if expected == nil then return true end
    if type(expected) == "table" then
        for index = 1, #expected do
            if scalarMatches(expected[index], actual) then return true end
        end
        return false
    end
    if type(expected) == "boolean" then return expected == (actual == true) end
    return tostring(expected) == tostring(actual)
end

function Core.conditionContext(context)
    context = type(context) == "table" and context or {}
    local world = context.worldContext or {}
    local time = world.time or {}
    local weather = world.weather or {}
    local environment = world.environment or {}
    local state = context.semanticDialogueState or {}
    local pendingRequest = context.pendingRequest
        or state.pendingRequest
    local situation = context.dialogueSituation or {}
    local npc = situation.npc or {}
    local activity = npc.activity or {}
    local needs = npc.needs or {}
    local emotion = npc.emotion or {}
    local social = situation.social or {}
    local gossip = context.npcGossip
    local healthState = context.healthState or npc.healthState
    -- Keep missing health evidence distinct from a known healthy state for
    -- response selection. The routed situation remains source-faithful and
    -- continues to omit the field when the NPC health fact is unavailable.
    if type(healthState) ~= "string" or healthState == "" then
        healthState = "unknown"
    end
    return {
        topic = context.currentTopic or context.topic,
        previousTopic = context.previousTopic,
        previousAction = context.previousAction,
        lastIntent = context.lastIntent,
        lastAction = context.lastAction,
        lastSpeaker = context.lastSpeaker,
        intent = context.intent,
        action = context.action,
        subject = context.subject,
        pattern = context.pattern,
        eventType = context.eventType,
        commandID = context.commandID,
        commandReason = context.commandReason,
        relationshipState = context.relationshipState,
        identityTrust = context.identityTrust,
        timeBand = world.timeBand or time.band or context.timeBand,
        raining = weather.raining,
        foggy = weather.foggy,
        snowing = weather.snowing,
        indoors = environment.indoors,
        hasPendingRequest = pendingRequest ~= nil,
        npcID = context.npcID,
        activity = context.activity or activity.id,
        busy = context.busy ~= nil and context.busy or activity.busy,
        memoryAvailable = type(gossip) == "table"
            and type(gossip.statements) == "table"
            and #gossip.statements > 0 or false,
        needType = context.needType or needs.highest,
        needUrgency = context.needUrgency or needs.urgency,
        emotionType = context.emotionType or emotion.highest,
        emotionUrgency = context.emotionUrgency or emotion.urgency,
        relationshipAttitude = context.relationshipAttitude
            or social.attitude,
        healthState = healthState,
        socialStyle = context.socialStyle or social.style,
        hostilityCount = context.hostilityCount
            or state.socialContext and state.socialContext.hostilityCount,
        insultCount = context.insultCount
            or state.socialContext and state.socialContext.insultCount,
        lastSpeechAct = context.lastSpeechAct
            or state.socialContext and state.socialContext.lastSpeechAct,
        downedAudience = context.downedAudience,
        downedNeed = context.downedNeed,
        downedThreat = context.downedThreat,
        leaderGrief = context.leaderGrief,
        leaderSuccession = context.leaderSuccession,
        corpseRevenge = context.corpseRevenge,
    }
end

function Core.matches(variant, context)
    local when = variant.when
    local actual
    local field
    local index
    if type(when) ~= "table" then return true, 0 end
    context = Core.conditionContext(context)
    local specificity = 0
    for index = 1, #Core.CONDITION_FIELDS do
        field = Core.CONDITION_FIELDS[index]
        actual = context[field]
        if when[field] ~= nil then
            if not scalarMatches(when[field], actual) then return false, 0 end
            specificity = specificity + 1
        end
    end
    return true, specificity
end

function Core.normalizedVariant(poolID, index, value)
    if type(value) == "string" then
        value = { fallback = value }
    end
    if type(value) ~= "table" then return nil end
    local fallback = Core.boundedText(value.fallback or value.text)
    if fallback == "" then return nil end
    local id = tostring(value.id or (poolID .. "." .. tostring(index)))
    if not Core.validID(id) then return nil end
    local plan
    if value.plan ~= nil then
        local valid, normalized = ResponsePlan.Build(value.plan)
        if not valid then return nil end
        plan = normalized
    end
    local normalized = {
        id = id,
        templateID = tostring(value.templateID or id),
        fallback = fallback,
        compatibilityFlavorID = value.compatibilityFlavorID,
        plan = plan,
        dialogueAct = value.dialogueAct,
        topic = value.topic,
        groundedFactRefs = Core.copy(
            value.groundedFactRefs or value.sourceFactRefs
        ),
        uncertainty = value.uncertainty,
        tone = value.tone,
        personalityStyle = value.personalityStyle,
        translationArgs = Core.copy(value.translationArgs),
        when = Core.copy(value.when),
        priority = tonumber(value.priority) or 0,
    }
    Core.registerTextFallback(normalized.templateID, normalized.fallback)
    return normalized
end

function Core.install(Catalog)
    Catalog.VERSION = 1
    Catalog.MAX_POOLS = 256
    Catalog.MAX_VARIANTS = 16
    Catalog.MAX_LAST_VARIANTS = 256
    Catalog.POOLS = Catalog.POOLS or {}
    Catalog.LAST_VARIANTS = Catalog.LAST_VARIANTS or {}
    Catalog.LAST_VARIANT_ORDER = Catalog.LAST_VARIANT_ORDER or {}
end

return Core
