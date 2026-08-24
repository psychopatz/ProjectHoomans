if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PopulationDirector = PNC.PopulationDirector or {}
PNC.PopulationDirector.Internal =
    PNC.PopulationDirector.Internal or {}

local Director = PNC.PopulationDirector
local Config = PNC.DirectorConfig.Population
local Store = PNC.AbstractWorldStore
local Sectors = PNC.PopulationSectors
local Log = PNC.PopulationLog

function Director.OnGroupDestroyed(payload)
    payload = payload or {}
    local _, sectorID = Sectors.UnregisterGroup(payload.groupId)
    sectorID = sectorID or payload.sectorId
    if not sectorID then return false end
    if payload.homeCommunityId then
        Sectors.AddHistory("COMMUNITY_GROUP_DESTROYED", {
            groupId = payload.groupId, communityId = payload.homeCommunityId,
            sectorId = sectorID, reason = payload.reason }, Store.WorldAgeHours())
        return true
    end
    if payload.factionId and PNC.Factions and PNC.Factions.ClearMobileGroup then
        PNC.Factions.ClearMobileGroup(payload.factionId,
            "population_group_destroyed")
    end
    local state = Sectors.Ensure(sectorID)
    local resolved = Director.LastResolved or PNC.PopulationSandbox.Resolve()
    state.groupGenerationCooldownUntil = resolved.groupRegenerationEnabled
        and Store.WorldAgeHours() + Config.GROUP_REGENERATION_COOLDOWN_HOURS
            / math.max(0.25, resolved.groupRegenerationMultiplier)
        or 2147483647
    Store.Touch("population_group_destroyed")
    Sectors.AddHistory("GROUP_DESTROYED", { groupId = payload.groupId,
        sectorId = sectorID, reason = payload.reason }, Store.WorldAgeHours())
    Log.Info("GROUP_DESTROYED", { groupId = payload.groupId,
        sectorId = sectorID, reason = payload.reason,
        cooldownUntil = state.groupGenerationCooldownUntil })
    return true
end

function Director.OnSettlementDestroyed(community, reason, at)
    if not community then return false end
    if reason == "site_reservation_failed" or reason == "group_generation_failed"
        or reason == "population_generation_rollback" then return false end
    at = tonumber(at) or Store.WorldAgeHours()
    local _, sectorID = Sectors.UnregisterCommunity(community.id)
    local home = community.home or community.site and community.site.home
    sectorID = sectorID or home and Sectors.IDForPosition(home.x, home.y)
    if not sectorID then return false end
    local state = Sectors.Ensure(sectorID)
    local resolved = Director.LastResolved or PNC.PopulationSandbox.Resolve()
    state.settlementGenerationCooldownUntil = resolved.settlementRegenerationEnabled
        and at + Config.SETTLEMENT_REGENERATION_COOLDOWN_HOURS
            / math.max(0.25, resolved.settlementRegenerationMultiplier)
        or 2147483647
    for _, group in ipairs(PNC.AbstractGroups.List()) do
        if group.homeCommunityId == community.id then
            PNC.AbstractGroups.Remove(group.id, "home_settlement_destroyed")
        end
    end
    local siteID = community.siteID or community.site and community.site.id
    local location
    for _, candidate in ipairs(PNC.AbstractLocations.List()) do
        if candidate.sourceSite and candidate.sourceSite.id == siteID then
            location = candidate break
        end
    end
    if location then
        local history = { formerSettlement = true, destroyedAt = at,
            regenerationBlockedUntil = at + Config.SITE_REGENERATION_COOLDOWN_HOURS }
        Store.Registry.population.siteHistory[location.id] = history
        location.populationHistory = history
        location.type = "BUILDING"
        if location.tags then location.tags.SETTLEMENT = nil end
    end
    Store.Touch("population_settlement_destroyed")
    Sectors.AddHistory("SETTLEMENT_DESTROYED", { communityId = community.id,
        sectorId = sectorID, locationId = location and location.id,
        reason = reason }, at)
    Store.Emit("SETTLEMENT_DESTROYED", { communityId = community.id,
        sectorId = sectorID, locationId = location and location.id,
        reason = reason })
    Log.Info("SETTLEMENT_DESTROYED", { communityId = community.id,
        sectorId = sectorID, locationId = location and location.id,
        reason = reason,
        cooldownUntil = state.settlementGenerationCooldownUntil })
    return true
end
