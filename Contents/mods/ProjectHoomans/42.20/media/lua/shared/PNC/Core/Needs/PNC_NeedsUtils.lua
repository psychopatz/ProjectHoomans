PNC = PNC or {}
PNC.NeedsUtils = PNC.NeedsUtils or {}

local Utils = PNC.NeedsUtils
local Definitions = PNC.NeedsDefinitions

function Utils.WorldAgeHours()
    local time = getGameTime and getGameTime() or nil
    return time and time.getWorldAgeHours
        and math.max(0, tonumber(time:getWorldAgeHours()) or 0) or 0
end

function Utils.NormalizeState(value, at, defaults)
    local source = type(value) == "table" and value or {}
    local state = {
        version = Definitions.VERSION,
        lastUpdateWorldAge = math.max(0, tonumber(source.lastUpdateWorldAge) or tonumber(at) or 0),
    }
    for _, needType in ipairs(Definitions.TYPES) do
        local default = defaults and defaults[needType]
            or Definitions.Get(needType).default
        state[needType] = Definitions.Clamp(
            needType, source[needType] == nil and default or source[needType]
        )
    end
    if Definitions.GROUP_ACTIVITY[tostring(source.debugActivity or "")] then
        state.debugActivity = tostring(source.debugActivity)
    end
    return state
end

function Utils.CopyState(value)
    local copy = {}
    for key, entry in pairs(value or {}) do copy[key] = entry end
    return copy
end

function Utils.GroupSizeModifier(memberCount)
    memberCount = math.max(1, math.floor(tonumber(memberCount) or 1))
    return 1 + (memberCount - 1) * Definitions.GROUP_SIZE_RATE_PER_MEMBER
end

function Utils.RandomInRange(minimum, maximum, seed)
    minimum = math.floor(tonumber(minimum) or 0)
    maximum = math.max(minimum, math.floor(tonumber(maximum) or minimum))
    if seed ~= nil and PNC.Identity and PNC.Identity.MixSeed then
        return minimum + (PNC.Identity.MixSeed(seed, "needs") % (maximum - minimum + 1))
    end
    return ZombRand and ZombRand(minimum, maximum + 1)
        or math.random(minimum, maximum)
end

return Utils
