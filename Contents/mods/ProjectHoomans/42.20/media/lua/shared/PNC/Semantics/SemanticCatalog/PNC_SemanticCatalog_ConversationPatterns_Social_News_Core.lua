-- Shared NEWS gossip registration adapter.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog social module requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog social module requires RegisterPattern")
end

function Internal.RegisterNewsPattern(id, match, targeted)
    registerPattern(
        id,
        match,
        {
            intent = "GOSSIP",
            speechAct = "GOSSIP",
            subject = "GOSSIP",
            target = targeted and "$capture.target" or nil,
            slots = {
                information = { event = "NEWS" },
            },
        },
        0.98,
        130
    )
end

return Internal

