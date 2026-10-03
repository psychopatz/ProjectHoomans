-- Relationship type primitive sanitizers.

PNC = PNC or {}
PNC.RelationshipTypes = PNC.RelationshipTypes or {}

-- Defensive constructors and canonical normalizers for social persistence.

PNC = PNC or {}
PNC.RelationshipTypes = PNC.RelationshipTypes or {}

local Types = PNC.RelationshipTypes
local Constants = PNC.RelationshipConstants
local EntityRef = PNC.EntityRef
local ProfileTypes = PNC.SocialProfileTypes
local ConductTypes = PNC.ConductTypes

local function finiteNumber(value)
    local numeric = tonumber(value)
    if numeric == nil
        or numeric ~= numeric
        or numeric == math.huge
        or numeric == -math.huge
    then
        return nil
    end
    return numeric
end

local function clamp(value, minimum, maximum, fallback)
    local numeric = finiteNumber(value)
    if numeric == nil then
        numeric = fallback
    end
    if numeric < minimum then
        return minimum
    end
    if numeric > maximum then
        return maximum
    end
    return numeric
end

local function nonNegative(value, fallback)
    local numeric = finiteNumber(value)
    if numeric == nil then
        numeric = fallback or 0
    end
    return math.max(0, numeric)
end

local function revision(value)
    return math.max(0, math.floor(finiteNumber(value) or 0))
end

local function normalizeRequiredString(value)
    if type(value) ~= "string" or value == "" or string.find(value, "%c") then
        return nil
    end
    return value
end

local function normalizeTags(value)
    local output = {}
    local key
    local enabled
    if type(value) ~= "table" then
        return output
    end
    for key, enabled in pairs(value) do
        if enabled == true and type(key) == "string" and key ~= ""
            and not string.find(key, "%c")
        then
            output[key] = true
        end
    end
    return output
end

local function normalizeNumericMap(value)
    local output = {}
    local key
    local numeric
    if type(value) ~= "table" then
        return output
    end
    for key, numeric in pairs(value) do
        if type(key) == "string" and key ~= "" then
            numeric = finiteNumber(numeric)
            if numeric ~= nil then
                output[key] = numeric
            end
        end
    end
    return output
end

local function normalizeSaturationMap(value)
    local output = {}
    local key
    local entry
    local approval
    local respect
    if type(value) ~= "table" then
        return output
    end
    for key, entry in pairs(value) do
        if type(key) == "string" and key ~= "" then
            if type(entry) == "table" then
                approval = finiteNumber(entry.approval)
                respect = finiteNumber(entry.respect)
                if approval ~= nil or respect ~= nil then
                    output[key] = {
                        approval = approval or 0,
                        respect = respect or 0,
                    }
                end
            else
                -- Preserve the Phase 1 numeric placeholder representation.
                -- Phase 2 writes structured entries but old/future data must
                -- continue to normalize without being destroyed.
                entry = finiteNumber(entry)
                if entry ~= nil then
                    output[key] = entry
                end
            end
        end
    end
    return output
end

local function normalizeStringList(value, maximum)
    local seen = {}
    local output = {}
    local extras = {}
    local index
    local key
    local item
    if type(value) ~= "table" then
        return output
    end
    -- Numeric insertion order is meaningful for the bounded recent-event
    -- cache. Malformed map entries are repaired deterministically afterward.
    for index = 1, #value do
        item = normalizeRequiredString(value[index])
        if item and not seen[item] then
            seen[item] = true
            output[#output + 1] = item
        end
    end
    for key, item in pairs(value) do
        if type(key) ~= "number"
            or key < 1
            or key > #value
            or key ~= math.floor(key)
        then
            item = normalizeRequiredString(item)
            if item and not seen[item] then
                extras[#extras + 1] = item
            end
        end
    end
    table.sort(extras)
    for index = 1, #extras do
        item = extras[index]
        item = normalizeRequiredString(item)
        if item and not seen[item] then
            seen[item] = true
            output[#output + 1] = item
        end
    end
    while #output > maximum do
        table.remove(output, 1)
    end
    return output
end

local function boundedString(value, maximum)
    value = normalizeRequiredString(value)
    if not value then return nil end
    return string.sub(value, 1, maximum or 256)
end


Types.Internal = Types.Internal or {}
local Internal = Types.Internal
Internal.FiniteNumber = finiteNumber
Internal.Clamp = clamp
Internal.NonNegative = nonNegative
Internal.Revision = revision
Internal.NormalizeRequiredString = normalizeRequiredString
Internal.NormalizeTags = normalizeTags
Internal.NormalizeNumericMap = normalizeNumericMap
Internal.NormalizeSaturationMap = normalizeSaturationMap
Internal.NormalizeStringList = normalizeStringList
Internal.BoundedString = boundedString

return Types
