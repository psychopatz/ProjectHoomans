-- Medical/contextual gift-offer pattern registration.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog gift module requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog gift module requires RegisterPattern")
end

function Internal.RegisterContextGiftOffers()
    registerPattern(
        "pnc.social.gift_bandage_context",
        {
            { kind = "literal", value = "i", optional = true },
            { kind = "concept", id = "HAVE" },
            { kind = "literal", value = "some" },
            { kind = "literal", value = "here" },
        },
        {
            intent = "OFFER",
            speechAct = "OFFER",
            action = "GIFT",
            subject = "ITEM",
            object = {
                category = "medical_supply",
                concept = "BANDAGE",
                text = "bandage",
                value = "bandage",
                unresolved = true,
                quantity = "ONE",
            },
            extensions = {
                giftOffer = {
                    mode = "candidate",
                    channel = "semantic",
                    requiresActiveMedicalSupply = true,
                },
            },
        },
        0.99,
        153,
        { allowFuzzyCapture = false }
    )
end

return Internal
