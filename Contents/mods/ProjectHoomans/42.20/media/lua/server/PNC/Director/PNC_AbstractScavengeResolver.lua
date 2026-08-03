-- Aggregate, deterministic scavenging. No containers or physical items exist here.

if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.AbstractScavengeResolver = PNC.AbstractScavengeResolver or {}

local Scavenge = PNC.AbstractScavengeResolver
local Config = PNC.DirectorConfig
local Store = PNC.AbstractWorldStore
local Groups = PNC.AbstractGroups
local Locations = PNC.AbstractLocations
local ResourceNeeds = PNC.AbstractResourceNeeds

local function hash(text)
    local value = 2166136261
    for index = 1, #tostring(text or "") do
        value = (value * 16777619 + string.byte(tostring(text), index)) % 2147483647
    end
    return value
end

local function unit(seed, salt)
    return (hash(tostring(seed) .. ":" .. tostring(salt)) % 100000) / 99999
end

function Scavenge.Seed(group, location, startedAt)
    local bucket = math.floor((tonumber(startedAt) or 0) * 60 + 0.5)
    return hash(tostring(group.id) .. ":" .. tostring(location.id) .. ":" .. bucket)
end

function Scavenge.Duration(group, location, seed)
    local tuning = Config.Scavenging
    return tuning.DURATION_MIN_HOURS + unit(seed, "duration")
        * (tuning.DURATION_MAX_HOURS - tuning.DURATION_MIN_HOURS)
end

local function capability(group)
    local count = 0
    for _, npcID in ipairs(group.memberIds or {}) do
        local record = PNC.Registry and PNC.Registry.Get(npcID) or nil
        if record and record.alive ~= false then
            local role = tostring(record.affiliation and record.affiliation.role or "civilian")
            count = count + (role == "scavenger" and 1.2
                or role == "civilian" and 0.55 or 0.8)
        end
    end
    if count <= 0 then return 0 end
    return math.max(0.55, count ^ Config.Scavenging.EFFECTIVE_SCAVENGER_EXPONENT)
end

function Scavenge.Calculate(group, location, action)
    local tuning = Config.Scavenging
    local needs = ResourceNeeds.Get(group) or {}
    local before = math.max(0, math.min(100, tonumber(location.scavengedLevel) or 0))
    local remaining = math.max(tuning.MIN_REMAINING_FACTOR, 1 - before / 100)
    local scavengerFactor = capability(group)
    local yields, components, total = {}, {}, 0
    for _, category in ipairs(Config.RESOURCE_CATEGORIES) do
        local potential = math.max(0, tonumber(location.resourcePotential
            and location.resourcePotential[category]) or 0)
        local variance = tuning.VARIANCE_MIN + unit(action.seed, category)
            * (tuning.VARIANCE_MAX - tuning.VARIANCE_MIN)
        local needFactor = 1 + (tonumber(needs[category]) or 0)
            * tuning.NEED_YIELD_BONUS
        local raw = potential * remaining * scavengerFactor
            * tuning.BASE_YIELD_SCALE * needFactor * variance
        local amount = math.max(0, math.min(tuning.MAX_YIELD_PER_RESOURCE,
            math.floor(raw + 0.5)))
        yields[category] = amount
        total = total + amount
        components[category] = { potential = potential,
            need = tonumber(needs[category]) or 0, remainingFactor = remaining,
            scavengerFactor = scavengerFactor, needFactor = needFactor,
            variance = variance, raw = raw, yield = amount }
    end
    local after = total > 0 and math.min(100, before + tuning.DEPLETION_BASE
        + total * tuning.DEPLETION_PER_YIELD) or before
    return { yields = yields, components = components,
        scavengedBefore = before, scavengedAfter = after,
        remainingFactor = remaining, totalYield = total, seed = action.seed }
end

function Scavenge.Apply(group, location, action)
    if not group or not location or not action
        or group.location.id ~= location.id
    then return nil, "invalid_scavenge_context" end
    local result = Scavenge.Calculate(group, location, action)
    for _, category in ipairs(Config.RESOURCE_CATEGORIES) do
        local amount = tonumber(result.yields[category]) or 0
        group.resources[category] = math.max(0,
            (tonumber(group.resources[category]) or 0) + amount)
    end
    location.scavengedLevel = result.scavengedAfter
    location.revision = (tonumber(location.revision) or 0) + 1
    if group.factionId and PNC.GroupNeeds and PNC.GroupNeeds.Restore then
        for category, needType in pairs({ food = "hunger", water = "hydration" }) do
            local scale = Config.Scavenging.NEED_RESTORE_PER_RESOURCE[category] or 0
            PNC.GroupNeeds.Restore(group.factionId, needType,
                (result.yields[category] or 0) * scale, "abstract_scavenge")
        end
    end
    group.diagnostics = group.diagnostics or {}
    group.diagnostics.lastScavenge = result
    group.revision = (tonumber(group.revision) or 0) + 1
    Store.Touch("abstract_scavenge_completed")
    Store.Emit("ABSTRACT_SCAVENGE_COMPLETED", { groupId = group.id,
        locationId = location.id, result = result })
    return result, "completed"
end

Scavenge.Hash = hash
Scavenge.Unit = unit

return Scavenge
