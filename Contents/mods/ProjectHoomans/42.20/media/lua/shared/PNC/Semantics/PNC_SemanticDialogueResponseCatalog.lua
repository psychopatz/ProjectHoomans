-- Data-only response pools for the deterministic semantic dialogue route.
--
-- Selection belongs here rather than in the parser or dialogue policy. A
-- response pool can therefore grow with authored content without turning the
-- semantic router into a sentence-by-sentence decision tree. Conditions are
-- deliberately small and scalar so this remains cheap, deterministic, and
-- safe to evaluate in both singleplayer and multiplayer clients.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.ResponseCatalog or {}
PNC.Semantics.ResponseCatalog = Catalog

Catalog.VERSION = 1
Catalog.MAX_POOLS = 64
Catalog.MAX_VARIANTS = 16
Catalog.POOLS = Catalog.POOLS or {}
Catalog.LAST_VARIANTS = Catalog.LAST_VARIANTS or {}

local CONDITION_FIELDS = {
    "topic", "previousTopic", "intent", "action", "subject",
    "relationshipState", "timeBand", "raining", "foggy", "snowing",
    "indoors", "hasPendingRequest", "npcID", "activity", "busy",
    "needType", "needUrgency", "relationshipAttitude", "healthState",
    "socialStyle", "emotionType", "emotionUrgency", "hostilityCount",
    "insultCount", "lastSpeechAct",
}

local function copy(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 6 then return nil end
    local output = {}
    local key
    local item
    for key, item in pairs(value) do
        if type(key) == "string" or type(key) == "number" then
            output[key] = copy(item, depth + 1)
        end
    end
    return output
end

local function validID(value)
    value = tostring(value or "")
    return value ~= ""
        and #value <= 96
        and string.find(value, "[^%w_%.%-]") == nil
end

local function boundedText(value)
    value = tostring(value or "")
    if #value > 256 then return string.sub(value, 1, 256) end
    return value
end

local function registerTextFallback(templateID, fallback)
    local text = PsychopatzCore
        and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.Text
    if text and type(text.RegisterFallback) == "function" then
        text.RegisterFallback(templateID, fallback)
    end
end

local function hash(value)
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

local function conditionContext(context)
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
    return {
        topic = context.currentTopic or context.topic,
        previousTopic = context.previousTopic,
        intent = context.intent,
        action = context.action,
        subject = context.subject,
        relationshipState = context.relationshipState,
        timeBand = world.timeBand or time.band or context.timeBand,
        raining = weather.raining,
        foggy = weather.foggy,
        snowing = weather.snowing,
        indoors = environment.indoors,
        hasPendingRequest = pendingRequest ~= nil,
        npcID = context.npcID,
        activity = context.activity or activity.id,
        busy = context.busy ~= nil and context.busy or activity.busy,
        needType = context.needType or needs.highest,
        needUrgency = context.needUrgency or needs.urgency,
        emotionType = context.emotionType or emotion.highest,
        emotionUrgency = context.emotionUrgency or emotion.urgency,
        relationshipAttitude = context.relationshipAttitude
            or social.attitude,
        healthState = context.healthState or npc.healthState,
        socialStyle = context.socialStyle or social.style,
        hostilityCount = context.hostilityCount
            or state.socialContext and state.socialContext.hostilityCount,
        insultCount = context.insultCount
            or state.socialContext and state.socialContext.insultCount,
        lastSpeechAct = context.lastSpeechAct
            or state.socialContext and state.socialContext.lastSpeechAct,
    }
end

local function matches(variant, context)
    local when = variant.when
    local actual
    local field
    local index
    if type(when) ~= "table" then return true, 0 end
    context = conditionContext(context)
    local specificity = 0
    for index = 1, #CONDITION_FIELDS do
        field = CONDITION_FIELDS[index]
        actual = context[field]
        if when[field] ~= nil then
            if not scalarMatches(when[field], actual) then return false, 0 end
            specificity = specificity + 1
        end
    end
    return true, specificity
end

local function normalizedVariant(poolID, index, value)
    if type(value) == "string" then
        value = { fallback = value }
    end
    if type(value) ~= "table" then return nil end
    local fallback = boundedText(value.fallback or value.text)
    if fallback == "" then return nil end
    local id = tostring(value.id or (poolID .. "." .. tostring(index)))
    if not validID(id) then return nil end
    local normalized = {
        id = id,
        templateID = tostring(value.templateID or id),
        fallback = fallback,
        when = copy(value.when),
        priority = tonumber(value.priority) or 0,
    }
    registerTextFallback(normalized.templateID, normalized.fallback)
    return normalized
end

function Catalog.Register(id, definition)
    local pool
    local variants
    local index
    local variant
    id = tostring(id or "")
    if not validID(id) or type(definition) ~= "table" then
        return false, "invalid_response_pool"
    end
    variants = definition.variants
    if type(variants) ~= "table" then
        return false, "response_pool_requires_variants"
    end
    pool = {
        id = id,
        variants = {},
    }
    for index = 1, math.min(#variants, Catalog.MAX_VARIANTS) do
        variant = normalizedVariant(id, index, variants[index])
        if variant then pool.variants[#pool.variants + 1] = variant end
    end
    if #pool.variants == 0 then return false, "response_pool_empty" end
    if not Catalog.POOLS[id] then
        local count = 0
        for _ in pairs(Catalog.POOLS) do count = count + 1 end
        if count >= Catalog.MAX_POOLS then return false, "response_pool_limit" end
    end
    Catalog.POOLS[id] = pool
    return true, pool
end

function Catalog.Get(id)
    return Catalog.POOLS[tostring(id or "")]
end

function Catalog.RegisterTextFallbacks()
    local count = 0
    for _, pool in pairs(Catalog.POOLS) do
        for _, variant in ipairs(pool.variants or {}) do
            registerTextFallback(variant.templateID, variant.fallback)
            count = count + 1
        end
    end
    return count
end

function Catalog.Select(id, context, salt)
    local pool = Catalog.Get(id)
    local candidates = {}
    local bestScore = nil
    local index
    local variant
    local matched
    local specificity
    local score
    local selectionKey
    local selectedIndex
    if not pool then return nil, "response_pool_unavailable" end
    for index = 1, #pool.variants do
        variant = pool.variants[index]
        matched, specificity = matches(variant, context)
        if matched then
            score = (tonumber(variant.priority) or 0) * 100
                + specificity
            if bestScore == nil or score > bestScore then
                bestScore = score
                candidates = { index }
            elseif score == bestScore then
                candidates[#candidates + 1] = index
            end
        end
    end
    if #candidates == 0 then return nil, "response_variant_unavailable" end
    selectionKey = tostring(id) .. ":"
        .. tostring(context and context.npcID or "")
    selectedIndex = candidates[
        (hash(tostring(salt or "") .. ":" .. selectionKey) % #candidates) + 1
    ]
    if #candidates > 1
        and Catalog.LAST_VARIANTS[selectionKey] == selectedIndex
    then
        -- Rotate relative to the previously selected candidate.  Hashing a
        -- second time is not sufficient: it can produce the same index again
        -- for the same salt and make a response pool appear repetitive.
        local previousPosition = nil
        local candidatePosition
        for candidatePosition = 1, #candidates do
            if candidates[candidatePosition] == selectedIndex then
                previousPosition = candidatePosition
                break
            end
        end
        if previousPosition then
            selectedIndex = candidates[
                (previousPosition % #candidates) + 1
            ]
        end
    end
    Catalog.LAST_VARIANTS[selectionKey] = selectedIndex
    variant = pool.variants[selectedIndex]
    return {
        id = variant.id,
        templateID = variant.templateID,
        fallback = variant.fallback,
    }, selectedIndex
end

function Catalog.ResetSelections()
    Catalog.LAST_VARIANTS = {}
    return true
end

-- Initial Project Hoomans pools. Keep this content outside the response
-- composer so authors can add or replace variants without editing routing.
Catalog.Register("semantic.greeting", {
    variants = {
        {
            id = "semantic.greeting.default",
            templateID = "semantic.greet.acknowledged",
            fallback = "Hey there.",
        },
        {
            id = "semantic.greeting.dawn",
            templateID = "semantic.greet.morning",
            fallback = "Good morning.",
            when = { timeBand = "dawn" },
            priority = 1,
        },
        {
            id = "semantic.greeting.rain",
            templateID = "semantic.greet.rain",
            fallback = "Hey there. Wet one today.",
            when = { raining = true },
            priority = 1,
        },
        {
            id = "semantic.greeting.fog",
            templateID = "semantic.greet.fog",
            fallback = "Hey there. Hard to see much in this fog.",
            when = { foggy = true },
            priority = 1,
        },
        {
            id = "semantic.greeting.busy",
            templateID = "semantic.greet.busy",
            fallback = "Hey. I'm in the middle of something.",
            when = { busy = true },
            priority = 0,
        },
        {
            id = "semantic.greeting.thirsty",
            templateID = "semantic.greet.thirsty",
            fallback = "Hey there. You wouldn't happen to have water, would you?",
            when = { needType = "thirst", needUrgency = { "moderate", "severe", "emergency", "critical" } },
            -- Weather and first-meet context remain the stronger opening
            -- signal; need pressure can still shape a neutral greeting.
            priority = 0,
        },
        {
            id = "semantic.greeting.first_meet",
            templateID = "semantic.greet.first_meet",
            fallback = "Hey. Don't think we've met.",
            when = { relationshipState = "FirstMeet" },
            priority = 1,
        },
        {
            id = "semantic.greeting.friendly",
            templateID = "semantic.greet.friendly",
            fallback = "Hey! Good to see you.",
            when = { socialStyle = "friendly" },
            priority = 0,
        },
        {
            id = "semantic.greeting.withdrawn",
            templateID = "semantic.greet.withdrawn",
            fallback = "Hey.",
            when = { socialStyle = "withdrawn" },
            priority = 0,
        },
    },
})

Catalog.Register("semantic.offer", {
    variants = {
        {
            id = "semantic.offer.hungry",
            templateID = "semantic.offer.interested",
            fallback = "I could use one.",
            when = {
                needType = "hunger",
                needUrgency = { "moderate", "severe", "emergency", "critical" },
            },
            priority = 2,
        },
        {
            id = "semantic.offer.default",
            templateID = "semantic.offer.declined",
            fallback = "No thanks, I'm not hungry.",
        },
    },
})

Catalog.Register("semantic.question.activity", {
    variants = {
        {
            id = "semantic.question.activity.combat",
            templateID = "semantic.question.activity.combat",
            fallback = "I'm keeping an eye on things.",
            when = { activity = "combat" },
            priority = 2,
        },
        {
            id = "semantic.question.activity.fishing",
            templateID = "semantic.question.activity.fishing",
            fallback = "I'm trying to catch something.",
            when = { activity = "fishing" },
            priority = 2,
        },
        {
            id = "semantic.question.activity.working",
            templateID = "semantic.question.activity.working",
            fallback = "I'm working on something.",
            when = { activity = "working" },
            priority = 2,
        },
        {
            id = "semantic.question.activity.traveling",
            templateID = "semantic.question.activity.traveling",
            fallback = "I'm on the move.",
            when = { activity = "traveling" },
            priority = 2,
        },
        {
            id = "semantic.question.activity.resting",
            templateID = "semantic.question.activity.resting",
            fallback = "I'm taking a breather.",
            when = { activity = "resting" },
            priority = 2,
        },
        {
            id = "semantic.question.activity.default",
            templateID = "semantic.question.activity.default",
            fallback = "Not much. Just getting by.",
        },
    },
})

Catalog.Register("semantic.question.wellbeing", {
    variants = {
        {
            id = "semantic.question.wellbeing.panic",
            templateID = "semantic.question.wellbeing.panic",
            fallback = "I'm pretty shaken up right now.",
            when = {
                emotionType = "panic",
                emotionUrgency = { "critical", "emergency" },
            },
            priority = 4,
        },
        {
            id = "semantic.question.wellbeing.stress",
            templateID = "semantic.question.wellbeing.stress",
            fallback = "I'm tense, but I can keep going.",
            when = {
                emotionType = "stress",
                emotionUrgency = { "critical", "emergency" },
            },
            priority = 3,
        },
        {
            id = "semantic.question.wellbeing.thirst",
            templateID = "semantic.question.wellbeing.thirst",
            fallback = "I've been better. I could really use some water.",
            when = { needType = "thirst", needUrgency = { "moderate", "severe", "emergency", "critical" } },
            priority = 3,
        },
        {
            id = "semantic.question.wellbeing.hunger",
            templateID = "semantic.question.wellbeing.hunger",
            fallback = "I'm pretty hungry, if I'm honest.",
            when = { needType = "hunger", needUrgency = { "moderate", "severe", "emergency", "critical" } },
            priority = 2,
        },
        {
            id = "semantic.question.wellbeing.fatigue",
            templateID = "semantic.question.wellbeing.fatigue",
            fallback = "I'm worn out, but I can still manage.",
            when = { needType = "fatigue", needUrgency = { "moderate", "severe", "emergency", "critical" } },
            priority = 2,
        },
        {
            id = "semantic.question.wellbeing.injured",
            templateID = "semantic.question.wellbeing.injured",
            fallback = "A little banged up, but I'll manage.",
            when = { healthState = { "injured", "wounded", "critical" } },
            priority = 2,
        },
        {
            id = "semantic.question.wellbeing.default",
            templateID = "semantic.question.wellbeing.default",
            fallback = "I'm okay. How about you?",
        },
    },
})

Catalog.Register("semantic.thanks", {
    variants = {
        {
            id = "semantic.thanks.default",
            templateID = "semantic.social.thanks_response",
            fallback = "You're welcome.",
        },
    },
})

Catalog.Register("semantic.accept", {
    variants = {
        {
            id = "semantic.accept.request",
            templateID = "semantic.social.accept_request",
            fallback = "All right, I'll take care of it.",
            when = { hasPendingRequest = true },
            priority = 1,
        },
        {
            id = "semantic.accept.default",
            templateID = "semantic.social.acknowledged",
            fallback = "All right.",
        },
    },
})

Catalog.Register("semantic.refuse", {
    variants = {
        {
            id = "semantic.refuse.request",
            templateID = "semantic.social.refuse_request",
            fallback = "No problem. I'll leave it.",
            when = { hasPendingRequest = true },
            priority = 1,
        },
        {
            id = "semantic.refuse.default",
            templateID = "semantic.social.acknowledged",
            fallback = "No.",
        },
    },
})

Catalog.Register("semantic.gossip", {
    variants = {
        {
            id = "semantic.gossip.unknown",
            templateID = "semantic.gossip.unknown",
            fallback = "I haven't heard anything about that yet.",
        },
    },
})

Catalog.Register("semantic.hostile_remark", {
    variants = {
        {
            id = "semantic.hostile.escalated",
            templateID = "semantic.social.hostile_escalated",
            fallback = "That's enough. Keep it up and we're done.",
            when = { hostilityCount = { 2, 3, 4, 5, 6 } },
            priority = 4,
        },
        {
            id = "semantic.hostile.default",
            templateID = "semantic.social.hostile_boundary",
            fallback = "Don't talk to me like that.",
        },
        {
            id = "semantic.hostile.short",
            templateID = "semantic.social.hostile_short",
            fallback = "Watch your mouth.",
        },
        {
            id = "semantic.hostile.withdrawn",
            templateID = "semantic.social.hostile_withdrawn",
            fallback = "Then leave me alone.",
            when = { socialStyle = "withdrawn" },
            priority = 2,
        },
        {
            id = "semantic.hostile.busy",
            templateID = "semantic.social.hostile_busy",
            fallback = "Not now. I have enough to deal with.",
            when = { busy = true },
            priority = 2,
        },
        {
            id = "semantic.hostile.stressed",
            templateID = "semantic.social.hostile_stressed",
            fallback = "I've had enough already.",
            when = {
                emotionType = { "stress", "panic" },
                emotionUrgency = {
                    "moderate", "severe", "critical", "emergency",
                },
            },
            priority = 2,
        },
    },
})

Catalog.Register("semantic.threat", {
    variants = {
        {
            id = "semantic.threat.default",
            templateID = "semantic.social.threat_boundary",
            fallback = "Back off.",
        },
        {
            id = "semantic.threat.firm",
            templateID = "semantic.social.threat_firm",
            fallback = "Don't threaten me.",
        },
        {
            id = "semantic.threat.busy",
            templateID = "semantic.social.threat_busy",
            fallback = "Pick another fight.",
            when = { busy = true },
            priority = 2,
        },
    },
})

return Catalog
