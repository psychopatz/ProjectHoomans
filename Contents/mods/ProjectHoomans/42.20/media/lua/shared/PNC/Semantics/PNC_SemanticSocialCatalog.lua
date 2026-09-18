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

function Social.Register()
    registerSpeechAct("INSULT")
    registerSpeechAct("HOSTILE_REMARK")
    registerSpeechAct("SELF_REFLECTION")

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
