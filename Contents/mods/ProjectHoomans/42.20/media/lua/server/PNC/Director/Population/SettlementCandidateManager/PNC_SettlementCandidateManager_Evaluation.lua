if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SettlementCandidates = PNC.SettlementCandidates or {}
PNC.SettlementCandidateManagerInternal =
    PNC.SettlementCandidateManagerInternal or {}

local Candidates = PNC.SettlementCandidates
local H = PNC.SettlementCandidateManagerInternal
local Config = PNC.DirectorConfig.Population
local Sectors = PNC.PopulationSectors
local Locations = PNC.AbstractLocations
local Store = PNC.AbstractWorldStore
local Core = PNC.Core
local Log = PNC.PopulationLog

function H.SiteCollision(location)
    local site = location and location.sourceSite or nil
    if not site then return "NO_CANONICAL_SITE" end
    local canonical = PNC.Communities.GetSite(site.id)
    if canonical and canonical.claimantKey then return "PLAYER_SITE_CLAIM" end
    if canonical and canonical.occupantCommunityID then
        return "SITE_ALREADY_OCCUPIED"
    end
    return nil
end

function H.SettlementDistance(location)
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
    local collision = H.SiteCollision(location)
    if collision then return reject(collision) end
    local reservation = Candidates.Reservations[location.id]
    if reservation and reservation.expiresAt > now
        and reservation.generationId ~= generationID then
        return reject("SITE_RESERVED")
    end
    local history = H.PopulationData().siteHistory[location.id]
        or location.populationHistory
    if history and (tonumber(history.regenerationBlockedUntil) or 0) > now then
        return reject("DESTROYED_SITE_COOLDOWN")
    end
    local playerDistance = Sectors.PlayerDistance(location.x, location.y)
    if playerDistance < resolved.minPlayerGenerationDistance then
        return reject("PLAYER_TOO_CLOSE")
    end
    local spacing = H.SettlementDistance(location)
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

return Candidates

