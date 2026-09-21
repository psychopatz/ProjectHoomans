PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog or {}
local Internal = Catalog.Internal or {}
Catalog.Internal = Internal

local IDENTITY_TAIL_WORDS = {
    "now", "your", "turn", "btw", "nice", "to", "meet", "you",
    "please", "an",
}

local function identityNameCapture()
    return {
        kind = "any_phrase",
        capture = "name",
        minTokens = 1,
        maxTokens = 2,
        stopWords = IDENTITY_TAIL_WORDS,
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

function Internal.RegisterIdentityPatterns()
    local registerPattern = Internal.RegisterPattern
    if type(registerPattern) ~= "function" then
        error("semantic identity catalog requires RegisterPattern")
    end

    registerPattern(
        "pnc.identity.self_name_im",
        identityMatch({ "i'm" }),
        identityClaimEmit(),
        0.98,
        155
    )
    registerPattern(
        "pnc.identity.self_name_i_am",
        identityMatch({ "i", "am" }),
        identityClaimEmit(),
        0.98,
        155
    )
    registerPattern(
        "pnc.identity.self_name_im_plain",
        identityMatch({ "im" }),
        identityClaimEmit(),
        0.98,
        155
    )
    registerPattern(
        "pnc.identity.name_is_my_name",
        identityMatch({}, { "is", "my", "name" }),
        identityClaimEmit(),
        0.97,
        154
    )

    local myNameIsMatch = {
        { kind = "literal", value = "my" },
        { kind = "literal", value = "name" },
        { kind = "literal", value = "is" },
        identityNameCapture(),
    }
    appendIdentityTail(myNameIsMatch)
    registerPattern(
        "pnc.identity.my_name_is",
        myNameIsMatch,
        identityClaimEmit(),
        0.97,
        154
    )

    local callMeMatch = {
        { kind = "literal", value = "call" },
        { kind = "literal", value = "me" },
        identityNameCapture(),
    }
    appendIdentityTail(callMeMatch)
    registerPattern(
        "pnc.identity.call_me",
        callMeMatch,
        identityClaimEmit(),
        0.97,
        154
    )

    registerPattern(
        "pnc.identity.self_name_my_names",
        identityMatch({ "my", "name's" }),
        identityClaimEmit(),
        0.98,
        155
    )
    registerPattern(
        "pnc.identity.self_name_you_can_call_me",
        identityMatch({ "you", "can", "call", "me" }),
        identityClaimEmit(),
        0.98,
        155
    )
    registerPattern(
        "pnc.identity.self_name_i_go_by",
        identityMatch({ "i", "go", "by" }),
        identityClaimEmit(),
        0.98,
        155
    )
    registerPattern(
        "pnc.identity.self_name_i_am_called",
        identityMatch({ "i'm", "called" }),
        identityClaimEmit(),
        0.98,
        155
    )
end

return Internal
