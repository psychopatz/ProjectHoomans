-- Data-only social language definitions for the Project Hoomans semantic
-- layer.  Recognition produces Semantic IR; it never changes relationships,
-- combat state, or any other gameplay state.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

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

function Social.Register()
    registerSpeechAct("INSULT")
    registerSpeechAct("HOSTILE_REMARK")
    registerSpeechAct("SELF_REFLECTION")
    registerSpeechAct("COMPLIMENT")

    -- Keep hostile vocabulary in the catalog. Explicit hostile phrases may
    -- carry up to eight trailing words such as "then" without requiring each
    -- complete sentence to be listed as a separate alias.
    registerConcept("INSULT", {
        "fuck you", "fuck u", "f u", "f*ck you", "f**k you", "f*** you",
        "f***k you", "fuck-you", "screw you", "screw u", "you suck",
        "you are useless", "you're useless", "you idiot", "idiot",
        "you jerk", "jerk", "asshole", "you asshole", "you're an asshole",
        "you are an asshole", "bastard", "you bastard", "bitch",
        "you bitch", "moron", "you moron", "stupid", "you are stupid",
        "you're stupid", "dumb", "you are dumb", "you're dumb", "pathetic",
        "you are pathetic", "you're pathetic", "worthless", "you are worthless",
        "you're worthless", "loser", "you are a loser", "you're a loser",
        "dumbass", "jackass", "dickhead", "asshat", "dipshit", "prick",
        "twat", "wanker", "cunt", "douchebag", "fuckface", "fucker",
        "motherfucker", "piece of shit", "you piece of shit", "son of a bitch",
        "you son of a bitch", "fucking idiot", "you fucking idiot",
        "fucking moron", "you fucking moron", "fucking asshole",
        "you fucking asshole",
    }, 3)
    registerConcept("HOSTILE_REMARK", {
        "shut up", "shut the fuck up", "fuck off", "get lost", "back off",
        "leave me alone", "don't come closer", "go away",
        "go to hell", "piss off", "screw off", "go fuck yourself",
        "get the fuck out", "leave me the fuck alone", "shut your mouth",
        "shut your fucking mouth", "stop talking to me", "i hate you",
        "i hate your guts", "get away from me",
    }, 2)
    registerConcept("PROFANITY", {
        "fuck", "f*ck", "f**k", "f***", "f***k", "f*****", "fuckin",
        "fucking", "fucked", "shit", "sh*t", "s**t", "shitty", "bullshit",
        "bullsh*t", "horseshit", "damn", "dammit", "goddamn", "hell",
        "crap", "ass", "arse", "piss", "pissed", "pissing", "cock",
    }, 1)
    registerConcept("THREATEN", {
        "i will kill you", "i'll kill you", "i am going to kill you",
        "i'm going to kill you", "you are going to die", "you're going to die",
    }, 4)
    registerConcept("SELF_BLAME", {
        "my fault", "it was my fault", "i messed up", "i screwed up",
        "i made a mistake", "i'm to blame", "i am to blame",
    }, 4)
    registerConcept("COMPLIMENT_ADJECTIVE", {
        "amazing", "beautiful", "cute", "gorgeous", "great", "handsome",
        "kind", "lovely", "nice", "pretty", "sweet", "wonderful",
    }, 3)
    registerConcept("COMPLIMENT_FEATURE", {
        "eyes", "hair", "outfit", "smile", "voice",
    }, 2)

    local index
    local prefix
    for index = 1, #COMPLIMENT_PREFIXES do
        prefix = COMPLIMENT_PREFIXES[index]
        registerComplimentPrefix(prefix, 118)
    end
    registerFeatureCompliment({
        id = "you_have_feature",
        words = { "you", "have" },
    }, 116)
    registerFeatureCompliment({
        id = "i_like_your_adjective_feature",
        words = { "i", "like", "your" },
    }, 116)
    registerFeatureOnlyCompliment({
        id = "i_like_your_feature",
        words = { "i", "like", "your" },
    }, 116)
    registerFeatureOnlyCompliment({
        id = "i_really_like_your_feature",
        words = { "i", "really", "like", "your" },
    }, 116)

    local question
    for index = 1, #RELATIONSHIP_STATUS_QUESTIONS do
        question = RELATIONSHIP_STATUS_QUESTIONS[index]
        registerPattern(
            "pnc.social.relationship_status_" .. question.id,
            literalPattern(question.words),
            relationshipStatusQuestionEmit(),
            0.99,
            150
        )
    end

    registerPattern(
        "pnc.social.self_mockery_im",
        {
            { kind = "literal", value = "i'm" },
            { kind = "literal", value = "an", optional = true },
            { kind = "concept", id = "INSULT" },
        },
        selfReflectionEmit("SELF_MOCKERY"),
        0.98,
        145
    )
    registerPattern(
        "pnc.social.self_mockery_i_am",
        {
            { kind = "literal", value = "i" },
            { kind = "literal", value = "am" },
            { kind = "literal", value = "an", optional = true },
            { kind = "concept", id = "INSULT" },
        },
        selfReflectionEmit("SELF_MOCKERY"),
        0.98,
        145
    )
    registerPattern(
        "pnc.social.self_mockery_im_plain",
        {
            { kind = "literal", value = "im" },
            { kind = "literal", value = "an", optional = true },
            { kind = "concept", id = "INSULT" },
        },
        selfReflectionEmit("SELF_MOCKERY"),
        0.98,
        145
    )
    registerPattern(
        "pnc.social.self_blame",
        { "@SELF_BLAME" },
        selfReflectionEmit("SELF_BLAME"),
        0.97,
        145
    )
    registerDirectedPattern(
        "pnc.social.insult_you_are",
        {
            { kind = "literal", value = "you" },
            { kind = "literal", value = "are" },
            { kind = "literal", value = "a", optional = true },
            { kind = "literal", value = "an", optional = true },
            { kind = "concept", id = "INSULT" },
        },
        "INSULT",
        "high",
        0.98,
        140
    )
    registerDirectedPattern(
        "pnc.social.insult_youre",
        {
            { kind = "literal", value = "you're" },
            { kind = "literal", value = "a", optional = true },
            { kind = "literal", value = "an", optional = true },
            { kind = "concept", id = "INSULT" },
        },
        "INSULT",
        "high",
        0.98,
        140
    )

    registerDirectedPattern(
        "pnc.social.insult_you",
        {
            { kind = "literal", value = "you" },
            { kind = "concept", id = "INSULT" },
        },
        "INSULT",
        "high",
        0.97,
        139
    )
    registerDirectedPattern(
        "pnc.social.insult",
        { "@INSULT" },
        "INSULT",
        "high",
        0.96,
        100
    )
    registerDirectedPattern(
        "pnc.social.insult_prefixed",
        {
            { kind = "literal", value = "hey", optional = true },
            { kind = "concept", id = "INSULT" },
        },
        "INSULT",
        "high",
        0.90,
        90
    )
    registerDirectedPattern(
        "pnc.social.hostile_remark",
        { "@HOSTILE_REMARK" },
        "HOSTILE_REMARK",
        "high",
        0.96,
        100
    )
    registerDirectedPattern(
        "pnc.social.hostile_remark_prefixed",
        {
            { kind = "literal", value = "hey", optional = true },
            { kind = "concept", id = "HOSTILE_REMARK" },
        },
        "HOSTILE_REMARK",
        "high",
        0.90,
        90
    )
    registerDirectedPattern(
        "pnc.social.profanity",
        { "@PROFANITY" },
        "HOSTILE_REMARK",
        "moderate",
        0.92,
        80
    )
    registerDirectedPattern(
        "pnc.social.profanity_prefixed",
        {
            { kind = "literal", value = "hey", optional = true },
            { kind = "concept", id = "PROFANITY" },
        },
        "HOSTILE_REMARK",
        "moderate",
        0.94,
        70
    )
    registerDirectedPattern(
        "pnc.social.profanity_you",
        {
            { kind = "literal", value = "you" },
            { kind = "literal", value = "are", optional = true },
            { kind = "literal", value = "a", optional = true },
            { kind = "literal", value = "an", optional = true },
            { kind = "concept", id = "PROFANITY" },
        },
        "HOSTILE_REMARK",
        "moderate",
        0.94,
        85
    )
    registerDirectedPattern(
        "pnc.social.threaten",
        { "@THREATEN" },
        "THREATEN",
        "critical",
        0.97,
        120
    )

    Social.registered = true
    Social.registryRevision = Registry.GetRevision()
    return true, Social.registryRevision
end

Social.Register()

return Social
