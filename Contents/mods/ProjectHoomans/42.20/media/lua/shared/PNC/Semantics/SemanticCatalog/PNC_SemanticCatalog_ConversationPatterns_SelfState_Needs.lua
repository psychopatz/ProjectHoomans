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

local function registerSelfNeedPatterns(subject)
    local prefixIndex
    local tokenIndex
    local prefix
    local match
    local patternID
    for prefixIndex = 1, #SELF_STATE_PREFIXES do
        prefix = SELF_STATE_PREFIXES[prefixIndex]
        match = {}
        for tokenIndex = 1, #prefix.tokens do
            match[#match + 1] = {
                kind = "literal",
                value = prefix.tokens[tokenIndex],
            }
        end
        match[#match + 1] = {
            kind = "concept",
            id = subject,
            capture = "state",
        }
        patternID = "pnc.state.self_" .. string.lower(subject)
            .. "_" .. prefix.id
        registerPattern(patternID, match, {
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
        }, 0.99, 180)
    end
end

function Internal.RegisterSelfNeedPatterns()
    registerSelfNeedPatterns("HUNGER")
    registerSelfNeedPatterns("THIRST")
    registerSelfNeedPatterns("FATIGUE")
end

return Internal
