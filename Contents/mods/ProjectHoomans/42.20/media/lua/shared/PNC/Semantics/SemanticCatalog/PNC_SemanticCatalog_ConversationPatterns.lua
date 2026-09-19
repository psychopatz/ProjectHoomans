-- Conversation-level state claims and non-item social utterances.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog module requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog pattern module requires RegisterPattern")
end

function Internal.RegisterSelfStatePatterns()
    -- Keep first-person state claims ahead of the open-ended name capture.
    -- This prevents "I'm starving" from being treated as a name claim while
    -- still allowing an unknown player name such as "Patrick" through the
    -- deterministic route.

    registerPattern(
        "pnc.state.self_hunger_im",
        {
            { kind = "literal", value = "i'm" },
            { kind = "concept", id = "HUNGER", capture = "state" },
        },
        {
            intent = "INFORM",
            speechAct = "INFORM",
            subject = "HUNGER",
            slots = {
                state = {
                    type = "HUNGER",
                    value = "$capture.state.text",
                },
            },
            socialContext = {
                directed = false,
                selfDirected = true,
                target = "SELF",
            },
        },
        0.99,
        180
    )

    registerPattern(
        "pnc.state.self_hunger_i_am",
        {
            { kind = "literal", value = "i" },
            { kind = "literal", value = "am" },
            { kind = "concept", id = "HUNGER", capture = "state" },
        },
        {
            intent = "INFORM",
            speechAct = "INFORM",
            subject = "HUNGER",
            slots = {
                state = {
                    type = "HUNGER",
                    value = "$capture.state.text",
                },
            },
            socialContext = {
                directed = false,
                selfDirected = true,
                target = "SELF",
            },
        },
        0.99,
        180
    )

    registerPattern(
        "pnc.state.self_hunger_im_plain",
        {
            { kind = "literal", value = "im" },
            { kind = "concept", id = "HUNGER", capture = "state" },
        },
        {
            intent = "INFORM",
            speechAct = "INFORM",
            subject = "HUNGER",
            slots = {
                state = {
                    type = "HUNGER",
                    value = "$capture.state.text",
                },
            },
            socialContext = {
                directed = false,
                selfDirected = true,
                target = "SELF",
            },
        },
        0.99,
        180
    )
end

function Internal.RegisterSocialSignals()
    registerPattern(
        "pnc.social.gossip_event",
        {
            { kind = "literal", value = "did" },
            { kind = "literal", value = "you" },
            { kind = "concept", id = "HEAR" },
            { kind = "literal", value = "that", optional = true },
            { kind = "any", capture = "target" },
            { kind = "concept", id = "BITTEN" },
        },
        {
            intent = "GOSSIP",
            speechAct = "GOSSIP",
            subject = "GOSSIP",
            target = "$capture.target",
            slots = {
                information = {
                    event = "BITTEN",
                    subject = "$capture.target",
                },
            },
        },
        0.88,
        90
    )

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
        "pnc.social.greet",
        { "@GREET" },
        { intent = "GREET", speechAct = "GREET" },
        0.97,
        75
    )
end

return Internal
