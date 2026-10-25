-- Wellbeing self-state registrations.
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
local SELF_WELLBEING_STATUSES = Internal.SelfWellbeingStatuses
if type(SELF_STATE_PREFIXES) ~= "table" or type(SELF_WELLBEING_STATUSES) ~= "table" then
    error("semantic catalog self-state wellbeing requires shared definitions")
end

local function registerSelfWellbeingPattern(prefix, status, thankYou)
    local thankYouText = thankYou
    if thankYou == true then
        thankYouText = "thank you"
    end
    local match = {}
    local tokenIndex
    for tokenIndex = 1, #prefix.tokens do
        match[#match + 1] = {
            kind = "literal",
            value = prefix.tokens[tokenIndex],
        }
    end
    match[#match + 1] = {
        kind = "literal",
        value = status.phrase,
    }
    if thankYouText then
        -- These exact suffixes keep the whole response anchored without
        -- stealing a standalone THANK utterance.
        match[#match + 1] = {
            kind = "literal",
            value = thankYouText,
        }
    end
    registerPattern(
        "pnc.state.self_wellbeing_" .. prefix.id .. "_" .. status.id
            .. (thankYouText and "_" .. string.gsub(thankYouText, " ", "_") or ""),
        match,
        {
            intent = "INFORM",
            speechAct = "INFORM",
            subject = "WELLBEING",
            slots = {
                state = {
                    type = "WELLBEING",
                    value = status.value,
                },
            },
            socialContext = Internal.BuildSelfStateSocialContext(),
        },
        0.99,
        190
    )
end

function Internal.RegisterSelfWellbeingPatterns()
    local prefixIndex
    local statusIndex
    local prefix
    local status
    for prefixIndex = 1, #SELF_STATE_PREFIXES do
        prefix = SELF_STATE_PREFIXES[prefixIndex]
        for statusIndex = 1, #SELF_WELLBEING_STATUSES do
            status = SELF_WELLBEING_STATUSES[statusIndex]
            registerSelfWellbeingPattern(prefix, status, false)
            if status.thankYou == true then
                registerSelfWellbeingPattern(prefix, status, "thank you")
                registerSelfWellbeingPattern(prefix, status, "thanks")
            end
        end
    end
end

return Internal
