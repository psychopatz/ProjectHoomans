-- Local “here” camp command pattern registrations.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog camp here spoke requires Catalog.Internal")
end

if type(Internal.RegisterCampPattern) ~= "function" then
    error("semantic catalog camp here spoke requires camp core")
end

function Internal.RegisterCampHereCommands()
    Internal.RegisterCampPattern(
        "pnc.command.camp_here",
        {
            { kind = "concept", id = "CAMP" },
            { kind = "concept", id = "CAMP_PREP", optional = true },
            { kind = "literal", value = "the", optional = true },
            { kind = "literal", value = "here", optional = true },
            { kind = "literal", value = "now", optional = true },
        },
        {
            kind = "camp_site",
            scope = "here",
        },
        0.96,
        160
    )
    Internal.RegisterCampPattern(
        "pnc.command.camp_here_place",
        {
            { kind = "concept", id = "CAMP" },
            { kind = "concept", id = "CAMP_PREP", optional = true },
            { kind = "literal", value = "the", optional = true },
            { kind = "literal", value = "this" },
            { kind = "literal", value = "place" },
            { kind = "literal", value = "now", optional = true },
        },
        {
            kind = "camp_site",
            scope = "here",
        },
        0.96,
        160
    )
end

return Internal
