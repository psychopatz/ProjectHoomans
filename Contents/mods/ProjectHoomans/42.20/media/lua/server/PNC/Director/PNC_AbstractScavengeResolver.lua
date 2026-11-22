-- Aggregate, deterministic scavenging. No containers or physical items exist here.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AbstractScavengeResolver = PNC.AbstractScavengeResolver or {}

local Scavenge = PNC.AbstractScavengeResolver
local Config = PNC.DirectorConfig
local Store = PNC.HoomansWorldView
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

local SUPPLY_CATEGORIES = {
    food = true,
    water = true,
    medical = true,
    materials = true,
}

local function scavengeYieldMultiplier(group, location, nowHours)
    local director = PNC.ScopedWorldEventDirector
    if director and type(director.AggregateEffectsForGroup) == "function" then
        local agg = director.AggregateEffectsForGroup(group, location, nowHours)
        local mult = agg and agg.effects and tonumber(agg.effects.scavengingYieldMultiplier)
        if mult ~= nil then return math.max(0.1, mult) end
    end
    local swe = PsychopatzCore and PsychopatzCore.ScopedWorldEvents
    if swe and type(swe.AggregateEffects) == "function" then
        local agg = swe.AggregateEffects({
            factionID = group and group.factionId or nil,
            settlementID = group and group.homeCommunityId or nil,
            localAreaID = location and location.id or nil,
            includeGlobal = true,
        }, nowHours)
        local mult = agg and agg.effects and tonumber(agg.effects.scavengingYieldMultiplier)
        if mult ~= nil then return math.max(0.1, mult) end
    end
    return 1.0
end

function Scavenge.Calculate(group, location, action)
    local tuning = Config.Scavenging
    local needs = ResourceNeeds.Get(group) or {}
    local before = math.max(0, math.min(100, tonumber(location.scavengedLevel) or 0))
    local remaining = math.max(tuning.MIN_REMAINING_FACTOR, 1 - before / 100)
    local scavengerFactor = capability(group)
    local at = tonumber(action and (action.completedAt or action.startedAt))
        or (Store and Store.WorldAgeHours and Store.WorldAgeHours())
        or nil
    local worldYieldMult = scavengeYieldMultiplier(group, location, at)
    local yields, components, total = {}, {}, 0
    for _, category in ipairs(Config.RESOURCE_CATEGORIES) do
        local potential = math.max(0, tonumber(location.resourcePotential
            and location.resourcePotential[category]) or 0)
        local variance = tuning.VARIANCE_MIN + unit(action.seed, category)
            * (tuning.VARIANCE_MAX - tuning.VARIANCE_MIN)
        local needFactor = 1 + (tonumber(needs[category]) or 0)
            * tuning.NEED_YIELD_BONUS
        local eventFactor = SUPPLY_CATEGORIES[category] and worldYieldMult or 1.0
        local raw = potential * remaining * scavengerFactor
            * tuning.BASE_YIELD_SCALE * needFactor * variance * eventFactor
        local amount = math.max(0, math.min(tuning.MAX_YIELD_PER_RESOURCE,
            math.floor(raw + 0.5)))
        yields[category] = amount
        total = total + amount
        components[category] = { potential = potential,
            need = tonumber(needs[category]) or 0, remainingFactor = remaining,
            scavengerFactor = scavengerFactor, needFactor = needFactor,
            variance = variance, scavengingYieldMultiplier = eventFactor,
            raw = raw, yield = amount }
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
        for category, needType in pairs({ food = "hunger", water = "thirst" }) do
            local scale = Config.Scavenging.NEED_RESTORE_PER_RESOURCE[category] or 0
            PNC.GroupNeeds.Restore(group.factionId, needType,
                (result.yields[category] or 0) * scale, "abstract_scavenge")
        end
    end
    group.diagnostics = group.diagnostics or {}
    group.diagnostics.lastScavenge = result

    local adapter = PNC.CoreSurvivorWorldAdapter
    if adapter and adapter.CommitLocation then
        local canonical, syncReason = adapter.CommitLocation(
            location,
            "abstract_scavenge_location"
        )
        if not canonical then
            return nil, syncReason or "core_location_sync_failed"
        end
    end

    local groupManager = PNC.AbstractGroupManagerInternal
    if groupManager and groupManager.Touch then
        groupManager.Touch(group, "abstract_scavenge_completed")
    else
        group.revision = (tonumber(group.revision) or 0) + 1
        Store.Touch("abstract_scavenge_completed")
    end

    Store.Emit("ABSTRACT_SCAVENGE_COMPLETED", { groupId = group.id,
        locationId = location.id, result = result })
    return result, "completed"
end

Scavenge.Hash = hash
Scavenge.Unit = unit

return Scavenge
