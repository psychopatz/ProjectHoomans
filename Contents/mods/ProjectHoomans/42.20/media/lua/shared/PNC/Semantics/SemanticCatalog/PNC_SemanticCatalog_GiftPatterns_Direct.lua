-- Direct possession and here-is gift-offer pattern registration.
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

function Internal.RegisterDirectGiftOffers()
    registerPattern(
        "pnc.social.gift_have",
        {
            { kind = "literal", value = "i", optional = true },
            { kind = "concept", id = "HAVE" },
            { kind = "literal", value = "a", optional = true },
            { kind = "literal", value = "an", optional = true },
            { kind = "literal", value = "some", optional = true },
            {
                kind = "any_phrase",
                capture = "object",
                minTokens = 1,
                maxTokens = 4,
                stopWords = { "for", "please", "now" },
            },
            { kind = "literal", value = "for" },
            { kind = "literal", value = "you", optional = true },
            {
                kind = "any_phrase",
                capture = "address",
                optional = true,
                minTokens = 1,
                maxTokens = 2,
                stopWords = { "please", "now" },
            },
        },
        {
            intent = "OFFER",
            speechAct = "OFFER",
            action = "GIFT",
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
            extensions = {
                giftOffer = { mode = "candidate", channel = "semantic" },
            },
        },
        0.95,
        148,
        { allowFuzzyCapture = true }
    )

    registerPattern(
        "pnc.social.gift_here",
        {
            { kind = "literal", value = "here's" },
            { kind = "literal", value = "a", optional = true },
            { kind = "literal", value = "an", optional = true },
            { kind = "literal", value = "some", optional = true },
            {
                kind = "any_phrase",
                capture = "object",
                minTokens = 1,
                maxTokens = 4,
                stopWords = { "for", "please", "now" },
            },
            { kind = "literal", value = "for", optional = true },
            { kind = "literal", value = "you", optional = true },
            {
                kind = "any_phrase",
                capture = "address",
                optional = true,
                minTokens = 1,
                maxTokens = 2,
                stopWords = { "please", "now" },
            },
        },
        {
            intent = "OFFER",
            speechAct = "OFFER",
            action = "GIFT",
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
            extensions = {
                giftOffer = { mode = "candidate", channel = "semantic" },
            },
        },
        0.95,
        147,
        { allowFuzzyCapture = true }
    )

    registerPattern(
        "pnc.social.gift_here_is",
        {
            { kind = "literal", value = "here" },
            { kind = "literal", value = "is" },
            { kind = "literal", value = "a", optional = true },
            { kind = "literal", value = "an", optional = true },
            { kind = "literal", value = "some", optional = true },
            {
                kind = "any_phrase",
                capture = "object",
                minTokens = 1,
                maxTokens = 4,
                stopWords = { "for", "please", "now" },
            },
            { kind = "literal", value = "for", optional = true },
            { kind = "literal", value = "you", optional = true },
            {
                kind = "any_phrase",
                capture = "address",
                optional = true,
                minTokens = 1,
                maxTokens = 2,
                stopWords = { "please", "now" },
            },
        },
        {
            intent = "OFFER",
            speechAct = "OFFER",
            action = "GIFT",
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
            extensions = {
                giftOffer = { mode = "candidate", channel = "semantic" },
            },
        },
        0.95,
        146,
        { allowFuzzyCapture = true }
    )

end

return Internal
