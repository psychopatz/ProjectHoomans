-- Wait command pattern registrations.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog command spoke requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog command spoke requires RegisterPattern")
end

function Internal.RegisterWaitCommands()
    registerPattern(
        "pnc.command.wait",
        { "@WAIT" },
        { intent = "REQUEST", speechAct = "REQUEST", action = "STAY" },
        0.96,
        100
    )
    registerPattern(
        "pnc.command.wait_at_reference",
        {
            { kind = "concept", id = "WAIT" },
            { kind = "literal", value = "there" },
        },
        {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "WAIT_AT",
            target = { reference = "THAT" },
        },
        0.96,
        135
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
end

return Internal

