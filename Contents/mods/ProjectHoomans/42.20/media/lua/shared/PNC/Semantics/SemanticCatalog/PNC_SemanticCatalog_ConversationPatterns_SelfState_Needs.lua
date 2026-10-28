-- Need self-state registrations.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog self-state spoke requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog self-state spoke requires RegisterPattern")
end

local SELF_STATE_PREFIXES = Internal.SelfStatePrefixes
if type(SELF_STATE_PREFIXES) ~= "table" then
    error("semantic catalog self-state needs require prefix definitions")
end

local SELF_STATE_INTENSIFIERS = {
    "really",
    "very",
    "so",
    "fucking",
    "damn",
}

local function selfStateEmit(subject)
    return {
        intent = "INFORM",
        speechAct = "INFORM",
        subject = subject,
        slots = {
            state = {
                type = subject,
                value = "$capture.state.text",
            },
        },
        socialContext = Internal.BuildSelfStateSocialContext(),
    }
end

local function prefixMatch(prefix)
    local match = {}
    for tokenIndex = 1, #prefix.tokens do
        match[#match + 1] = {
            kind = "literal",
            value = prefix.tokens[tokenIndex],
        }
    end
    return match
end

local function appendState(match, subject)
    match[#match + 1] = {
        kind = "concept",
        id = subject,
        capture = "state",
    }
    return match
end

local function registerSelfNeedPatterns(subject)
    for prefixIndex = 1, #SELF_STATE_PREFIXES do
        local prefix = SELF_STATE_PREFIXES[prefixIndex]
        local patternID = "pnc.state.self_" .. string.lower(subject)
            .. "_" .. prefix.id

        registerPattern(
            patternID,
            appendState(prefixMatch(prefix), subject),
            selfStateEmit(subject),
            0.99,
            180
        )

        for intensifierIndex = 1, #SELF_STATE_INTENSIFIERS do
            local intensifier = SELF_STATE_INTENSIFIERS[intensifierIndex]
            local match = prefixMatch(prefix)
            match[#match + 1] = {
                kind = "literal",
                value = intensifier,
            }
            appendState(match, subject)
            registerPattern(
                patternID .. "_intensifier_" .. intensifier,
                match,
                selfStateEmit(subject),
                0.98,
                181
            )
        end
    end
end

function Internal.RegisterSelfNeedPatterns()
    registerSelfNeedPatterns("HUNGER")
    registerSelfNeedPatterns("THIRST")
    registerSelfNeedPatterns("FATIGUE")
end

return Internal
