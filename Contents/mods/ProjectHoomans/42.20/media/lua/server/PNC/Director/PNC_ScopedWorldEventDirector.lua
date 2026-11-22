-- Deterministic server-authoritative Scoped World Event Director.
-- Kahlua2-safe Lua 5.1: zero pcall, zero next(), zero math.random(), zero OnTick polling.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local ScopedWorldEvents = require "PsychopatzCore/WorldEvents/PsychopatzScopedWorldEvents"

PNC = PNC or {}
PNC.ScopedWorldEventDirector = PNC.ScopedWorldEventDirector or {}

local Director = PNC.ScopedWorldEventDirector

Director.VERSION = 1
Director.SOURCE = "hoomans-world-event"
Director.MAX_ACTIVE_EVENTS = 6
Director.BUCKET_HOURS = 24
Director.DEMEANOR_AXES = {
    "moraleHope",
    "scarcityAnxiety",
    "vigilanceFear",
    "hostilityIrritability",
    "griefStress",
    "confidencePressure",
}

local function finite(value, fallback)
    local num = tonumber(value)
    if num == nil or num ~= num or num == math.huge or num == -math.huge then
        return fallback
    end
    return num
end

local function clamp(value, low, high)
    local num = finite(value, low)
    if num < low then return low end
    if num > high then return high end
    return num
end

local function round2(value)
    return math.floor((tonumber(value) or 0) * 100 + 0.5) / 100
end

local function copyList(list)
    local out = {}
    if type(list) ~= "table" then return out end
    for i = 1, #list do out[i] = list[i] end
    return out
end

local function copyTable(tbl)
    local out = {}
    if type(tbl) ~= "table" then return out end
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            out[k] = copyTable(v)
        else
            out[k] = v
        end
    end
    return out
end

function Director.Hash(text)
    local resolver = PNC.AbstractScavengeResolver
    if resolver and type(resolver.Hash) == "function" then
        return resolver.Hash(text)
    end
    local value = 2166136261
    local str = tostring(text or "")
    for index = 1, #str do
        value = (value * 16777619 + string.byte(str, index)) % 2147483647
    end
    return value
end

Director.CATALOG = Director.CATALOG or {}
Director.CATALOG_ORDER = Director.CATALOG_ORDER or {}

local function registerBuiltIn(def)
    if type(def) ~= "table" or not def.id then return end
    local id = tostring(def.id)
    if not Director.CATALOG[id] then
        Director.CATALOG_ORDER[#Director.CATALOG_ORDER + 1] = id
    end
    Director.CATALOG[id] = def
end

registerBuiltIn({
    id = "food_crisis",
    label = "Food Crisis",
    weight = 22,
    durationHours = 72,
    cooldownHours = 120,
    severity = 0.72,
    provenance = "public",
    mutuallyExclusiveWith = { "agricultural_surplus" },
    semanticTags = { "scarcity", "food", "crisis" },
    effects = {
        foodAvailabilityPressure = 0.65,
        scavengingYieldMultiplier = 0.60,
        moralePressure = 0.45,
        tradeScarcity = 0.55,
    },
    demeanor = {
        scarcityAnxiety = 22,
        moraleHope = -14,
        hostilityIrritability = 8,
        confidencePressure = 6,
    },
    factSummary = "Food supplies have tightened sharply across the area.",
})

registerBuiltIn({
    id = "agricultural_surplus",
    label = "Agricultural Surplus",
    weight = 16,
    durationHours = 72,
    cooldownHours = 120,
    severity = 0.40,
    provenance = "public",
    mutuallyExclusiveWith = { "food_crisis" },
    semanticTags = { "surplus", "food", "harvest" },
    effects = {
        foodAvailabilityPressure = -0.45,
        scavengingYieldMultiplier = 1.35,
        moralePressure = -0.35,
        tradeScarcity = -0.30,
    },
    demeanor = {
        moraleHope = 18,
        scarcityAnxiety = -14,
        confidencePressure = -6,
    },
    factSummary = "Surplus harvests have eased food shortages.",
})

registerBuiltIn({
    id = "bandit_bonanza",
    label = "Raider Surge",
    weight = 20,
    durationHours = 60,
    cooldownHours = 108,
    severity = 0.78,
    provenance = "public",
    semanticTags = { "raiders", "hostile", "security" },
    effects = {
        hostileActivityMultiplier = 1.75,
        travelRisk = 0.65,
        caravanRisk = 0.75,
        moralePressure = 0.35,
    },
    demeanor = {
        vigilanceFear = 24,
        hostilityIrritability = 10,
        confidencePressure = 10,
        moraleHope = -8,
    },
    factSummary = "Raider sightings and ambush activity have spiked along travel routes.",
})

registerBuiltIn({
    id = "severe_weather",
    label = "Severe Weather Front",
    weight = 18,
    durationHours = 36,
    cooldownHours = 84,
    severity = 0.60,
    provenance = "environmental",
    semanticTags = { "weather", "hazard", "shelter" },
    effects = {
        travelRisk = 0.45,
        scavengingYieldMultiplier = 0.80,
        moralePressure = 0.25,
    },
    demeanor = {
        vigilanceFear = 12,
        moraleHope = -10,
        confidencePressure = 8,
    },
    factSummary = "Severe weather is making travel and scavenging hazardous.",
})

registerBuiltIn({
    id = "epidemic",
    label = "Outbreak Wave",
    weight = 12,
    durationHours = 84,
    cooldownHours = 168,
    severity = 0.85,
    provenance = "public",
    semanticTags = { "medical", "illness", "crisis" },
    effects = {
        medicalDemand = 0.75,
        moralePressure = 0.55,
        scavengingYieldMultiplier = 0.85,
        travelRisk = 0.30,
    },
    demeanor = {
        griefStress = 16,
        vigilanceFear = 14,
        moraleHope = -16,
        confidencePressure = 12,
    },
    factSummary = "Illness has been spreading, straining medicine and morale.",
})

registerBuiltIn({
    id = "trade_disruption",
    label = "Trade Disruption",
    weight = 16,
    durationHours = 60,
    cooldownHours = 108,
    severity = 0.62,
    provenance = "public",
    semanticTags = { "trade", "logistics", "scarcity" },
    effects = {
        tradeScarcity = 0.60,
        caravanRisk = 0.50,
        travelRisk = 0.35,
        moralePressure = 0.20,
    },
    demeanor = {
        scarcityAnxiety = 16,
        vigilanceFear = 10,
        moraleHope = -8,
    },
    factSummary = "Trade routes have been disrupted, driving up scarcity and risk.",
})

table.sort(Director.CATALOG_ORDER)

function Director.RegisterEventDefinition(def)
    if type(def) ~= "table" or type(def.id) ~= "string" or def.id == "" then
        return false, "invalid_event_definition"
    end
    local copy = copyTable(def)
    copy.weight = math.max(1, tonumber(copy.weight) or 10)
    copy.durationHours = math.max(1, tonumber(copy.durationHours) or 48)
    copy.cooldownHours = math.max(0, tonumber(copy.cooldownHours) or 72)
    copy.severity = clamp(copy.severity or 0.5, 0, 1)
    copy.provenance = tostring(copy.provenance or "public")
    if not Director.CATALOG[copy.id] then
        Director.CATALOG_ORDER[#Director.CATALOG_ORDER + 1] = copy.id
        table.sort(Director.CATALOG_ORDER)
    end
    Director.CATALOG[copy.id] = copy
    return true, copy
end

function Director.GetCatalog()
    local out = {}
    for i = 1, #Director.CATALOG_ORDER do
        local id = Director.CATALOG_ORDER[i]
        if Director.CATALOG[id] then
            out[#out + 1] = copyTable(Director.CATALOG[id])
        end
    end
    return out
end

function Director.BucketForHours(nowHours, bucketHours)
    local step = math.max(1, finite(bucketHours, Director.BUCKET_HOURS) or Director.BUCKET_HOURS)
    local t = math.max(0, finite(nowHours, 0) or 0)
    return math.floor(t / step), step
end

local function resolveWorldSeed(opts)
    if type(opts) == "table" and opts.worldSeed ~= nil then
        return tostring(opts.worldSeed)
    end
    if PNC.PopulationSectors and type(PNC.PopulationSectors.WorldSeed) == "function" then
        local seed = PNC.PopulationSectors.WorldSeed()
        if seed ~= nil then return tostring(seed) end
    end
    return "PNC_DEFAULT_WORLD"
end

local function isMutuallyExclusive(def, activeEvents)
    local activeTypes = {}
    for i = 1, #activeEvents do
        activeTypes[tostring(activeEvents[i].eventType or "")] = true
    end
    if activeTypes[def.id] then return true end
    for i = 1, #(def.mutuallyExclusiveWith or {}) do
        if activeTypes[tostring(def.mutuallyExclusiveWith[i])] then
            return true
        end
    end
    for activeType in pairs(activeTypes) do
        local other = Director.CATALOG[activeType]
        if other and type(other.mutuallyExclusiveWith) == "table" then
            for i = 1, #other.mutuallyExclusiveWith do
                if tostring(other.mutuallyExclusiveWith[i]) == def.id then
                    return true
                end
            end
        end
    end
    return false
end

local function isOnCooldown(def, scope, scopeID, nowHours, history)
    local cooldown = math.max(0, tonumber(def.cooldownHours) or 0)
    if cooldown <= 0 then return false end
    for i = 1, #history do
        local item = history[i]
        if item.eventType == def.id
            and item.scope == scope
            and tostring(item.scopeID or "global") == tostring(scopeID or "global")
        then
            local ended = tonumber(item.archivedAt or item.endsAt or item.startsAt) or 0
            if (nowHours - ended) < cooldown then
                return true
            end
        end
    end
    return false
end

local function scopeAllowed(def, scope)
    if type(def.allowedScopes) ~= "table" then return true end
    for i = 1, #def.allowedScopes do
        if def.allowedScopes[i] == scope then return true end
    end
    return def.allowedScopes[scope] == true
end

function Director.SelectEventForBucket(worldSeed, scope, scopeID, timeBucket, opts)
    opts = type(opts) == "table" and opts or {}
    scope = tostring(scope or "global")
    scopeID = tostring(scopeID or (scope == "global" and "global" or "default"))
    local bucket = math.floor(tonumber(timeBucket) or 0)
    local bucketHours = math.max(1, finite(opts.bucketHours, Director.BUCKET_HOURS) or Director.BUCKET_HOURS)
    local nowHours = finite(opts.nowHours, bucket * bucketHours)

    local activeForScope = opts.ignoreActive == true and {}
        or ScopedWorldEvents.QueryActive({
            scope = scope,
            scopeID = scope == "global" and nil or scopeID,
            includeGlobal = false,
            source = Director.SOURCE,
        }, nowHours)
    local history = opts.ignoreCooldown == true and {} or ScopedWorldEvents.GetHistory(64)

    local eligible = {}
    local totalWeight = 0
    for i = 1, #Director.CATALOG_ORDER do
        local def = Director.CATALOG[Director.CATALOG_ORDER[i]]
        if def and (tonumber(def.weight) or 0) > 0
            and scopeAllowed(def, scope)
            and not isMutuallyExclusive(def, activeForScope)
            and not isOnCooldown(def, scope, scopeID, nowHours, history)
        then
            eligible[#eligible + 1] = def
            totalWeight = totalWeight + math.floor(tonumber(def.weight) or 1)
        end
    end
    if #eligible == 0 or totalWeight <= 0 then return nil, "no_eligible_event" end

    local seedText = tostring(worldSeed) .. ":" .. scope .. ":"
        .. scopeID .. ":" .. tostring(bucket)
    if opts.allowQuiet == true then
        local quietRoll = Director.Hash(seedText .. ":quiet") % 100
        local quietChance = math.max(0, math.min(95, tonumber(opts.quietPercent) or 25))
        if quietRoll < quietChance then
            return nil, "quiet_bucket"
        end
    end

    local roll = Director.Hash(seedText .. ":pick") % totalWeight
    local acc = 0
    for i = 1, #eligible do
        local def = eligible[i]
        acc = acc + math.floor(tonumber(def.weight) or 1)
        if roll < acc then
            return def, "selected"
        end
    end
    return eligible[#eligible], "selected"
end

local function publishEventFact(ev, def)
    local wk = PNC.WorldKnowledge
    if not wk or type(wk.Publish) ~= "function" then return nil end
    return wk.Publish({
        producer = "hoomans:world_event",
        kind = "world.event",
        subject = { id = tostring(ev.eventType), kind = "world_event", name = def and def.label or ev.eventType },
        location = ev.scope ~= "global"
            and { id = tostring(ev.scopeID), kind = tostring(ev.scope) }
            or nil,
        eventID = ev.eventID,
        occurredAt = ev.startsAt,
        observedAt = ev.startsAt,
        expiresAt = ev.endsAt,
        severity = ev.severity,
        retention = "historical",
        payload = {
            eventID = ev.eventID,
            eventType = ev.eventType,
            scope = ev.scope,
            scopeID = ev.scopeID,
            label = def and def.label or ev.eventType,
            summary = def and def.factSummary or ev.eventType,
        },
    })
end

function Director.EvaluateBucket(nowHours, opts)
    opts = type(opts) == "table" and opts or {}
    nowHours = math.max(0, finite(nowHours, 0) or 0)
    ScopedWorldEvents.PruneExpired(nowHours)

    local activeOwned = ScopedWorldEvents.QueryActive({ source = Director.SOURCE }, nowHours)
    local cap = math.max(1, math.min(Director.MAX_ACTIVE_EVENTS,
        tonumber(opts.maxActive) or Director.MAX_ACTIVE_EVENTS))
    if #activeOwned >= cap then
        return nil, "active_cap_reached"
    end

    local scope = tostring(opts.scope or "global")
    local scopeID = tostring(opts.scopeID or (scope == "global" and "global" or "default"))
    local bucket, bucketHours = Director.BucketForHours(nowHours, opts.bucketHours)
    if opts.timeBucket ~= nil then
        bucket = math.floor(tonumber(opts.timeBucket) or bucket)
    end
    local worldSeed = resolveWorldSeed(opts)

    local def, reason = Director.SelectEventForBucket(worldSeed, scope, scopeID, bucket, {
        bucketHours = bucketHours,
        nowHours = nowHours,
        allowQuiet = opts.allowQuiet,
        quietPercent = opts.quietPercent,
        ignoreCooldown = opts.ignoreCooldown,
        ignoreActive = opts.ignoreActive,
    })
    if not def then return nil, reason end

    local startsAt = opts.startsAt ~= nil and finite(opts.startsAt, bucket * bucketHours)
        or (bucket * bucketHours)
    local duration = finite(opts.durationHours, def.durationHours) or def.durationHours
    local endsAt = startsAt + math.max(1, duration)

    local ev, regReason = ScopedWorldEvents.Register({
        eventID = opts.eventID or ("wev:" .. def.id .. ":" .. scope .. ":" .. scopeID .. ":" .. tostring(bucket)),
        eventType = def.id,
        semanticTags = copyList(def.semanticTags),
        scope = scope,
        scopeID = scopeID,
        affectedSettlements = opts.affectedSettlements,
        x = opts.x,
        y = opts.y,
        radius = opts.radius,
        startsAt = startsAt,
        endsAt = endsAt,
        severity = opts.severity or def.severity,
        source = Director.SOURCE,
        provenance = def.provenance or "public",
        effects = copyTable(def.effects),
        metadata = {
            worldSeed = worldSeed,
            timeBucket = bucket,
            catalogID = def.id,
            label = def.label,
            summary = def.factSummary,
        },
    }, {
        nowHours = nowHours,
        communities = opts.communities,
        resolveSettlements = opts.resolveSettlements,
    })
    if not ev then return nil, regReason end

    local fact = publishEventFact(ev, def)
    return ev, regReason, fact
end

function Director.Pump(nowHours, _, opts)
    opts = type(opts) == "table" and opts or {}
    nowHours = math.max(0, finite(nowHours, 0) or 0)
    local prunedCount = ScopedWorldEvents.PruneExpired(nowHours)
    local ev, reason = Director.EvaluateBucket(nowHours, {
        worldSeed = opts.worldSeed,
        scope = opts.scope or "global",
        scopeID = opts.scopeID or "global",
        allowQuiet = opts.allowQuiet ~= false,
        quietPercent = opts.quietPercent or 25,
        communities = opts.communities,
    })
    return prunedCount + (ev and 1 or 0), ev, reason
end

local function collectUniqueEvents(scopes, nowHours)
    local byID = {}
    local ordered = {}
    local function addBatch(queryOpts)
        local list = ScopedWorldEvents.QueryActive(queryOpts, nowHours)
        for i = 1, #list do
            local ev = list[i]
            if ev and ev.eventID and not byID[ev.eventID] then
                byID[ev.eventID] = ev
                ordered[#ordered + 1] = ev
            end
        end
    end

    if scopes.includeGlobal ~= false then
        addBatch({ global = true })
    end
    if scopes.settlementID then
        addBatch({ settlementID = scopes.settlementID, includeGlobal = false })
    end
    if scopes.regionID then
        addBatch({ regionID = scopes.regionID, includeGlobal = false })
    end
    if scopes.factionID then
        addBatch({ factionID = scopes.factionID, includeGlobal = false })
    end
    if scopes.localAreaID then
        addBatch({ localAreaID = scopes.localAreaID, includeGlobal = false })
    end

    table.sort(ordered, function(a, b)
        if a.startsAt == b.startsAt then return a.eventID < b.eventID end
        return a.startsAt < b.startsAt
    end)
    return ordered
end

local function effectSpecFor(key)
    local known = ScopedWorldEvents.EFFECT_SPECS and ScopedWorldEvents.EFFECT_SPECS[key]
    if known then return known end
    if string.sub(key, -10) == "Multiplier" then
        return { mode = "multiplier", neutral = 1, min = 0.1, max = 4 }
    end
    return { mode = "additive", neutral = 0, min = -2, max = 2 }
end

function Director.AggregateEffectsForContext(ctx, nowHours)
    ctx = type(ctx) == "table" and ctx or {}
    local events = collectUniqueEvents({
        includeGlobal = ctx.includeGlobal ~= false,
        settlementID = ctx.settlementID,
        regionID = ctx.regionID,
        factionID = ctx.factionID,
        localAreaID = ctx.localAreaID,
    }, nowHours)
    local combined = {}
    for key, spec in pairs(ScopedWorldEvents.EFFECT_SPECS or {}) do
        combined[key] = spec.neutral
    end
    local eventIDs = {}
    local maxSeverity = 0
    for i = 1, #events do
        local ev = events[i]
        eventIDs[#eventIDs + 1] = ev.eventID
        if (tonumber(ev.severity) or 0) > maxSeverity then
            maxSeverity = tonumber(ev.severity) or 0
        end
        for key, val in pairs(ev.effects or {}) do
            local spec = effectSpecFor(key)
            if spec.mode == "multiplier" then
                combined[key] = (combined[key] or spec.neutral) * val
            else
                combined[key] = (combined[key] or spec.neutral) + val
            end
        end
    end
    for key, val in pairs(combined) do
        local spec = effectSpecFor(key)
        combined[key] = clamp(val, spec.min, spec.max)
    end
    return {
        effects = combined,
        events = events,
        eventCount = #events,
        eventIDs = eventIDs,
        maxSeverity = maxSeverity,
    }
end

local function communityRegion(settlementID)
    if not settlementID or not PNC.Communities or type(PNC.Communities.Get) ~= "function" then
        return nil
    end
    local comm = PNC.Communities.Get(settlementID)
    return comm and (comm.regionID or comm.regionId) or nil
end

function Director.ContextForFaction(faction)
    if type(faction) ~= "table" then return {} end
    local settlementID = faction.homeCommunityID or faction.homeCommunityId or faction.communityID
    return {
        factionID = faction.id,
        settlementID = settlementID,
        regionID = faction.regionID or faction.regionId or communityRegion(settlementID),
        localAreaID = faction.mobile and faction.mobile.site and faction.mobile.site.id or nil,
    }
end

function Director.ContextForGroup(group, location)
    local settlementID = (type(group) == "table" and group.homeCommunityId)
        or (type(location) == "table" and location.communityID)
        or nil
    return {
        factionID = type(group) == "table" and group.factionId or nil,
        settlementID = settlementID,
        regionID = (type(group) == "table" and (group.regionID or group.regionId))
            or (type(location) == "table" and (location.regionID or location.regionId))
            or communityRegion(settlementID),
        localAreaID = (type(location) == "table" and location.id)
            or (type(group) == "table" and type(group.location) == "table" and group.location.id)
            or nil,
    }
end

function Director.ContextForActor(record)
    if type(record) ~= "table" then return {} end
    local aff = type(record.affiliation) == "table" and record.affiliation or {}
    local settlementID = record.settlementID or record.communityID or aff.communityID
    local factionID = aff.factionID or record.factionID
    local regionID = record.regionID or record.regionId or communityRegion(settlementID)
    if not regionID and factionID and PNC.Factions and type(PNC.Factions.Get) == "function" then
        local faction = PNC.Factions.Get(factionID)
        if faction then
            regionID = faction.regionID or faction.regionId
            if not settlementID then
                settlementID = faction.homeCommunityID or faction.communityID
                regionID = regionID or communityRegion(settlementID)
            end
        end
    end
    return {
        factionID = factionID,
        settlementID = settlementID,
        regionID = regionID,
        localAreaID = record.localAreaID or record.locationID,
    }
end

function Director.AggregateEffectsForFaction(faction, nowHours)
    return Director.AggregateEffectsForContext(Director.ContextForFaction(faction), nowHours)
end

function Director.AggregateEffectsForGroup(group, location, nowHours)
    return Director.AggregateEffectsForContext(Director.ContextForGroup(group, location), nowHours)
end

function Director.AggregateEffectsForSector(sectorID, nowHours)
    local regionID = nil
    if PNC.PopulationSectors and type(PNC.PopulationSectors.Get) == "function" then
        local sector = PNC.PopulationSectors.Get(sectorID)
        regionID = sector and (sector.regionID or sector.regionId) or nil
    end
    return Director.AggregateEffectsForContext({ regionID = regionID }, nowHours)
end

function Director.AggregateEffectsForActor(record, nowHours)
    return Director.AggregateEffectsForContext(Director.ContextForActor(record), nowHours)
end

local function basePersonalityFor(record)
    local projection = PNC.ConvoEngine and PNC.ConvoEngine.DispositionProjection
    if projection and type(projection.Resolve) == "function" then
        local resolved = projection.Resolve(record, { temporaryDemeanor = {} })
        if resolved and resolved.baseDisposition then
            return resolved.baseDisposition
        end
    end
    return {
        bravery = 50, confidence = 50, aggression = 50, compassion = 50,
        sociability = 50, forgiveness = 50, materialism = 50, loyalty = 50,
    }
end

local function axisScaleForPersonality(axis, base)
    local bravery = (tonumber(base.bravery) or 50) / 100
    local confidence = (tonumber(base.confidence) or 50) / 100
    local materialism = (tonumber(base.materialism) or 50) / 100
    local aggression = (tonumber(base.aggression) or 50) / 100
    local compassion = (tonumber(base.compassion) or 50) / 100

    if axis == "vigilanceFear" or axis == "confidencePressure" then
        return 1.35 - 0.70 * ((bravery + confidence) * 0.5)
    elseif axis == "scarcityAnxiety" then
        return 0.70 + 0.65 * materialism
    elseif axis == "hostilityIrritability" then
        return 0.70 + 0.65 * aggression
    elseif axis == "griefStress" then
        return 0.70 + 0.65 * compassion
    elseif axis == "moraleHope" then
        return 0.75 + 0.50 * confidence
    end
    return 1.0
end

function Director.ApplyActorImpulse(record, axes, nowHours, opts)
    if type(record) ~= "table" or type(axes) ~= "table" then return nil end
    opts = type(opts) == "table" and opts or {}
    nowHours = math.max(0, finite(nowHours, 0) or 0)
    local halfLife = math.max(1, finite(opts.halfLifeHours, 48) or 48)
    local duration = math.max(halfLife, finite(opts.durationHours, halfLife * 4) or (halfLife * 4))

    record.runtime = type(record.runtime) == "table" and record.runtime or {}
    local existing = type(record.runtime.chronologyImpulse) == "table"
        and record.runtime.chronologyImpulse or nil
    local merged = {}
    if existing and type(existing.axes) == "table" and nowHours < (tonumber(existing.expiresAt) or 0) then
        local elapsed = math.max(0, nowHours - (tonumber(existing.updatedAt) or nowHours))
        local decay = 0.5 ^ (elapsed / math.max(1, tonumber(existing.halfLifeHours) or 48))
        for i = 1, #Director.DEMEANOR_AXES do
            local axis = Director.DEMEANOR_AXES[i]
            merged[axis] = (tonumber(existing.axes[axis]) or 0) * decay
        end
    end
    for i = 1, #Director.DEMEANOR_AXES do
        local axis = Director.DEMEANOR_AXES[i]
        local delta = finite(axes[axis], 0) or 0
        merged[axis] = clamp((merged[axis] or 0) + delta, -50, 50)
    end
    record.runtime.chronologyImpulse = {
        axes = merged,
        updatedAt = nowHours,
        halfLifeHours = halfLife,
        expiresAt = nowHours + duration,
    }
    return Director.ProjectActorDemeanor(record, nowHours, opts)
end

function Director.ProjectActorDemeanor(record, nowHours, opts)
    if type(record) ~= "table" then return nil end
    opts = type(opts) == "table" and opts or {}
    nowHours = math.max(0, finite(nowHours, 0) or 0)
    local base = basePersonalityFor(record)
    local combined = {}
    for i = 1, #Director.DEMEANOR_AXES do
        combined[Director.DEMEANOR_AXES[i]] = 0
    end

    local ctx = type(opts.scopeContext) == "table" and opts.scopeContext or Director.ContextForActor(record)
    local agg = Director.AggregateEffectsForContext(ctx, nowHours)
    for i = 1, #agg.events do
        local ev = agg.events[i]
        local def = Director.CATALOG[tostring(ev.eventType or "")]
        local template = (def and def.demeanor) or (ev.metadata and ev.metadata.demeanor)
        if type(template) == "table" then
            local severityScale = 0.5 + (tonumber(ev.severity) or 0.5) * 0.75
            for j = 1, #Director.DEMEANOR_AXES do
                local axis = Director.DEMEANOR_AXES[j]
                local baseDelta = finite(template[axis], 0) or 0
                if baseDelta ~= 0 then
                    local scaled = baseDelta * severityScale * axisScaleForPersonality(axis, base)
                    combined[axis] = combined[axis] + scaled
                end
            end
        end
    end

    local runtime = type(record.runtime) == "table" and record.runtime or {}
    local impulse = type(runtime.chronologyImpulse) == "table" and runtime.chronologyImpulse or nil
    if impulse and type(impulse.axes) == "table" then
        if nowHours >= (tonumber(impulse.expiresAt) or 0) then
            runtime.chronologyImpulse = nil
        else
            local elapsed = math.max(0, nowHours - (tonumber(impulse.updatedAt) or nowHours))
            local hl = math.max(1, tonumber(impulse.halfLifeHours) or 48)
            local decay = 0.5 ^ (elapsed / hl)
            local anyNonZero = false
            for i = 1, #Director.DEMEANOR_AXES do
                local axis = Director.DEMEANOR_AXES[i]
                local val = (tonumber(impulse.axes[axis]) or 0) * decay
                if math.abs(val) >= 0.05 then
                    combined[axis] = combined[axis] + val
                    anyNonZero = true
                end
            end
            if not anyNonZero then
                runtime.chronologyImpulse = nil
            end
        end
    end

    for i = 1, #Director.DEMEANOR_AXES do
        local axis = Director.DEMEANOR_AXES[i]
        combined[axis] = round2(clamp(combined[axis], -50, 50))
    end

    record.runtime = type(record.runtime) == "table" and record.runtime or {}
    record.runtime.temporaryDemeanor = combined
    return combined
end

function Director.GrantActorEventFact(record, eventOrID, provenance, nowHours, opts)
    local wk = PNC.WorldKnowledge
    if not wk or not wk.Core or type(record) ~= "table" then
        return nil, "world_knowledge_unavailable"
    end
    opts = type(opts) == "table" and opts or {}
    local eventID = type(eventOrID) == "table" and eventOrID.eventID or tostring(eventOrID or "")
    if eventID == "" then return nil, "event_id_required" end
    local factID = wk.Core.Fact.StableID({
        producer = "hoomans:world_event",
        kind = "world.event",
        subject = type(eventOrID) == "table" and tostring(eventOrID.eventType or "world_event")
            or opts.eventType or "world_event",
        eventID = eventID,
    })
    local actorID = wk.ActorID and wk.ActorID(record) or tostring(record.coreActorID or record.id or "")
    if actorID == "" then return nil, "actor_invalid" end
    local prov = tostring(provenance or "public")
    return wk.Core.Acquire(actorID, factID, {
        authorized = true,
        provenance = prov,
        sourceActorID = opts.sourceActorID,
        source = opts.source or ("world_event_" .. prov),
        acquisitionPath = opts.acquisitionPath or prov,
        confidence = opts.confidence or (prov == "experienced" and 1.0 or prov == "public" and 0.85 or 0.55),
        learnedAt = finite(nowHours, 0) or 0,
    })
end

function Director.ResetRuntime()
    ScopedWorldEvents.Reset()
end

return Director
