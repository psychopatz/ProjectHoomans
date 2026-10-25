-- Shared camp command pattern construction.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog camp core requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog camp core requires RegisterPattern")
end

local CAMP_COMMAND_PREFIX = {
    { kind = "literal", value = "let's", optional = true },
    { kind = "literal", value = "lets", optional = true },
    { kind = "literal", value = "we", optional = true },
    { kind = "literal", value = "should", optional = true },
    { kind = "literal", value = "can", optional = true },
    { kind = "literal", value = "make", optional = true },
    { kind = "literal", value = "set", optional = true },
    { kind = "literal", value = "up", optional = true },
}

function Internal.BuildCampCommandMatch(tail)
    local match = {}
    local prefixIndex
    local tailIndex
    local prefixEntry
    for prefixIndex = 1, #CAMP_COMMAND_PREFIX do
        prefixEntry = CAMP_COMMAND_PREFIX[prefixIndex]
        match[#match + 1] = {
            kind = prefixEntry.kind,
            value = prefixEntry.value,
            optional = prefixEntry.optional,
        }
    end
    for tailIndex = 1, #tail do
        match[#match + 1] = tail[tailIndex]
    end
    return match
end

function Internal.RegisterCampPattern(
    patternID,
    tail,
    target,
    confidence,
    priority,
    options
)
    local match = Internal.BuildCampCommandMatch(tail)
    local payload = {
        intent = "REQUEST",
        speechAct = "REQUEST",
        action = "CAMP",
        target = target,
    }
    if options == nil then
        registerPattern(patternID, match, payload, confidence, priority)
        return
    end
    registerPattern(patternID, match, payload, confidence, priority, options)
end

return Internal
