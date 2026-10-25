-- Campfire command pattern registrations.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog campfire spoke requires Catalog.Internal")
end

if type(Internal.RegisterCampPattern) ~= "function" then
    error("semantic catalog campfire spoke requires camp core")
end

function Internal.RegisterCampfireCommand()
    Internal.RegisterCampPattern(
        "pnc.command.camp_campfire",
        {
            { kind = "concept", id = "CAMP" },
            { kind = "concept", id = "CAMP_PREP" },
            { kind = "literal", value = "the", optional = true },
            { kind = "concept", id = "CAMPFIRE" },
        },
        {
            kind = "camp_site",
            scope = "campfire",
            concept = "CAMPFIRE",
            text = "campfire",
        },
        0.97,
        150
    )
end

return Internal
