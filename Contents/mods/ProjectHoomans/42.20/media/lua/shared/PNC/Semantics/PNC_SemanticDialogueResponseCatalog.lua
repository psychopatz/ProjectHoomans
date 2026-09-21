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
local GeneratedDialogue = require
    "PNC/Semantics/PNC_SemanticGeneratedDialogue"

Catalog.VERSION = 1
Catalog.MAX_POOLS = 64
Catalog.MAX_VARIANTS = 16
Catalog.POOLS = Catalog.POOLS or {}
Catalog.LAST_VARIANTS = Catalog.LAST_VARIANTS or {}

local CONDITION_FIELDS = {
    "topic", "previousTopic", "intent", "action", "subject",
    "relationshipState", "identityTrust", "timeBand", "raining", "foggy", "snowing",
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

function Catalog.Extend(id, definition)
    id = tostring(id or "")
    local pool = Catalog.Get(id)
    local variants = type(definition) == "table" and definition.variants
    if not pool then return false, "response_pool_unavailable" end
    if type(variants) ~= "table" or #variants == 0 then
        return false, "response_pool_requires_variants"
    end
    if #pool.variants + #variants > Catalog.MAX_VARIANTS then
        return false, "response_variant_limit"
    end

    local seenIDs = {}
    local index
    local variant
    for index = 1, #pool.variants do
        variant = pool.variants[index]
        seenIDs[variant.id] = true
    end
    local additions = {}
    local normalized
    for index = 1, #variants do
        normalized = normalizedVariant(id, #pool.variants + index, variants[index])
        if not normalized then return false, "invalid_response_variant" end
        if seenIDs[normalized.id] then
            return false, "duplicate_response_variant_id"
        end
        seenIDs[normalized.id] = true
        additions[#additions + 1] = normalized
    end
    for index = 1, #additions do
        pool.variants[#pool.variants + 1] = additions[index]
    end
    return true, pool
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
            fallback = "I'd really like one. Could I have it?",
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

Catalog.Register("semantic.question.identity", {
    variants = {
        {
            id = "semantic.question.identity.default",
            templateID = "semantic.question.identity",
            fallback = "I'll tell you my name once we've established some trust. What's your name?",
        },
        {
            id = "semantic.question.identity.untrustworthy",
            templateID = "semantic.question.identity",
            fallback = "I don't share my name with liars. What's yours, truthfully?",
            when = { identityTrust = "untrustworthy" },
            priority = 2,
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
            fallback = "I'm pretty thirsty. Could you spare some water?",
            when = { needType = "thirst", needUrgency = { "moderate", "severe", "emergency", "critical" } },
            priority = 3,
        },
        {
            id = "semantic.question.wellbeing.thirst_alt",
            templateID = "semantic.question.wellbeing.thirst_alt",
            fallback = "I could really use a drink. Do you have any water?",
            when = { needType = "thirst", needUrgency = { "moderate", "severe", "emergency", "critical" } },
            priority = 3,
        },
        {
            id = "semantic.question.wellbeing.hunger",
            templateID = "semantic.question.wellbeing.hunger",
            fallback = "I'm pretty hungry, if I'm honest. Do you have anything to eat?",
            when = { needType = "hunger", needUrgency = { "moderate", "severe", "emergency", "critical" } },
            priority = 2,
        },
        {
            id = "semantic.question.wellbeing.hunger_alt",
            templateID = "semantic.question.wellbeing.hunger_alt",
            fallback = "I'm getting hungry. Could you spare something to eat?",
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
            id = "semantic.question.wellbeing.fatigue_alt",
            templateID = "semantic.question.wellbeing.fatigue_alt",
            fallback = "I'm tired. A little rest would help.",
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

Catalog.Register("semantic.self_state", {
    variants = {
        {
            id = "semantic.self_state.wellbeing",
            templateID = "semantic.self_state.wellbeing",
            fallback = "I'm glad to hear it. Thanks for checking in.",
            when = { subject = "WELLBEING" },
            priority = 2,
        },
        {
            id = "semantic.self_state.wellbeing_alt",
            templateID = "semantic.self_state.wellbeing_alt",
            fallback = "That's good to hear. I appreciate you asking.",
            when = { subject = "WELLBEING" },
            priority = 2,
        },
        {
            id = "semantic.self_state.hunger",
            templateID = "semantic.self_state.hunger",
            fallback = "Sorry to hear that. I hope we find something to eat soon.",
            when = { subject = "HUNGER" },
            priority = 2,
        },
        {
            id = "semantic.self_state.hunger_alt",
            templateID = "semantic.self_state.hunger_alt",
            fallback = "That sounds rough. Let's keep an eye out for food.",
            when = { subject = "HUNGER" },
            priority = 2,
        },
        {
            id = "semantic.self_state.thirst",
            templateID = "semantic.self_state.thirst",
            fallback = "I hope we can find some water for you soon.",
            when = { subject = "THIRST" },
            priority = 2,
        },
        {
            id = "semantic.self_state.thirst_alt",
            templateID = "semantic.self_state.thirst_alt",
            fallback = "That's rough. Let's look for something to drink.",
            when = { subject = "THIRST" },
            priority = 2,
        },
        {
            id = "semantic.self_state.fatigue",
            templateID = "semantic.self_state.fatigue",
            fallback = "I hear you. I hope you get a chance to rest soon.",
            when = { subject = "FATIGUE" },
            priority = 2,
        },
        {
            id = "semantic.self_state.fatigue_alt",
            templateID = "semantic.self_state.fatigue_alt",
            fallback = "This is wearing. Take a breather when you can.",
            when = { subject = "FATIGUE" },
            priority = 2,
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

Catalog.Register("semantic.compliment", {
    variants = {
        {
            id = "semantic.compliment.default",
            templateID = "semantic.social.compliment.default",
            fallback = "Thanks. That's kind of you.",
        },
        {
            id = "semantic.compliment.alternate",
            templateID = "semantic.social.compliment.alternate",
            fallback = "I appreciate you saying that.",
        },
        {
            id = "semantic.compliment.friendly",
            templateID = "semantic.social.compliment.friendly",
            fallback = "Thanks. You seem pretty great yourself.",
            when = { socialStyle = { "friendly", "protective" } },
            priority = 3,
        },
        {
            id = "semantic.compliment.trusted",
            templateID = "semantic.social.compliment.trusted",
            fallback = "Thanks. Hearing that from you means a lot.",
            when = { relationshipState = { "Member", "Lover" } },
            priority = 2,
        },
        {
            id = "semantic.compliment.withdrawn",
            templateID = "semantic.social.compliment.withdrawn",
            fallback = "Oh. Thank you, that's kind of you.",
            when = { socialStyle = "withdrawn" },
            priority = 2,
        },
    },
})

Catalog.Register("semantic.question.relationship_status.committed", {
    variants = {
        {
            id = "semantic.question.relationship_status.committed",
            templateID = "semantic.question.relationship_status.committed",
            fallback = "I thought we were already together.",
        },
    },
})

Catalog.Register("semantic.question.relationship_status.unknown", {
    variants = {
        {
            id = "semantic.question.relationship_status.uncertain",
            templateID = "semantic.question.relationship_status.uncertain",
            fallback = "I haven't really thought about dating. Right now, I'm focused on surviving.",
        },
        {
            id = "semantic.question.relationship_status.uncertain_alt",
            templateID = "semantic.question.relationship_status.uncertain_alt",
            fallback = "Honestly, I haven't had much room to think about relationships lately.",
        },
        {
            id = "semantic.question.relationship_status.withdrawn",
            templateID = "semantic.question.relationship_status.withdrawn",
            fallback = "I'd rather not get into that. There's too much going on right now.",
            when = { socialStyle = "withdrawn" },
            priority = 2,
        },
    },
})

Catalog.Register(
    "semantic.question.relationship_status.committed_after_compliment",
    {
        variants = {
            {
                id = "semantic.question.relationship_status.after_compliment.committed",
                templateID = "semantic.question.relationship_status.after_compliment.committed",
                fallback = "Thanks for the compliment, but I thought we were already together.",
            },
        },
    }
)

Catalog.Register(
    "semantic.question.relationship_status.unknown_after_compliment",
    {
        variants = {
            {
                id = "semantic.question.relationship_status.after_compliment.unknown",
                templateID = "semantic.question.relationship_status.after_compliment.unknown",
                fallback = "That's kind of you to ask. I don't have a clear answer right now.",
            },
            {
                id = "semantic.question.relationship_status.after_compliment.unknown_alt",
                templateID = "semantic.question.relationship_status.after_compliment.unknown_alt",
                fallback = "Thanks for saying that. I can't give you a clear answer about relationships right now.",
            },
            {
                id = "semantic.question.relationship_status.after_compliment.withdrawn",
                templateID = "semantic.question.relationship_status.after_compliment.withdrawn",
                fallback = "Thanks, but I'd rather keep that personal.",
                when = { socialStyle = "withdrawn" },
                priority = 2,
            },
        },
    }
)

Catalog.Register(
    "semantic.question.relationship_status.acknowledged",
    {
        variants = {
            {
                id = "semantic.question.relationship_status.acknowledged.default",
                templateID = "semantic.question.relationship_status.acknowledged.default",
                fallback = "Thanks for understanding. It's hard to think about relationships with everything going on.",
            },
            {
                id = "semantic.question.relationship_status.acknowledged.alternate",
                templateID = "semantic.question.relationship_status.acknowledged.alternate",
                fallback = "I appreciate you listening. It's hard to make plans while we're trying to survive.",
            },
            {
                id = "semantic.question.relationship_status.acknowledged.withdrawn",
                templateID = "semantic.question.relationship_status.acknowledged.withdrawn",
                fallback = "Thanks. I'd rather leave it there for now.",
                when = { socialStyle = "withdrawn" },
                priority = 2,
            },
        },
    }
)

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

Catalog.Register("semantic.self_reflection", {
    variants = {
        {
            id = "semantic.self_reflection.friendly",
            templateID = "semantic.social.self_reflection.friendly",
            fallback = "Hey. Don't talk about yourself like that. You matter.",
            when = { socialStyle = { "friendly", "protective" } },
            priority = 4,
        },
        {
            id = "semantic.self_reflection.trusted",
            templateID = "semantic.social.self_reflection.trusted",
            fallback = "You're harder on yourself than you need to be.",
            -- Conversation authority currently projects Member/Lover as the
            -- established relationship categories. Keep the older labels as
            -- compatibility aliases for other context providers.
            when = {
                relationshipState = {
                    "Friend", "Trusted", "Ally", "Member", "Lover",
                },
            },
            priority = 3,
        },
        {
            id = "semantic.self_reflection.withdrawn",
            templateID = "semantic.social.self_reflection.withdrawn",
            fallback = "Don't make a habit of saying things like that.",
            when = { socialStyle = "withdrawn" },
            priority = 2,
        },
        {
            id = "semantic.self_reflection.stressed",
            templateID = "semantic.social.self_reflection.stressed",
            fallback = "We've all made mistakes. Focus on what comes next.",
            when = { emotionType = { "stress", "panic" } },
            priority = 1,
        },
        {
            id = "semantic.self_reflection.default",
            templateID = "semantic.social.self_reflection.default",
            fallback = "Don't talk about yourself like that.",
        },
    },
})

Catalog.Register("semantic.identity.evasion", {
    variants = {
        {
            id = "semantic.identity.evasion.untrustworthy",
            templateID = "semantic.identity.evasion.untrustworthy",
            fallback = "You avoided my question. I can't trust you with my name.",
            when = { identityTrust = "untrustworthy" },
            priority = 5,
        },
        {
            id = "semantic.identity.evasion.friendly",
            templateID = "semantic.identity.evasion.friendly",
            fallback = "I asked you your name. Changing the subject makes me question your honesty.",
            when = { socialStyle = { "friendly", "protective" } },
            priority = 3,
        },
        {
            id = "semantic.identity.evasion.withdrawn",
            templateID = "semantic.identity.evasion.withdrawn",
            fallback = "Forget it. Keep your name to yourself; I don't trust evasive people.",
            when = { socialStyle = "withdrawn" },
            priority = 2,
        },
        {
            id = "semantic.identity.evasion.default",
            templateID = "semantic.identity.evasion.default",
            fallback = "You avoided my question. That makes you seem untrustworthy.",
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

local generatedPools = GeneratedDialogue and GeneratedDialogue.responsePools
if type(generatedPools) ~= "table" then
    error("generated dialogue dataset requires responsePools")
end
local generatedIndex
local generatedPool
local extended
local reason
for generatedIndex = 1, #generatedPools do
    generatedPool = generatedPools[generatedIndex]
    if type(generatedPool) ~= "table" then
        error("generated dialogue dataset contains an invalid response pool")
    end
    extended, reason = Catalog.Extend(generatedPool.id, generatedPool)
    if extended ~= true then
        error("generated dialogue responses could not extend "
            .. tostring(generatedPool.id) .. " (" .. tostring(reason) .. ")")
    end
end

return Catalog
