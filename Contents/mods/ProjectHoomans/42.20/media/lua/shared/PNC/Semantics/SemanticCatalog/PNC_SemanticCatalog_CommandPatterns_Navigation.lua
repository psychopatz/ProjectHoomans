-- Navigation command pattern registration.
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

return Internal
