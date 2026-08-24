if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Generator = PNC.SettlementGenerator
local Config = PNC.DirectorConfig.Population
local Sectors = PNC.PopulationSectors
local Candidates = PNC.SettlementCandidates
local Locations = PNC.AbstractLocations
local Store = PNC.AbstractWorldStore
local Identity = PNC.PopulationIdentity

local function rollbackFaction(factionID, at)
    local faction = factionID and PNC.Factions.Get(factionID) or nil
    for npcID in pairs(faction and faction.memberIDs or {}) do
        if PNC.Factions.RemoveNPC then
            PNC.Factions.RemoveNPC(factionID, npcID,
                "population_generation_rollback", at)
        end
        if PNC.API and PNC.API.Despawn then PNC.API.Despawn(npcID) end
    end
    if factionID and PNC.Factions.Destroy then
        PNC.Factions.Destroy(factionID, "population_generation_rollback", at)
    end
end

function Generator.Commit(plan, context)
    Generator.Metrics.attempts = Generator.Metrics.attempts + 1
    context = context or {}
    local valid, reason = Generator.Validate(plan, context)
    if not valid then
        if plan then Candidates.Release(plan.locationId, plan.generationId) end
        Generator.Metrics.failures = Generator.Metrics.failures + 1
        return { ok = false, reason = reason }
    end
    local now = tonumber(context.worldAge) or Store.WorldAgeHours()
    local location = Locations.Get(plan.locationId)
    local factionID, createdFaction = plan.factionId, false
    if not factionID then
        local ok, createReason, faction = PNC.Factions.Create({
            name = Identity.FactionName(plan.factionArchetypeId, plan.seed),
            archetypeID = plan.factionArchetypeId, createdAt = now,
            tags = Identity.FactionTags(plan.factionArchetypeId, "SETTLEMENT"),
        })
        if not ok then
            Candidates.Release(plan.locationId, plan.generationId)
            Generator.Metrics.failures = Generator.Metrics.failures + 1
            return { ok = false, reason = string.upper(tostring(createReason)) }
        end
        factionID, createdFaction = faction.id, true
    end
    local generation = { source = plan.source, generationId = plan.generationId,
        sectorId = plan.sectorId, createdAt = now, seed = plan.seed }
    local presence = Identity.PresenceSpec()
    local ok, createReason, result = PNC.CommunityDirector.GenerateForFaction(
        factionID, { useExisting = false, siteSpec = location.sourceSite,
            groupSize = plan.initialPopulation,
            presenceMode = presence.presenceMode,
            allowLive = presence.allowLive,
            worldAgeHours = now, generation = generation,
            communityMode = "settled" })
    if not ok then
        if createdFaction then rollbackFaction(factionID, now) end
        Candidates.Release(plan.locationId, plan.generationId)
        Generator.Metrics.failures = Generator.Metrics.failures + 1
        return { ok = false, reason = string.upper(tostring(createReason)) }
    end
    local community = result and PNC.Communities.Get(result.communityID) or nil
    if not community then
        if result and result.communityID and PNC.Communities.Destroy then
            PNC.Communities.Destroy(result.communityID,
                "population_generation_rollback", now)
        end
        for _, npcID in ipairs(result and result.npcIDs or {}) do
            if PNC.Factions.RemoveNPC then
                PNC.Factions.RemoveNPC(factionID, npcID,
                    "population_generation_rollback", now)
            end
            if PNC.API and PNC.API.Despawn then PNC.API.Despawn(npcID) end
        end
        if createdFaction then rollbackFaction(factionID, now) end
        Candidates.Release(plan.locationId, plan.generationId)
        Generator.Metrics.failures = Generator.Metrics.failures + 1
        return { ok = false, reason = "COMMUNITY_API_FAILURE" }
    end
    location.type = "SETTLEMENT"
    location.tags = location.tags or {}
    location.tags.SETTLEMENT, location.tags.SAFE = true, true
    location.sourceSite = community.site or location.sourceSite
    location.revision = (tonumber(location.revision) or 0) + 1
    Store.Touch("population_settlement_location")
    Sectors.RegisterCommunity(community)
    Sectors.SetProvenance(community.id, generation)
    Sectors.SetProvenance(factionID, generation)
    Sectors.SetProvenance(location.id, generation)
    Sectors.MarkCommitted(plan.generationId)
    local state = Sectors.Ensure(plan.sectorId)
    local recovery = context.resolved
        and context.resolved.settlementRegenerationMultiplier or 1
    state.settlementGenerationCooldownUntil = now
        + Config.SETTLEMENT_INITIAL_COOLDOWN_HOURS / math.max(0.25, recovery)
    Store.Touch("population_settlement_cooldown")
    Candidates.Release(plan.locationId, plan.generationId)
    Generator.Metrics.successes = Generator.Metrics.successes + 1
    Generator.Metrics.npcRecordsCreated = Generator.Metrics.npcRecordsCreated
        + (tonumber(result.createdCount) or 0)
    Sectors.AddHistory("SETTLEMENT_CREATED", { sectorId = plan.sectorId,
        communityId = community.id, factionId = factionID,
        locationId = location.id, population = result.createdCount,
        generationId = plan.generationId, seed = plan.seed }, now)
    Store.Emit("POPULATION_SETTLEMENT_CREATED", { communityId = community.id,
        generationId = plan.generationId, sectorId = plan.sectorId })
    Store.Emit("SETTLEMENT_CREATED", { communityId = community.id,
        generationId = plan.generationId, sectorId = plan.sectorId })
    return { ok = true, reason = "SETTLEMENT_CREATED", community = community,
        createdNPCs = result.createdCount or 0,
        liveNPCs = result.liveCount or 0,
        abstractNPCs = result.abstractCount or 0 }
end

return Generator

