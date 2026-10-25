-- Negated and take command pattern registration.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog command module requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog command module requires RegisterPattern")
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

    -- A prohibition on following has a direct, existing game action: stop.
    registerPattern(
        "pnc.command.stop_negated_follow",
        {
            { kind = "literal", value = "please", optional = true },
            { kind = "literal", value = "don't" },
            { kind = "concept", id = "FOLLOW" },
        },
        { intent = "REQUEST", speechAct = "REQUEST", action = "STOP" },
        0.97,
        126
    )

    registerPattern(
        "pnc.command.stop_do_not_follow",
        {
            { kind = "literal", value = "please", optional = true },
            { kind = "literal", value = "do" },
            { kind = "literal", value = "not" },
            { kind = "concept", id = "FOLLOW" },
        },
        { intent = "REQUEST", speechAct = "REQUEST", action = "STOP" },
        0.97,
        126
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
