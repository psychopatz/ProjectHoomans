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

local function registerNewsQuestions()
    local patterns = {
        {
            id = "pnc.social.news_you_got",
            match = {
                { kind = "literal", value = "you" },
                { kind = "literal", value = "still", optional = true },
                { kind = "literal", value = "got" },
                { kind = "literal", value = "any", optional = true },
                { kind = "concept", id = "NEWS" },
            },
        },
        {
            -- Some input sources drop the final "s" in this exact phrasing.
            -- Keep that shorthand local instead of making "new" a global alias.
            id = "pnc.social.news_you_got_short",
            match = {
                { kind = "literal", value = "you" },
                { kind = "literal", value = "still", optional = true },
                { kind = "literal", value = "got" },
                { kind = "literal", value = "any", optional = true },
                { kind = "literal", value = "new" },
            },
        },
        {
            id = "pnc.social.news_have_you_got",
            match = {
                { kind = "literal", value = "have" },
                { kind = "literal", value = "you" },
                { kind = "literal", value = "still", optional = true },
                { kind = "literal", value = "got" },
                { kind = "literal", value = "any", optional = true },
                { kind = "concept", id = "NEWS" },
            },
        },
        {
            id = "pnc.social.news_do_you_have",
            match = {
                { kind = "literal", value = "do" },
                { kind = "literal", value = "you" },
                { kind = "literal", value = "still", optional = true },
                { kind = "concept", id = "HAVE" },
                { kind = "literal", value = "any", optional = true },
                { kind = "concept", id = "NEWS" },
            },
        },
        {
            id = "pnc.social.news_any",
            match = {
                { kind = "literal", value = "any" },
                { kind = "concept", id = "NEWS" },
            },
        },
        {
            id = "pnc.social.news_tell_me",
            match = {
                { kind = "literal", value = "tell" },
                { kind = "literal", value = "me" },
                { kind = "literal", value = "some", optional = true },
                { kind = "literal", value = "any", optional = true },
                { kind = "concept", id = "NEWS" },
            },
        },
        {
            id = "pnc.social.news_what_is",
            match = {
                { kind = "literal", value = "what" },
                { kind = "literal", value = "is" },
                { kind = "literal", value = "the", optional = true },
                { kind = "concept", id = "NEWS" },
            },
        },
        {
            id = "pnc.social.news_whats_the",
            match = {
                { kind = "literal", value = "what's" },
                { kind = "literal", value = "the", optional = true },
                { kind = "concept", id = "NEWS" },
            },
        },
        {
            id = "pnc.social.news_have_you_heard",
            match = {
                { kind = "literal", value = "have" },
                { kind = "literal", value = "you" },
                { kind = "concept", id = "HEAR" },
                { kind = "literal", value = "any", optional = true },
                { kind = "concept", id = "NEWS" },
            },
        },
        {
            id = "pnc.social.news_any_about_target",
            match = {
                { kind = "literal", value = "any" },
                { kind = "concept", id = "NEWS" },
                { kind = "literal", value = "about" },
                { kind = "any", capture = "target" },
            },
            target = true,
        },
        {
            id = "pnc.social.news_tell_me_about_target",
            match = {
                { kind = "literal", value = "tell" },
                { kind = "literal", value = "me" },
                { kind = "literal", value = "some", optional = true },
                { kind = "concept", id = "NEWS" },
                { kind = "literal", value = "about" },
                { kind = "any", capture = "target" },
            },
            target = true,
        },
        {
            id = "pnc.social.news_what_heard_about_target",
            match = {
                { kind = "literal", value = "what" },
                { kind = "literal", value = "have" },
                { kind = "literal", value = "you" },
                { kind = "concept", id = "HEAR" },
                { kind = "literal", value = "about" },
                { kind = "any", capture = "target" },
            },
            target = true,
        },
    }
    local index
    local pattern
    for index = 1, #patterns do
        pattern = patterns[index]
        registerPattern(
            pattern.id,
            pattern.match,
            {
                intent = "GOSSIP",
                speechAct = "GOSSIP",
                subject = "GOSSIP",
                target = pattern.target and "$capture.target" or nil,
                slots = {
                    information = { event = "NEWS" },
                },
            },
            0.98,
            130
        )
    end
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

    -- Prefer the gossip semantic over the open-ended inventory item capture
    -- when a conversational news term follows a stock possession question.
    registerNewsQuestions()

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
