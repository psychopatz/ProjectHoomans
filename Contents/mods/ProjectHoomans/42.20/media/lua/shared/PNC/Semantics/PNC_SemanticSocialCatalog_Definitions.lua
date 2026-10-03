local Semantic = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local Registry = Semantic.Registry
local Social = PNC.Semantics.SocialCatalog or {}
PNC.Semantics.SocialCatalog = Social

Social.VERSION = 2
Social.OWNER = "ProjectHoomans"

local function registerConcept(id, aliases, priority)
    return Registry.RegisterConcept({
        id = id,
        aliases = aliases,
        priority = priority or 0,
        owner = Social.OWNER,
        metadata = {
            domain = "social",
        },
    })
end

local function registerPattern(id, match, emit, confidence, priority, options)
    local definition = {
        id = id,
        match = match,
        emit = emit,
        confidence = confidence,
        priority = priority or 0,
        owner = Social.OWNER,
    }
    for key, value in pairs(type(options) == "table" and options or {}) do
        definition[key] = value
    end
    return Registry.RegisterPattern(definition)
end

local function registerSpeechAct(id)
    return Registry.RegisterSpeechAct({
        id = id,
        owner = Social.OWNER,
        metadata = {
            domain = "social",
        },
    })
end

local function directedSocialEmit(speechAct, intensity)
    return {
        intent = speechAct,
        speechAct = speechAct,
        subject = "RECIPIENT",
        modifiers = {
            directed = true,
        },
        emotionalState = {
            valence = "negative",
            intensity = intensity,
        },
        socialContext = {
            directed = true,
            hostility = intensity,
        },
    }
end

local function registerDirectedPattern(
    id,
    match,
    speechAct,
    intensity,
    confidence,
    priority
)
    local matchWithTrailingWords = {}
    for index = 1, #match do
        matchWithTrailingWords[index] = match[index]
    end
    matchWithTrailingWords[#matchWithTrailingWords + 1] = {
        kind = "any_phrase",
        minTokens = 1,
        maxTokens = 8,
        allowVerbForms = true,
        optional = true,
    }
    return registerPattern(
        id,
        matchWithTrailingWords,
        directedSocialEmit(speechAct, intensity),
        confidence,
        priority
    )
end

local function selfReflectionEmit(reflectionType)
    return {
        intent = "SELF_REFLECTION",
        speechAct = "SELF_REFLECTION",
        subject = "SELF",
        modifiers = {
            directed = false,
            selfDirected = true,
        },
        emotionalState = {
            valence = "negative",
            intensity = "moderate",
        },
        socialContext = {
            directed = false,
            selfDirected = true,
            target = "SELF",
            reflectionType = reflectionType,
        },
    }
end

local function complimentEmit()
    return {
        intent = "COMPLIMENT",
        speechAct = "COMPLIMENT",
        subject = "RECIPIENT",
        modifiers = {
            directed = true,
        },
        emotionalState = {
            valence = "positive",
            intensity = "mild",
        },
        socialContext = {
            directed = true,
            affiliative = true,
        },
    }
end

local function relationshipStatusQuestionEmit()
    return {
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "RELATIONSHIP_STATUS",
        modifiers = {
            directed = true,
        },
        socialContext = {
            directed = true,
            personalQuestion = true,
        },
    }
end

local COMPLIMENT_INTENSIFIERS = { "really", "so", "very" }

local COMPLIMENT_PREFIXES = {
    { id = "you_look", words = { "you", "look" } },
    { id = "you_are", words = { "you", "are" } },
    { id = "youre", words = { "you're" } },
    { id = "you_seem", words = { "you", "seem" } },
    { id = "i_think_you_look", words = { "i", "think", "you", "look" } },
    { id = "i_think_you_are", words = { "i", "think", "you", "are" } },
    { id = "i_think_youre", words = { "i", "think", "you're" } },
}

local RELATIONSHIP_STATUS_QUESTIONS = {
    { id = "single", words = { "are", "you", "single" } },
    { id = "still_single", words = { "are", "you", "still", "single" } },
    { id = "single_right_now", words = {
        "are", "you", "single", "right", "now",
    } },
    { id = "taken", words = { "are", "you", "taken" } },
    { id = "seeing_anyone", words = {
        "are", "you", "seeing", "anyone",
    } },
    { id = "seeing_anybody", words = {
        "are", "you", "seeing", "anybody",
    } },
    { id = "seeing_someone", words = {
        "are", "you", "seeing", "someone",
    } },
    { id = "dating_anyone", words = { "are", "you", "dating", "anyone" } },
    { id = "dating_someone", words = {
        "are", "you", "dating", "someone",
    } },
    { id = "with_someone", words = { "are", "you", "with", "someone" } },
    { id = "already_with_someone", words = {
        "are", "you", "already", "with", "someone",
    } },
    { id = "relationship", words = {
        "are", "you", "in", "a", "relationship",
    } },
    { id = "relationship_now", words = {
        "are", "you", "in", "a", "relationship", "right", "now",
    } },
    { id = "married", words = { "are", "you", "married" } },
    { id = "have_partner", words = {
        "do", "you", "have", "a", "partner",
    } },
    { id = "have_boyfriend", words = {
        "do", "you", "have", "a", "boyfriend",
    } },
    { id = "have_girlfriend", words = {
        "do", "you", "have", "a", "girlfriend",
    } },
    { id = "have_spouse", words = {
        "do", "you", "have", "a", "spouse",
    } },
    { id = "have_someone", words = {
        "do", "you", "have", "someone",
    } },
    { id = "wondering_are_single", words = {
        "i", "was", "wondering", "if", "you", "are", "single",
    } },
    { id = "wondering_youre_single", words = {
        "i", "was", "wondering", "if", "you're", "single",
    } },
    { id = "ask_are_single", words = {
        "can", "i", "ask", "if", "you", "are", "single",
    } },
    { id = "ask_youre_single", words = {
        "can", "i", "ask", "if", "you're", "single",
    } },
    { id = "someone_in_your_life", words = {
        "is", "there", "someone", "in", "your", "life",
    } },
}

local function literalPattern(words)
    local match = {}
    local index
    for index = 1, #words do
        match[index] = { kind = "literal", value = words[index] }
    end
    return match
end

local function complimentPattern(prefix, intensifier)
    local match = literalPattern(prefix)
    if intensifier then
        match[#match + 1] = { kind = "literal", value = intensifier }
    end
    match[#match + 1] = { kind = "concept", id = "COMPLIMENT_ADJECTIVE" }
    return match
end

local function registerComplimentPrefix(prefix, priority)
    local baseID = "pnc.social.compliment_" .. prefix.id
    registerPattern(
        baseID,
        complimentPattern(prefix.words),
        complimentEmit(),
        0.98,
        priority
    )
    local index
    local intensifier
    for index = 1, #COMPLIMENT_INTENSIFIERS do
        intensifier = COMPLIMENT_INTENSIFIERS[index]
        registerPattern(
            baseID .. "_" .. intensifier,
            complimentPattern(prefix.words, intensifier),
            complimentEmit(),
            0.98,
            priority - 1
        )
    end
end

local function registerFeatureCompliment(prefix, priority)
    local baseID = "pnc.social.compliment_" .. prefix.id
    local match = literalPattern(prefix.words)
    match[#match + 1] = { kind = "concept", id = "COMPLIMENT_ADJECTIVE" }
    match[#match + 1] = { kind = "concept", id = "COMPLIMENT_FEATURE" }
    registerPattern(baseID, match, complimentEmit(), 0.97, priority)

    local index
    local intensifier
    for index = 1, #COMPLIMENT_INTENSIFIERS do
        intensifier = COMPLIMENT_INTENSIFIERS[index]
        match = literalPattern(prefix.words)
        match[#match + 1] = { kind = "literal", value = intensifier }
        match[#match + 1] = {
            kind = "concept", id = "COMPLIMENT_ADJECTIVE",
        }
        match[#match + 1] = { kind = "concept", id = "COMPLIMENT_FEATURE" }
        registerPattern(
            baseID .. "_" .. intensifier,
            match,
            complimentEmit(),
            0.97,
            priority - 1
        )
    end
end

local function registerFeatureOnlyCompliment(prefix, priority)
    local match = literalPattern(prefix.words)
    match[#match + 1] = { kind = "concept", id = "COMPLIMENT_FEATURE" }
    registerPattern(
        "pnc.social.compliment_" .. prefix.id,
        match,
        complimentEmit(),
        0.97,
        priority
    )
end


local Internal = Social.Internal or {}
Social.Internal = Internal
Internal.Registry = Registry
Internal.RegisterConcept = registerConcept
Internal.RegisterPattern = registerPattern
Internal.RegisterSpeechAct = registerSpeechAct
Internal.DirectedSocialEmit = directedSocialEmit
Internal.RegisterDirectedPattern = registerDirectedPattern
Internal.SelfReflectionEmit = selfReflectionEmit
Internal.ComplimentEmit = complimentEmit
Internal.RelationshipStatusQuestionEmit = relationshipStatusQuestionEmit
Internal.LiteralPattern = literalPattern
Internal.RegisterComplimentPrefix = registerComplimentPrefix
Internal.RegisterFeatureCompliment = registerFeatureCompliment
Internal.RegisterFeatureOnlyCompliment = registerFeatureOnlyCompliment
Internal.ComplimentIntensifiers = COMPLIMENT_INTENSIFIERS
Internal.ComplimentPrefixes = COMPLIMENT_PREFIXES
Internal.RelationshipStatusQuestions = RELATIONSHIP_STATUS_QUESTIONS
