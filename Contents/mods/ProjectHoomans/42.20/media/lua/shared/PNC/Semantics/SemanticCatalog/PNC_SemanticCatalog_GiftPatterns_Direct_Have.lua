-- Possession-based direct gift-offer registration.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog direct gift have spoke requires Catalog.Internal")
end

if type(Internal.RegisterDirectGiftPattern) ~= "function" then
    error("semantic catalog direct gift have spoke requires direct gift core")
end

function Internal.RegisterDirectGiftHaveOffer()
    Internal.RegisterDirectGiftPattern(
        "pnc.social.gift_have",
        {
            { kind = "literal", value = "i", optional = true },
            { kind = "concept", id = "HAVE" },
            { kind = "literal", value = "a", optional = true },
            { kind = "literal", value = "an", optional = true },
            { kind = "literal", value = "some", optional = true },
        },
        false,
        0.95,
        148
    )
end

return Internal
