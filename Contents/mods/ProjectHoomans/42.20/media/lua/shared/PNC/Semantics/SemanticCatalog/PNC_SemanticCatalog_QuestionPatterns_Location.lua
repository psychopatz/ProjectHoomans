-- Location and seen-target question pattern registration.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog question module requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog question module requires RegisterPattern")
end

local traderTarget = {
    kind = "community_role",
    id = "trader",
    role = "trader",
    text = "the trader",
    unresolved = false,
}

function Internal.RegisterLocationQuestions()
    local currentLocationEmit = {
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "CURRENT_LOCATION",
    }
    registerPattern(
        "pnc.question.current_location.where_are_we",
        {
            { kind = "literal", value = "where" },
            { kind = "literal", value = "are" },
            { kind = "literal", value = "we" },
            { kind = "literal", value = "right", optional = true },
            { kind = "literal", value = "now", optional = true },
            { kind = "literal", value = "at", optional = true },
        },
        currentLocationEmit,
        0.98,
        125
    )
    registerPattern(
        "pnc.question.current_location.do_you_know_where_we_are",
        {
            { kind = "literal", value = "do" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "know" },
            { kind = "literal", value = "where" },
            { kind = "literal", value = "we" },
            { kind = "literal", value = "are" },
            { kind = "literal", value = "right", optional = true },
            { kind = "literal", value = "now", optional = true },
        },
        currentLocationEmit,
        0.99,
        126
    )
    registerPattern(
        "pnc.question.current_location.what_place_is_this",
        {
            { kind = "literal", value = "what" },
            { kind = "literal", value = "place" },
            { kind = "literal", value = "is" },
            { kind = "literal", value = "this" },
        },
        currentLocationEmit,
        0.97,
        124
    )
    registerPattern(
        "pnc.question.current_location.what_is_this_place",
        {
            { kind = "literal", value = "what" },
            { kind = "literal", value = "is" },
            { kind = "literal", value = "this" },
            { kind = "literal", value = "place" },
        },
        currentLocationEmit,
        0.97,
        124
    )
    registerPattern(
        "pnc.question.current_location.whats_this_place",
        {
            { kind = "literal", value = "whats" },
            { kind = "literal", value = "this" },
            { kind = "literal", value = "place" },
        },
        currentLocationEmit,
        0.97,
        124
    )
    registerPattern(
        "pnc.question.current_location.where_is_this",
        {
            { kind = "literal", value = "where" },
            { kind = "literal", value = "is" },
            { kind = "literal", value = "this" },
        },
        currentLocationEmit,
        0.96,
        123
    )
    for _, noun in ipairs({ "town", "building", "road", "street", "zone", "area" }) do
        registerPattern(
            "pnc.question.current_location.what_" .. noun .. "_is_this",
            {
                { kind = "literal", value = "what" },
                { kind = "literal", value = noun },
                { kind = "literal", value = "is" },
                { kind = "literal", value = "this" },
            },
            currentLocationEmit,
            0.97,
            124
        )
        registerPattern(
            "pnc.question.current_location.what_" .. noun .. "_are_we_in",
            {
                { kind = "literal", value = "what" },
                { kind = "literal", value = noun },
                { kind = "literal", value = "are" },
                { kind = "literal", value = "we" },
                { kind = "literal", value = "in", optional = true },
                { kind = "literal", value = "on", optional = true },
            },
            currentLocationEmit,
            0.97,
            124
        )
    end

    registerPattern(
        "pnc.question.community_role_whereabouts.your_trader",
        {
            { kind = "literal", value = "where" },
            { kind = "literal", value = "is" },
            { kind = "literal", value = "your" },
            { kind = "literal", value = "trader" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "COMMUNITY_ROLE_WHEREABOUTS",
            target = traderTarget,
            slots = { role = "trader" },
        },
        0.98,
        120
    )

    registerPattern(
        "pnc.question.community_role_whereabouts.the_trader",
        {
            { kind = "literal", value = "where's" },
            { kind = "literal", value = "the" },
            { kind = "literal", value = "trader" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "COMMUNITY_ROLE_WHEREABOUTS",
            target = traderTarget,
            slots = { role = "trader" },
        },
        0.98,
        121
    )

    registerPattern(
        "pnc.question.community_role_whereabouts.trader_went",
        {
            { kind = "literal", value = "do" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "know" },
            { kind = "literal", value = "where" },
            { kind = "literal", value = "the" },
            { kind = "literal", value = "trader" },
            { kind = "literal", value = "went" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "COMMUNITY_ROLE_WHEREABOUTS",
            target = traderTarget,
            slots = { role = "trader" },
        },
        0.98,
        122
    )

    registerPattern(
        "pnc.question.where",
        {
            { kind = "literal", value = "where" },
            { kind = "literal", value = "is" },
            {
                kind = "any_phrase",
                capture = "target",
                minTokens = 1,
                maxTokens = 4,
            },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "LOCATION",
            target = "$capture.target",
        },
        0.90,
        80
    )

    registerPattern(
        "pnc.question.where_can_find",
        {
            { kind = "literal", value = "where" },
            { kind = "literal", value = "can" },
            { kind = "literal", value = "i" },
            { kind = "literal", value = "find" },
            {
                kind = "any_phrase",
                capture = "target",
                minTokens = 1,
                maxTokens = 4,
            },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "LOCATION",
            target = "$capture.target",
        },
        0.91,
        82
    )

    registerPattern(
        "pnc.question.where_do_you_know",
        {
            { kind = "literal", value = "do" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "know" },
            { kind = "literal", value = "where" },
            {
                kind = "any_phrase",
                capture = "target",
                minTokens = 1,
                maxTokens = 4,
                stopWords = { "is" },
            },
            { kind = "literal", value = "is" },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "LOCATION",
            target = "$capture.target",
        },
        0.90,
        81
    )

    registerPattern(
        "pnc.question.seen",
        {
            { kind = "literal", value = "did" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "see" },
            {
                kind = "any_phrase",
                capture = "target",
                minTokens = 1,
                maxTokens = 4,
            },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "SEEN",
            target = "$capture.target",
        },
        0.88,
        80
    )

    registerPattern(
        "pnc.question.seen_have_you_seen",
        {
            { kind = "literal", value = "have" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "seen" },
            {
                kind = "any_phrase",
                capture = "target",
                minTokens = 1,
                maxTokens = 4,
            },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "SEEN",
            target = "$capture.target",
        },
        0.90,
        82
    )

    registerPattern(
        "pnc.question.seen_happen_to",
        {
            { kind = "literal", value = "did" },
            { kind = "literal", value = "you" },
            { kind = "literal", value = "happen" },
            { kind = "literal", value = "to" },
            { kind = "literal", value = "see" },
            {
                kind = "any_phrase",
                capture = "target",
                minTokens = 1,
                maxTokens = 4,
            },
        },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "SEEN",
            target = "$capture.target",
        },
        0.89,
        81
    )
end

return Internal
