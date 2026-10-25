-- Room-targeted camp command pattern registrations.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog camp room spoke requires Catalog.Internal")
end

if type(Internal.RegisterCampPattern) ~= "function" then
    error("semantic catalog camp room spoke requires camp core")
end

function Internal.RegisterCampRoomCommand()
    Internal.RegisterCampPattern(
        "pnc.command.camp_room",
        {
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
            kind = "camp_site",
            scope = "room",
            roomQuery = "$capture.room",
            roomType = "$capture.room.concept",
            text = "$capture.room.text",
            unresolved = "$capture.room.unresolved",
        },
        0.95,
        140,
        { allowFuzzyCapture = true }
    )
end

return Internal
