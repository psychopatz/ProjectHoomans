local Social = PNC.Semantics.SocialCatalog
local Internal = Social.Internal
local Registry = Internal.Registry
local registerSpeechAct = Internal.RegisterSpeechAct
local registerConcept = Internal.RegisterConcept
local registerPattern = Internal.RegisterPattern
local registerDirectedPattern = Internal.RegisterDirectedPattern
local selfReflectionEmit = Internal.SelfReflectionEmit
local complimentEmit = Internal.ComplimentEmit
local relationshipStatusQuestionEmit = Internal.RelationshipStatusQuestionEmit
local literalPattern = Internal.LiteralPattern
local registerComplimentPrefix = Internal.RegisterComplimentPrefix
local registerFeatureCompliment = Internal.RegisterFeatureCompliment
local registerFeatureOnlyCompliment = Internal.RegisterFeatureOnlyCompliment
local COMPLIMENT_PREFIXES = Internal.ComplimentPrefixes
local RELATIONSHIP_STATUS_QUESTIONS = Internal.RelationshipStatusQuestions

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
            { kind = "literal", value = "hey" },
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
