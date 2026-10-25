-- Open gift-offer request pattern registration.
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

function Internal.RegisterGiftRequests()
    registerPattern(
        "pnc.social.offer",
        {
            { kind = "literal", value = "who", optional = true },
            { kind = "literal", value = "does", optional = true },
            { kind = "literal", value = "anyone", optional = true },
            { kind = "concept", id = "WANT" },
            { kind = "literal", value = "a", optional = true },
            { kind = "literal", value = "an", optional = true },
            { kind = "literal", value = "some", optional = true },
            { kind = "literal", value = "the", optional = true },
            {
                kind = "any_phrase",
                capture = "object",
                minTokens = 1,
                maxTokens = 4,
                stopWords = { "please", "now" },
            },
            { kind = "literal", value = "please", optional = true },
        },
        {
            intent = "OFFER",
            speechAct = "OFFER",
            subject = "ITEM",
            object = {
                category = "$capture.object.category",
                concept = "$capture.object.concept",
                text = "$capture.object.text",
                value = "$capture.object.value",
                unresolved = "$capture.object.unresolved",
                reference = "$capture.object.reference",
                quantity = "SOME",
            },
        },
        0.94,
        120,
        { allowFuzzyCapture = true }
    )
end

return Internal
