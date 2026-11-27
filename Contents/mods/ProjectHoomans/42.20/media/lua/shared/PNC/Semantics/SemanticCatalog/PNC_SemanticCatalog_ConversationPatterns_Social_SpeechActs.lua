-- Social acknowledgement and speech-act pattern registration.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog social module requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog social module requires RegisterPattern")
end

function Internal.RegisterSocialSpeechActs()
    registerPattern(
        "pnc.social.thank",
        { "@THANK" },
        { intent = "THANK", speechAct = "THANK" },
        0.96,
        70
    )

    registerPattern(
        "pnc.social.apologize",
        { "@APOLOGIZE" },
        { intent = "APOLOGIZE", speechAct = "APOLOGIZE" },
        0.96,
        70
    )

    registerPattern(
        "pnc.social.accept",
        { "@ACCEPT" },
        { intent = "ACCEPT", speechAct = "ACCEPT" },
        0.94,
        70
    )

    registerPattern(
        "pnc.social.refuse",
        { "@REFUSE" },
        { intent = "REFUSE", speechAct = "REFUSE" },
        0.94,
        70
    )

    registerPattern(
        "pnc.social.agree",
        { "@AGREE" },
        { intent = "AGREE", speechAct = "AGREE" },
        0.94,
        71
    )

    registerPattern(
        "pnc.social.acknowledge",
        { "@ACKNOWLEDGE" },
        { intent = "ACKNOWLEDGE", speechAct = "ACKNOWLEDGE" },
        0.96,
        72
    )

    registerPattern(
        "pnc.social.disagree",
        { "@DISAGREE" },
        { intent = "DISAGREE", speechAct = "DISAGREE" },
        0.94,
        71
    )

    registerPattern(
        "pnc.social.skepticism",
        { "@SKEPTICISM" },
        {
            intent = "DISAGREE",
            speechAct = "DISAGREE",
            modifiers = { skeptical = true },
            socialContext = { skepticism = true },
        },
        0.91,
        73
    )

    registerPattern(
        "pnc.social.greet",
        { "@GREET" },
        { intent = "GREET", speechAct = "GREET" },
        0.97,
        75
    )

    -- Compositional social pleasantries: covers hundreds of natural greeting
    -- combinations ("so glad to see you", "it's really nice meeting you too")
    -- without flat phrase duplication.
    registerPattern(
        "pnc.social.greet.compositional_infinitive",
        {
            { kind = "literal", value = "it", optional = true },
            { kind = "literal", value = "is", optional = true },
            { kind = "concept", id = "INTENSIFIER", optional = true },
            { kind = "concept", id = "PLEASANTRY_ADJ" },
            { kind = "literal", value = "to" },
            { kind = "concept", id = "PLEASANTRY_VERB_YOU" },
            { kind = "concept", id = "RECIPROCAL_TAIL", optional = true },
        },
        { intent = "GREET", speechAct = "GREET" },
        0.97,
        78
    )

    registerPattern(
        "pnc.social.greet.compositional_compliment_infinitive",
        {
            { kind = "literal", value = "it", optional = true },
            { kind = "literal", value = "is", optional = true },
            { kind = "concept", id = "INTENSIFIER", optional = true },
            { kind = "concept", id = "COMPLIMENT_ADJECTIVE" },
            { kind = "literal", value = "to" },
            { kind = "concept", id = "PLEASANTRY_VERB_YOU" },
            { kind = "concept", id = "RECIPROCAL_TAIL", optional = true },
        },
        { intent = "GREET", speechAct = "GREET" },
        0.97,
        78
    )

    registerPattern(
        "pnc.social.greet.compositional_gerund",
        {
            { kind = "literal", value = "it", optional = true },
            { kind = "literal", value = "is", optional = true },
            { kind = "concept", id = "INTENSIFIER", optional = true },
            { kind = "concept", id = "PLEASANTRY_ADJ" },
            { kind = "concept", id = "PLEASANTRY_GERUND_YOU" },
            { kind = "concept", id = "RECIPROCAL_TAIL", optional = true },
        },
        { intent = "GREET", speechAct = "GREET" },
        0.96,
        78
    )

    registerPattern(
        "pnc.social.greet.compositional_compliment_gerund",
        {
            { kind = "literal", value = "it", optional = true },
            { kind = "literal", value = "is", optional = true },
            { kind = "concept", id = "INTENSIFIER", optional = true },
            { kind = "concept", id = "COMPLIMENT_ADJECTIVE" },
            { kind = "concept", id = "PLEASANTRY_GERUND_YOU" },
            { kind = "concept", id = "RECIPROCAL_TAIL", optional = true },
        },
        { intent = "GREET", speechAct = "GREET" },
        0.96,
        78
    )

    registerPattern(
        "pnc.social.thank.compositional_much",
        {
            { kind = "concept", id = "THANK" },
            { kind = "concept", id = "INTENSIFIER", optional = true },
            { kind = "literal", value = "much" },
        },
        { intent = "THANK", speechAct = "THANK" },
        0.96,
        76
    )

    registerPattern(
        "pnc.social.thank.compositional_amount",
        {
            { kind = "concept", id = "THANK" },
            { kind = "literal", value = "a" },
            { kind = "concept", id = "THANK_AMOUNT" },
        },
        { intent = "THANK", speechAct = "THANK" },
        0.96,
        76
    )

    registerPattern(
        "pnc.social.apologize.compositional",
        {
            { kind = "concept", id = "INTENSIFIER", optional = true },
            { kind = "concept", id = "APOLOGIZE" },
            { kind = "literal", value = "about", optional = true },
            { kind = "literal", value = "that", optional = true },
        },
        { intent = "APOLOGIZE", speechAct = "APOLOGIZE" },
        0.95,
        76
    )

    registerPattern(
        "pnc.social.farewell",
        { "@FAREWELL" },
        { intent = "FAREWELL", speechAct = "FAREWELL", topic = "farewell" },
        0.96,
        74
    )
end

return Internal
