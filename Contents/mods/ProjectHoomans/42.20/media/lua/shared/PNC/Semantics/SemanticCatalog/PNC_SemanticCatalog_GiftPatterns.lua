-- Gift offers express item intent and leave transfers to their adapters.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog module requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog pattern module requires RegisterPattern")
end

function Internal.RegisterGiftOffers()
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

    registerPattern(
        "pnc.social.gift_give_you",
        {
            { kind = "literal", value = "i", optional = true },
            { kind = "literal", value = "want", optional = true },
            { kind = "literal", value = "to", optional = true },
            { kind = "concept", id = "GIVE" },
            { kind = "literal", value = "you" },
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
            { kind = "literal", value = "please", optional = true },
            {
                kind = "any_phrase",
                capture = "address",
                optional = true,
                minTokens = 1,
                maxTokens = 2,
                stopWords = { "now" },
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
        0.94,
        145,
        { allowFuzzyCapture = true }
    )

    registerPattern(
        "pnc.social.gift_reference",
        {
            { kind = "literal", value = "this" },
            { kind = "literal", value = "is" },
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
                text = "this",
                value = "this",
                reference = "THIS",
                unresolved = true,
                quantity = "SOME",
            },
            extensions = {
                giftOffer = { mode = "candidate", channel = "semantic" },
            },
        },
        0.96,
        149
    )

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
