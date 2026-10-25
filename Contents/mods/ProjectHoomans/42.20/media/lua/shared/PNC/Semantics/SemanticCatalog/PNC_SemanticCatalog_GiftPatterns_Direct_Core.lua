-- Shared direct gift-offer match and payload construction.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog direct gift core requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog direct gift core requires RegisterPattern")
end

local function objectCapture()
    return {
        kind = "any_phrase",
        capture = "object",
        minTokens = 1,
        maxTokens = 4,
        stopWords = { "for", "please", "now" },
    }
end

local function addressCapture()
    return {
        kind = "any_phrase",
        capture = "address",
        optional = true,
        minTokens = 1,
        maxTokens = 2,
        stopWords = { "please", "now" },
    }
end

local function appendEntry(match, entry)
    match[#match + 1] = {
        kind = entry.kind,
        id = entry.id,
        value = entry.value,
        optional = entry.optional,
    }
end

local function giftOfferEmit()
    return {
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
    }
end

function Internal.RegisterDirectGiftPattern(
    patternID,
    prefix,
    forOptional,
    confidence,
    priority
)
    local match = {}
    local prefixIndex
    for prefixIndex = 1, #prefix do
        appendEntry(match, prefix[prefixIndex])
    end
    match[#match + 1] = objectCapture()
    local forEntry = {
        kind = "literal",
        value = "for",
    }
    if forOptional then
        forEntry.optional = true
    end
    match[#match + 1] = forEntry
    match[#match + 1] = {
        kind = "literal",
        value = "you",
        optional = true,
    }
    match[#match + 1] = addressCapture()
    registerPattern(
        patternID,
        match,
        giftOfferEmit(),
        confidence,
        priority,
        { allowFuzzyCapture = true }
    )
end

return Internal
