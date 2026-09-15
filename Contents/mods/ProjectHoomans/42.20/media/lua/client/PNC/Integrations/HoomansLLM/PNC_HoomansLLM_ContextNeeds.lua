-- Bounded, revisioned needs projection for interactive LLM context.
PNC = PNC or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}
PNC.HoomansLLM.Internal = PNC.HoomansLLM.Internal or {}

local Internal = PNC.HoomansLLM.Internal
local Runtime = Internal.Runtime
local Needs = Internal.ContextNeeds or {}
Internal.ContextNeeds = Needs

local NEED_TYPES = { "hunger", "thirst", "fatigue" }
local NEED_LEVEL_WEIGHT = {
    NORMAL = 0,
    MINOR = 1,
    MODERATE = 2,
    SEVERE = 3,
    CRITICAL = 4,
}
local needsCache = {}
local needsCacheOrder = {}
local NEED_CACHE_LIMIT = 32

function Needs.Build(npcID, source)
    local values = source and source.needs
    if type(values) ~= "table" then return nil end
    local signatureParts = {}
    local digest = {}
    local highestType = nil
    local highestLevel = "NORMAL"
    local highestWeight = -1
    for _, needType in ipairs(NEED_TYPES) do
        local value = tonumber(values[needType])
        if value ~= nil then
            value = math.max(0, math.min(1, value))
            signatureParts[#signatureParts + 1] = needType .. ":" .. tostring(value)
            digest[needType] = value
            local definitions = PNC.NeedsDefinitions
            local level = definitions and definitions.GetLevel
                and definitions.GetLevel(needType, value) or nil
            if level then
                digest[needType .. "_level"] = level
                local weight = NEED_LEVEL_WEIGHT[level] or 0
                if weight > highestWeight then
                    highestWeight = weight
                    highestType = needType
                    highestLevel = level
                end
            end
        end
    end
    if #signatureParts == 0 then return nil end
    local id = Runtime.Trim(npcID or "unknown-npc")
    local signature = table.concat(signatureParts, "|")
    local cached = needsCache[id]
    if cached and cached.signature == signature then
        return cached.digest
    end
    digest.highest = highestType
    digest.urgency = string.lower(highestLevel)
    digest.revision = (cached and cached.revision or 0) + 1
    digest.sampled_at = tonumber(
        source.needsSampledAt or source.snapshotAt
            or values.sampledAt
    )
    needsCache[id] = {
        signature = signature,
        revision = digest.revision,
        digest = digest,
    }
    if not cached then
        needsCacheOrder[#needsCacheOrder + 1] = id
        while #needsCacheOrder > NEED_CACHE_LIMIT do
            local oldest = table.remove(needsCacheOrder, 1)
            if oldest ~= id then needsCache[oldest] = nil end
        end
    end
    return digest
end

function Needs.Reset()
    needsCache = {}
    needsCacheOrder = {}
end

return Needs
