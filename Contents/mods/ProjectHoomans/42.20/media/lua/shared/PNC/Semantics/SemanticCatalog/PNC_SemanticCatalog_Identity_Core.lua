-- Shared identity claim grammar and payload construction.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog or {}
local Internal = Catalog.Internal or {}
Catalog.Internal = Internal

local IDENTITY_TAIL_WORDS = {
    "now", "your", "turn", "btw", "nice", "to", "meet", "you",
    "please", "an",
}

-- Keep these words out of the open-ended identity capture so an unmatched
-- wellbeing or need utterance cannot become a name claim.
local IDENTITY_CAPTURE_STOP_WORDS = {
    "fine", "okay", "ok", "alright", "all", "right", "good", "well",
    "thanks", "thank", "sorry", "apologies", "hungry", "starving", "famished", "thirsty", "parched",
    "tired", "exhausted", "sleepy", "worn", "out", "really", "very", "so",
    "fucking", "damn", "now", "your", "turn", "btw",
    "nice", "to", "meet", "you", "please", "an",
}

local function identityNameCapture()
    return {
        kind = "any_phrase",
        capture = "name",
        minTokens = 1,
        maxTokens = 2,
        stopWords = IDENTITY_CAPTURE_STOP_WORDS,
    }
end

local function appendIdentityTail(match)
    local index
    local word
    for index = 1, #IDENTITY_TAIL_WORDS do
        word = IDENTITY_TAIL_WORDS[index]
        -- Keep natural introductions bounded instead of making the name
        -- capture an arbitrary-English parser.
        match[#match + 1] = {
            kind = "literal",
            value = word,
            optional = true,
        }
    end
    return match
end

local function identityMatch(prefix, suffix)
    local match = {}
    local index
    for index = 1, #prefix do
        match[#match + 1] = {
            kind = "literal",
            value = prefix[index],
        }
    end
    match[#match + 1] = identityNameCapture()
    for index = 1, #(suffix or {}) do
        match[#match + 1] = {
            kind = "literal",
            value = suffix[index],
        }
    end
    return appendIdentityTail(match)
end

local function identityClaimEmit()
    return {
        intent = "INFORM",
        speechAct = "INFORM",
        subject = "IDENTITY",
        slots = {
            identityClaim = {
                claimType = "SELF_NAME",
                name = "$capture.name.text",
            },
        },
        socialContext = {
            directed = false,
            selfDirected = true,
            target = "SELF",
            identityClaim = true,
        },
    }
end

function Internal.RegisterIdentityPattern(
    patternID,
    prefix,
    suffix,
    confidence,
    priority
)
    local registerPattern = Internal.RegisterPattern
    if type(registerPattern) ~= "function" then
        error("semantic identity catalog requires RegisterPattern")
    end
    registerPattern(
        patternID,
        identityMatch(prefix, suffix),
        identityClaimEmit(),
        confidence,
        priority
    )
end

return Internal
