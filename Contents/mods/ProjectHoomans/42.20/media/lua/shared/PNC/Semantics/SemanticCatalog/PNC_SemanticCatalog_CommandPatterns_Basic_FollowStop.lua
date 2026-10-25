-- Follow and stop command pattern registrations.
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

function Internal.RegisterFollowStopCommands()
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
        "pnc.command.stop_following",
        {
            { kind = "literal", value = "please", optional = true },
            { kind = "concept", id = "STOP" },
            {
                kind = "concept",
                id = "FOLLOW",
                verbForms = { "PROGRESSIVE" },
            },
            { kind = "literal", value = "me", optional = true },
        },
        { intent = "REQUEST", speechAct = "REQUEST", action = "STOP" },
        0.97,
        125
    )
end

return Internal

