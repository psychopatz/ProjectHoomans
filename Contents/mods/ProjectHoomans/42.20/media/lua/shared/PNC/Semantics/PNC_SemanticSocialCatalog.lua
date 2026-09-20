-- Data-only social language definitions for the Project Hoomans semantic
-- layer.  Recognition produces Semantic IR; it never changes relationships,
-- combat state, or any other gameplay state.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Semantic = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local Registry = Semantic.Registry
local Social = PNC.Semantics.SocialCatalog or {}
PNC.Semantics.SocialCatalog = Social

Social.VERSION = 1
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

local function registerPattern(id, match, emit, confidence, priority)
    return Registry.RegisterPattern({
        id = id,
        match = match,
        emit = emit,
        confidence = confidence,
        priority = priority or 0,
        owner = Social.OWNER,
    })
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

    -- These are deliberately short, game-domain phrases.  This is not a
    -- general profanity detector; adding or removing vocabulary is a data
    -- change and does not require parser changes.
    registerConcept("INSULT", {
        "fuck you", "fuck u", "f u", "f*ck you", "f**k you", "f*** you",
        "fuck-you", "screw you", "screw u", "you suck", "you are useless",
        "you're useless", "you idiot", "idiot", "you jerk", "jerk",
        "asshole", "bastard",
    }, 3)
    registerConcept("HOSTILE_REMARK", {
        "shut up", "shut the fuck up", "fuck off", "get lost", "back off",
        "leave me alone", "don't come closer", "go away",
    }, 2)
    registerConcept("PROFANITY", {
        "fuck", "f*ck", "f**k", "f***", "shit", "damn", "hell",
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
    registerPattern(
        "pnc.social.insult_you_are",
        {
            { kind = "literal", value = "you" },
            { kind = "literal", value = "are" },
            { kind = "literal", value = "an", optional = true },
            { kind = "concept", id = "INSULT" },
        },
        directedSocialEmit("INSULT", "high"),
        0.98,
        140
    )
    registerPattern(
        "pnc.social.insult_youre",
        {
            { kind = "literal", value = "you're" },
            { kind = "literal", value = "an", optional = true },
            { kind = "concept", id = "INSULT" },
        },
        directedSocialEmit("INSULT", "high"),
        0.98,
        140
    )

    registerPattern(
        "pnc.social.insult",
        { "@INSULT" },
        directedSocialEmit("INSULT", "high"),
        0.96,
        100
    )
    registerPattern(
        "pnc.social.insult_prefixed",
        {
            { kind = "literal", value = "hey", optional = true },
            { kind = "concept", id = "INSULT" },
        },
        directedSocialEmit("INSULT", "high"),
        0.90,
        90
    )
    registerPattern(
        "pnc.social.hostile_remark",
        { "@HOSTILE_REMARK" },
        directedSocialEmit("HOSTILE_REMARK", "high"),
        0.96,
        100
    )
    registerPattern(
        "pnc.social.hostile_remark_prefixed",
        {
            { kind = "literal", value = "hey", optional = true },
            { kind = "concept", id = "HOSTILE_REMARK" },
        },
        directedSocialEmit("HOSTILE_REMARK", "high"),
        0.90,
        90
    )
    registerPattern(
        "pnc.social.profanity",
        { "@PROFANITY" },
        directedSocialEmit("HOSTILE_REMARK", "moderate"),
        0.92,
        80
    )
    registerPattern(
        "pnc.social.profanity_prefixed",
        {
            { kind = "literal", value = "hey", optional = true },
            { kind = "concept", id = "PROFANITY" },
        },
        directedSocialEmit("HOSTILE_REMARK", "moderate"),
        0.86,
        70
    )
    registerPattern(
        "pnc.social.threaten",
        { "@THREATEN" },
        directedSocialEmit("THREATEN", "critical"),
        0.97,
        120
    )

    Social.registered = true
    Social.registryRevision = Registry.GetRevision()
    return true, Social.registryRevision
end

Social.Register()

return Social
