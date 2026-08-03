-- Lazy settlement candidates sourced only from registered/loaded locations.

if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.SettlementCandidates = PNC.SettlementCandidates or {}

local Candidates = PNC.SettlementCandidates
local Config = PNC.DirectorConfig.Population
local Sectors = PNC.PopulationSectors
local Locations = PNC.AbstractLocations
local Store = PNC.AbstractWorldStore
local Core = PNC.Core
local Log = PNC.PopulationLog

Candidates.Pools = Candidates.Pools or {}
Candidates.Reservations = Candidates.Reservations or {}
Candidates.Metrics = Candidates.Metrics or { discovered = 0, evaluated = 0,
    rejected = 0, reservations = 0, metaQueries = 0,
    metaMatched = 0, metaInspected = 0, metaDiscovered = 0,
    starterDiscovered = 0 }
for _, field in ipairs({ "discovered", "evaluated", "rejected",
    "reservations", "metaQueries", "metaMatched", "metaInspected",
    "metaDiscovered", "starterDiscovered" }) do
    Candidates.Metrics[field] = tonumber(Candidates.Metrics[field]) or 0
end
Candidates.LastEvaluations = Candidates.LastEvaluations or {}
Candidates.LastStarterDiscovery = Candidates.LastStarterDiscovery or {}
Candidates.LastMetaDiscovery = Candidates.LastMetaDiscovery or {}
Candidates.Cursors = Candidates.Cursors or {}

local function populationData()
    Store.EnsureLoaded()
    return Store.Registry.population
end

local function add(location)
    if not location then return false end
    local sectorID = Sectors.IDForPosition(location.x, location.y)
    Candidates.Pools[sectorID] = Candidates.Pools[sectorID] or {}
    if Candidates.Pools[sectorID][location.id] then return false end
    Candidates.Pools[sectorID][location.id] = true
    Candidates.Metrics.discovered = Candidates.Metrics.discovered + 1
    return true
end

function Candidates.RegisterLocation(location) return add(location) end

function Candidates.Rebuild()
    Candidates.Pools = {}
    for _, location in ipairs(Locations.List()) do add(location) end
end

function Candidates.Discover(sectorID, budget)
    local center = Sectors.Center(sectorID)
    if not center then return 0 end
    budget = math.max(1, math.floor(tonumber(budget)
        or Config.CANDIDATE_EVALUATION_BUDGET))
    Locations.DiscoverLoadedNear(center.x, center.y, center.z,
        Config.SECTOR_SIZE * 0.75, budget)
    local found = 0
    for _, entry in ipairs(Locations.GetNearby(center.x, center.y,
        Config.SECTOR_SIZE * 0.75, budget * 4)) do
        if Sectors.IDForPosition(entry.location.x, entry.location.y) == sectorID
            and add(entry.location) then found = found + 1 end
    end
    return found
end

function Candidates.DiscoverMeta(sectorID, seed, purpose)
    local sx, sy = Sectors.ParseID(sectorID)
    if not sx then return 0, { reason = "INVALID_SECTOR" } end
    local size = Config.SECTOR_SIZE
    local found, diagnostic = Locations.DiscoverMetaBuildingsInBounds({
        minX = sx * size, minY = sy * size,
        maxX = (sx + 1) * size - 1,
        maxY = (sy + 1) * size - 1,
    }, 0, seed, Config.STARTER_META_CANDIDATE_LIMIT,
        Config.STARTER_META_INSPECTION_LIMIT)
    diagnostic = diagnostic or { reason = "DISCOVERY_FAILED" }
    diagnostic.sectorId = sectorID
    diagnostic.seed = seed
    diagnostic.purpose = tostring(purpose or "POPULATION_FALLBACK")
    Candidates.Metrics.metaQueries = Candidates.Metrics.metaQueries + 1
    Candidates.Metrics.metaMatched = Candidates.Metrics.metaMatched
        + (tonumber(diagnostic.matched) or 0)
    Candidates.Metrics.metaInspected = Candidates.Metrics.metaInspected
        + (tonumber(diagnostic.inspected) or 0)
    for _, locationID in ipairs(diagnostic.locationIds or {}) do
        if add(Locations.Get(locationID)) then
            Candidates.Metrics.metaDiscovered =
                Candidates.Metrics.metaDiscovered + 1
            if purpose == "STARTER" then
                Candidates.Metrics.starterDiscovered =
                    Candidates.Metrics.starterDiscovered + 1
            end
        end
    end
    Candidates.LastMetaDiscovery[sectorID] = Core.DeepCopy(diagnostic)
    if purpose == "STARTER" then
        Candidates.LastStarterDiscovery[sectorID] = Core.DeepCopy(diagnostic)
    end
    local fields = { sectorId = sectorID, purpose = diagnostic.purpose,
        seed = seed, reason = diagnostic.reason, found = diagnostic.found,
        matched = diagnostic.matched, inspected = diagnostic.inspected,
        residential = diagnostic.residential }
    if (tonumber(diagnostic.found) or 0) > 0 then
        Log.Info("META_SITE_DISCOVERY", fields)
    else
        Log.Warn("META_SITE_DISCOVERY", fields)
    end
    return found, diagnostic
end

function Candidates.DiscoverStarter(sectorID, seed)
    return Candidates.DiscoverMeta(sectorID, seed, "STARTER")
end

local function siteCollision(location)
    local site = location and location.sourceSite or nil
    if not site then return "NO_CANONICAL_SITE" end
    local canonical = PNC.Communities.GetSite(site.id)
    if canonical and canonical.claimantKey then return "PLAYER_SITE_CLAIM" end
    if canonical and canonical.occupantCommunityID then
        return "SITE_ALREADY_OCCUPIED"
    end
    return nil
end

local function settlementDistance(location)
    local minimum = math.huge
    local sectorID = Sectors.IDForPosition(location.x, location.y)
    local ids = { sectorID }
    for _, id in ipairs(Sectors.NeighborIDs(sectorID)) do ids[#ids + 1] = id end
    for _, id in ipairs(ids) do
        for communityID in pairs(Sectors.CommunityIDs[id] or {}) do
            local community = PNC.Communities.Get(communityID)
            local home = community and community.home or nil
            if home then
                minimum = math.min(minimum,
                    Core.Distance(location.x, location.y, home.x, home.y))
            end
        end
    end
    return minimum
end

function Candidates.Evaluate(locationOrID, factionArchetypeID, resolved, now,
    generationID, seed)
    local location = type(locationOrID) == "table" and locationOrID
        or Locations.Get(locationOrID)
    now = tonumber(now) or Store.WorldAgeHours()
    resolved = resolved or PNC.PopulationSandbox.Resolve()
    Candidates.Metrics.evaluated = Candidates.Metrics.evaluated + 1
    local result = { locationId = location and location.id,
        eligible = false, score = 0, components = {} }
    local function reject(reason)
        result.reason = reason
        Candidates.Metrics.rejected = Candidates.Metrics.rejected + 1
        return result
    end
    if not location then return reject("LOCATION_NOT_FOUND") end
    if location.type == "SETTLEMENT" then return reject("ALREADY_SETTLEMENT") end
    local collision = siteCollision(location)
    if collision then return reject(collision) end
    local reservation = Candidates.Reservations[location.id]
    if reservation and reservation.expiresAt > now
        and reservation.generationId ~= generationID then
        return reject("SITE_RESERVED")
    end
    local history = populationData().siteHistory[location.id]
        or location.populationHistory
    if history and (tonumber(history.regenerationBlockedUntil) or 0) > now then
        return reject("DESTROYED_SITE_COOLDOWN")
    end
    local playerDistance = Sectors.PlayerDistance(location.x, location.y)
    if playerDistance < resolved.minPlayerGenerationDistance then
        return reject("PLAYER_TOO_CLOSE")
    end
    local spacing = settlementDistance(location)
    if spacing < Config.SETTLEMENT_HARD_MIN_DISTANCE then
        return reject("TOO_CLOSE_TO_EXISTING_SETTLEMENT")
    end
    local components = result.components
    components.siteQuality = location.sourceSite and 18 or 0
    components.food = math.min(18,
        (tonumber(location.resourcePotential.food) or 0) * 0.20)
    components.water = math.min(12,
        (tonumber(location.resourcePotential.water) or 0) * 0.15)
    components.defensibility = location.tags and location.tags.BUILDING and 10 or 3
    components.danger = -(tonumber(location.danger) or 0) * 0.20
    components.spacing = spacing >= Config.SETTLEMENT_PREFERRED_DISTANCE and 10
        or 10 * math.max(0, (spacing - Config.SETTLEMENT_HARD_MIN_DISTANCE)
            / math.max(1, Config.SETTLEMENT_PREFERRED_DISTANCE
                - Config.SETTLEMENT_HARD_MIN_DISTANCE))
    components.playerProximity = playerDistance < resolved.preferredPlayerGenerationDistance
        and -18 * (1 - (playerDistance - resolved.minPlayerGenerationDistance)
            / math.max(1, resolved.preferredPlayerGenerationDistance
                - resolved.minPlayerGenerationDistance)) or 0
    local preferences = Config.SETTLEMENT_PREFERENCES[factionArchetypeID] or {}
    local preference = 0
    for tag, weight in pairs(preferences) do
        if location.tags and location.tags[tag] then preference = preference + 8 * (weight - 1) end
    end
    components.factionPreference = preference
    components.siteHistory = history and history.formerSettlement and -8 or 0
    components.seedJitter = seed and (Sectors.Seed(
        tostring(seed) .. ":" .. tostring(location.id)) % 1000) / 1000 or 0
    for _, value in pairs(components) do result.score = result.score + value end
    result.eligible = true
    return result
end

function Candidates.Best(sectorID, factionArchetypeID, resolved, now, budget,
    seed, metaAttempted)
    Candidates.Discover(sectorID, budget)
    if Candidates.PoolCount(sectorID) == 0 and seed and not metaAttempted then
        Candidates.DiscoverMeta(sectorID, seed, "SETTLEMENT_FALLBACK")
        metaAttempted = true
    end
    local values = {}
    for locationID in pairs(Candidates.Pools[sectorID] or {}) do
        values[#values + 1] = locationID
    end
    table.sort(values)
    budget = math.max(1, math.floor(tonumber(budget)
        or Config.CANDIDATE_EVALUATION_BUDGET))
    local best, evaluated = nil, {}
    local start = math.max(1, math.min(#values,
        tonumber(Candidates.Cursors[sectorID]) or 1))
    for offset = 0, math.min(#values, budget) - 1 do
        local index = ((start - 1 + offset) % #values) + 1
        local result = Candidates.Evaluate(values[index], factionArchetypeID,
            resolved, now, nil, seed)
        evaluated[#evaluated + 1] = result
        if result.eligible and (not best or result.score > best.score
            or result.score == best.score
                and result.locationId < best.locationId) then best = result end
    end
    if #values > 0 then
        Candidates.Cursors[sectorID] = ((start - 1 + math.min(#values, budget))
            % #values) + 1
    end
    Candidates.LastEvaluations[sectorID] = evaluated
    if not best and seed and not metaAttempted then
        Candidates.DiscoverMeta(sectorID, seed, "SETTLEMENT_FALLBACK")
        return Candidates.Best(sectorID, factionArchetypeID, resolved, now,
            budget, seed, true)
    end
    return best, evaluated
end

function Candidates.PoolCount(sectorID)
    local total = 0
    for _ in pairs(Candidates.Pools[tostring(sectorID or "")] or {}) do
        total = total + 1
    end
    return total
end

function Candidates.ReservationSnapshot(now)
    now = tonumber(now) or Store.WorldAgeHours()
    local output = {}
    for _, value in pairs(Candidates.Reservations) do
        output[#output + 1] = { locationId = value.locationId,
            generationId = value.generationId,
            expiresAt = value.expiresAt,
            remainingHours = math.max(0, value.expiresAt - now) }
    end
    table.sort(output, function(a, b) return a.locationId < b.locationId end)
    return output
end

function Candidates.Reserve(locationID, generationID, now)
    now = tonumber(now) or Store.WorldAgeHours()
    local existing = Candidates.Reservations[locationID]
    if existing and existing.expiresAt > now
        and existing.generationId ~= generationID then return false, "site_reserved" end
    Candidates.Reservations[locationID] = { locationId = locationID,
        generationId = generationID,
        expiresAt = now + Config.RESERVATION_EXPIRY_HOURS }
    Candidates.Metrics.reservations = Candidates.Metrics.reservations + 1
    return true, "reserved"
end

function Candidates.HasReservation(locationID, generationID, now)
    local value = Candidates.Reservations[locationID]
    return value ~= nil and value.generationId == generationID
        and value.expiresAt > (tonumber(now) or Store.WorldAgeHours())
end

function Candidates.Release(locationID, generationID)
    local value = Candidates.Reservations[locationID]
    if not value or generationID and value.generationId ~= generationID then return false end
    Candidates.Reservations[locationID] = nil
    return true
end

function Candidates.Expire(now)
    now = tonumber(now) or Store.WorldAgeHours()
    local removed = 0
    for id, value in pairs(Candidates.Reservations) do
        if value.expiresAt <= now then Candidates.Reservations[id] = nil removed = removed + 1 end
    end
    return removed
end

return Candidates
