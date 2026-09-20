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

local SELF_STATE_PREFIXES = {
    { id = "im", tokens = { "i'm" } },
    { id = "i_am", tokens = { "i", "am" } },
    { id = "im_plain", tokens = { "im" } },
}

local SELF_WELLBEING_STATUSES = {
    { id = "fine", phrase = "fine", value = "fine", thankYou = true },
    { id = "okay", phrase = "okay", value = "okay", thankYou = true },
    { id = "ok", phrase = "ok", value = "okay", thankYou = true },
    { id = "alright", phrase = "alright", value = "alright" },
    { id = "all_right", phrase = "all right", value = "all right" },
    { id = "good", phrase = "good", value = "good" },
}

local function selfStateSocialContext()
    return {
        directed = false,
        selfDirected = true,
        target = "SELF",
    }
end

local function registerSelfNeedPatterns(subject)
    local prefixIndex
    local tokenIndex
    local prefix
    local match
    local patternID
    for prefixIndex = 1, #SELF_STATE_PREFIXES do
        prefix = SELF_STATE_PREFIXES[prefixIndex]
        match = {}
        for tokenIndex = 1, #prefix.tokens do
            match[#match + 1] = {
                kind = "literal",
                value = prefix.tokens[tokenIndex],
            }
        end
        match[#match + 1] = {
            kind = "concept",
            id = subject,
            capture = "state",
        }
        patternID = "pnc.state.self_" .. string.lower(subject)
            .. "_" .. prefix.id
        registerPattern(patternID, match, {
            intent = "INFORM",
            speechAct = "INFORM",
            subject = subject,
            slots = {
                state = {
                    type = subject,
                    value = "$capture.state.text",
                },
            },
            socialContext = selfStateSocialContext(),
        }, 0.99, 180)
    end
end

local function registerSelfWellbeingPattern(prefix, status, thankYou)
    local match = {}
    local tokenIndex
    for tokenIndex = 1, #prefix.tokens do
        match[#match + 1] = {
            kind = "literal",
            value = prefix.tokens[tokenIndex],
        }
    end
    match[#match + 1] = {
        kind = "literal",
        value = status.phrase,
    }
    if thankYou then
        -- "thank you" is an existing semantic concept phrase. Matching its
        -- exact text keeps the whole response anchored without stealing a
        -- standalone THANK utterance.
        match[#match + 1] = {
            kind = "literal",
            value = "thank you",
        }
    end
    registerPattern(
        "pnc.state.self_wellbeing_" .. prefix.id .. "_" .. status.id
            .. (thankYou and "_thank_you" or ""),
        match,
        {
            intent = "INFORM",
            speechAct = "INFORM",
            subject = "WELLBEING",
            slots = {
                state = {
                    type = "WELLBEING",
                    value = status.value,
                },
            },
            socialContext = selfStateSocialContext(),
        },
        0.99,
        190
    )
end

function Internal.RegisterSelfStatePatterns()
    -- Keep first-person claims ahead of the open-ended name capture. Exact
    -- prefix/state patterns consume the whole utterance, so clauses such as
    -- "I'm fine with that" cannot become wellbeing reports.
    registerSelfNeedPatterns("HUNGER")
    registerSelfNeedPatterns("THIRST")
    registerSelfNeedPatterns("FATIGUE")

    local prefixIndex
    local statusIndex
    local prefix
    local status
    for prefixIndex = 1, #SELF_STATE_PREFIXES do
        prefix = SELF_STATE_PREFIXES[prefixIndex]
        for statusIndex = 1, #SELF_WELLBEING_STATUSES do
            status = SELF_WELLBEING_STATUSES[statusIndex]
            registerSelfWellbeingPattern(prefix, status, false)
            if status.thankYou == true then
                registerSelfWellbeingPattern(prefix, status, true)
            end
        end
    end
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
        "pnc.social.greet",
        { "@GREET" },
        { intent = "GREET", speechAct = "GREET" },
        0.97,
        75
    )
end

return Internal
