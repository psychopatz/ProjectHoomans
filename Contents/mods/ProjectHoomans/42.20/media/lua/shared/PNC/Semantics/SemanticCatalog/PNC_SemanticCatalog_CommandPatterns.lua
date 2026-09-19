-- Direct movement, camp, wait, and local NPC command language.
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

function Internal.RegisterBasicCommands()
    registerPattern(
        "pnc.command.follow",
        { "@FOLLOW" },
        { intent = "REQUEST", speechAct = "REQUEST", action = "FOLLOW" },
        0.96,
        100
    )

    registerPattern(
        "pnc.command.stop",
        { "@STOP" },
        { intent = "REQUEST", speechAct = "REQUEST", action = "STOP" },
        0.96,
        100
    )

    registerPattern(
        "pnc.command.wait",
        { "@WAIT" },
        { intent = "REQUEST", speechAct = "REQUEST", action = "STAY" },
        0.96,
        100
    )

    registerPattern(
        "pnc.command.wait_at",
        {
            { kind = "concept", id = "WAIT" },
            { kind = "literal", value = "at" },
            { kind = "literal", value = "the", optional = true },
            {
                kind = "any_phrase",
                capture = "target",
                minTokens = 1,
                maxTokens = 4,
                stopWords = { "please", "now" },
            },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "WAIT_AT",
            target = "$capture.target",
        },
        0.94,
        130
    )

    registerPattern(
        "pnc.command.camp_campfire",
        {
            { kind = "literal", value = "let's", optional = true },
            { kind = "literal", value = "lets", optional = true },
            { kind = "literal", value = "we", optional = true },
            { kind = "literal", value = "should", optional = true },
            { kind = "literal", value = "can", optional = true },
            { kind = "literal", value = "make", optional = true },
            { kind = "literal", value = "set", optional = true },
            { kind = "literal", value = "up", optional = true },
            { kind = "concept", id = "CAMP" },
            { kind = "concept", id = "CAMP_PREP" },
            { kind = "literal", value = "the", optional = true },
            { kind = "concept", id = "CAMPFIRE" },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "CAMP",
            target = {
                kind = "camp_site",
                scope = "campfire",
                concept = "CAMPFIRE",
                text = "campfire",
            },
        },
        0.97,
        150
    )

    registerPattern(
        "pnc.command.camp_room",
        {
            { kind = "literal", value = "let's", optional = true },
            { kind = "literal", value = "lets", optional = true },
            { kind = "literal", value = "we", optional = true },
            { kind = "literal", value = "should", optional = true },
            { kind = "literal", value = "can", optional = true },
            { kind = "literal", value = "make", optional = true },
            { kind = "literal", value = "set", optional = true },
            { kind = "literal", value = "up", optional = true },
            { kind = "concept", id = "CAMP" },
            { kind = "concept", id = "CAMP_PREP" },
            { kind = "literal", value = "the", optional = true },
            {
                kind = "any_phrase",
                capture = "room",
                minTokens = 1,
                maxTokens = 4,
                stopWords = { "please", "now" },
            },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "CAMP",
            target = {
                kind = "camp_site",
                scope = "room",
                roomQuery = "$capture.room",
                roomType = "$capture.room.concept",
                text = "$capture.room.text",
                unresolved = "$capture.room.unresolved",
            },
        },
        0.95,
        140,
        { allowFuzzyCapture = true }
    )

    registerPattern(
        "pnc.command.camp_here",
        {
            { kind = "literal", value = "let's", optional = true },
            { kind = "literal", value = "lets", optional = true },
            { kind = "literal", value = "we", optional = true },
            { kind = "literal", value = "should", optional = true },
            { kind = "literal", value = "can", optional = true },
            { kind = "literal", value = "make", optional = true },
            { kind = "literal", value = "set", optional = true },
            { kind = "literal", value = "up", optional = true },
            { kind = "concept", id = "CAMP" },
            { kind = "concept", id = "CAMP_PREP", optional = true },
            { kind = "literal", value = "the", optional = true },
            { kind = "literal", value = "here", optional = true },
            { kind = "literal", value = "now", optional = true },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "CAMP",
            target = {
                kind = "camp_site",
                scope = "here",
            },
        },
        0.96,
        160
    )

    registerPattern(
        "pnc.command.camp_here_place",
        {
            { kind = "literal", value = "let's", optional = true },
            { kind = "literal", value = "lets", optional = true },
            { kind = "literal", value = "we", optional = true },
            { kind = "literal", value = "should", optional = true },
            { kind = "literal", value = "can", optional = true },
            { kind = "literal", value = "make", optional = true },
            { kind = "literal", value = "set", optional = true },
            { kind = "literal", value = "up", optional = true },
            { kind = "concept", id = "CAMP" },
            { kind = "concept", id = "CAMP_PREP", optional = true },
            { kind = "literal", value = "the", optional = true },
            { kind = "literal", value = "this" },
            { kind = "literal", value = "place" },
            { kind = "literal", value = "now", optional = true },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "CAMP",
            target = {
                kind = "camp_site",
                scope = "here",
            },
        },
        0.96,
        160
    )
end

function Internal.RegisterNavigationCommands()
    registerPattern(
        "pnc.command.go_home",
        {
            { kind = "concept", id = "GO" },
            { kind = "concept", id = "HOME", capture = "destination" },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "GO",
            destination = "$capture.destination",
        },
        0.96,
        110
    )

    registerPattern(
        "pnc.command.go",
        { "@GO" },
        { intent = "REQUEST", speechAct = "REQUEST", action = "GO" },
        0.88,
        90
    )
end

function Internal.RegisterOtherCommands()
    registerPattern(
        "pnc.command.negated_go",
        {
            { kind = "literal", value = "don't" },
            { kind = "concept", id = "GO" },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "GO",
            modifiers = { negated = true },
        },
        0.95,
        120
    )

    registerPattern(
        "pnc.command.negated_take",
        {
            { kind = "literal", value = "don't" },
            { kind = "concept", id = "TAKE" },
            {
                kind = "any_phrase",
                capture = "object",
                optional = true,
                minTokens = 1,
                maxTokens = 4,
            },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "TAKE",
            modifiers = { negated = true },
            object = "$capture.object",
        },
        0.90,
        120
    )

    registerPattern(
        "pnc.command.take",
        {
            { kind = "concept", id = "TAKE" },
            {
                kind = "any_phrase",
                capture = "object",
                minTokens = 1,
                maxTokens = 4,
            },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "TAKE",
            object = "$capture.object",
        },
        0.90,
        100
    )
end

return Internal
