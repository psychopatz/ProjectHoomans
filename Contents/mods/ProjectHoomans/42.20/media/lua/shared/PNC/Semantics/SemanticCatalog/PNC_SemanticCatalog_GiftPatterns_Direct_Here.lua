-- “Here's” and “here is” direct gift-offer registrations.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog direct gift here spoke requires Catalog.Internal")
end

if type(Internal.RegisterDirectGiftPattern) ~= "function" then
    error("semantic catalog direct gift here spoke requires direct gift core")
end

function Internal.RegisterDirectGiftHereOffers()
    Internal.RegisterDirectGiftPattern(
        "pnc.social.gift_here",
        {
            { kind = "literal", value = "here's" },
            { kind = "literal", value = "a", optional = true },
            { kind = "literal", value = "an", optional = true },
            { kind = "literal", value = "some", optional = true },
        },
        true,
        0.95,
        147
    )
    Internal.RegisterDirectGiftPattern(
        "pnc.social.gift_here_is",
        {
            { kind = "literal", value = "here" },
            { kind = "literal", value = "is" },
            { kind = "literal", value = "a", optional = true },
            { kind = "literal", value = "an", optional = true },
            { kind = "literal", value = "some", optional = true },
        },
        true,
        0.95,
        146
    )
end

return Internal
