if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Generator = PNC.SettlementGenerator
local Config = PNC.DirectorConfig.Population
local Sectors = PNC.PopulationSectors
local Candidates = PNC.SettlementCandidates
local Locations = PNC.AbstractLocations
local Store = PNC.HoomansWorldView
local HoomansPolicy = PNC.PopulationHoomansPolicy
local CoreWorld = PNC.CoreSurvivorWorldAdapter

local function rollbackFaction(factionID, at)
    local faction = factionID
        and PNC.Factions.Get(factionID) or nil
    for npcID in pairs(
        faction and faction.memberIDs or {}
    ) do
        if PNC.Factions.RemoveNPC then
            PNC.Factions.RemoveNPC(
                factionID,
                npcID,
                "population_generation_rollback",
                at
            )
        end
        if PNC.API and PNC.API.Despawn then
            PNC.API.Despawn(npcID)
        end
    end
    if factionID and PNC.Factions.Destroy then
        PNC.Factions.Destroy(
            factionID,
            "population_generation_rollback",
            at
        )
    end
end

local function commitCorePlan(plan, context, now)
    if not CoreWorld
        or type(CoreWorld.CanCommitGeneratedPlans) ~= "function"
        or not CoreWorld.CanCommitGeneratedPlans()
    then
        return nil, false
    end

    local community, reason = CoreWorld.CommitGeneratedCommunityPlan(
        plan,
        "pnc_population_community_generation"
    )
    if not community then
        Candidates.Release(plan.locationID, plan.generationID)
        return { ok = false, reason = string.upper(tostring(reason)) }, true
    end
    local viewCommunity = PNC.Communities.Get(plan.communityID)
        or community
    local location = Locations.Get(plan.locationID)
    if location then
        location.type = "SETTLEMENT"
        location.tags = location.tags or {}
        location.tags.SETTLEMENT = true
        location.tags.SAFE = true
        location.revision = (tonumber(location.revision) or 0) + 1
        Store.Touch("population_settlement_location_core")
    end

    local generation = {
        source = plan.source,
        generationID = plan.generationID,
        sectorID = plan.sectorID,
        createdAt = now,
        seed = plan.seed,
    }
    local created = #(plan.memberActorIDs or {})
    Store.Touch("population_settlement_created_core")
    Sectors.RegisterCommunity(viewCommunity)
    Sectors.SetProvenance(viewCommunity.id, generation)
    Sectors.SetProvenance(plan.factionID, generation)
    Sectors.SetProvenance(plan.locationID, generation)
    Sectors.MarkCommitted(plan.generationID)

    local state = Sectors.Ensure(plan.sectorID)
    local recovery = context.resolved
        and context.resolved.settlementRegenerationMultiplier
        or 1
    state.settlementGenerationCooldownUntil = now
        + Config.SETTLEMENT_INITIAL_COOLDOWN_HOURS
            / math.max(0.25, recovery)
    Store.Touch("population_settlement_cooldown")
    Candidates.Release(plan.locationID, plan.generationID)

    Generator.Metrics.successes =
        Generator.Metrics.successes + 1
    Generator.Metrics.npcRecordsCreated =
        Generator.Metrics.npcRecordsCreated + created
    Sectors.AddHistory("SETTLEMENT_CREATED", {
        sectorID = plan.sectorID,
        communityID = viewCommunity.id,
        factionID = plan.factionID,
        locationID = plan.locationID,
        population = created,
        generationID = plan.generationID,
        seed = plan.seed,
        authority = "PsychopatzCore",
    }, now)
    Store.Emit("POPULATION_SETTLEMENT_CREATED", {
        communityId = viewCommunity.id,
        generationID = plan.generationID,
        sectorID = plan.sectorID,
    })
    Store.Emit("SETTLEMENT_CREATED", {
        communityId = viewCommunity.id,
        generationID = plan.generationID,
        sectorID = plan.sectorID,
    })
    return {
        ok = true,
        reason = "SETTLEMENT_CREATED",
        community = viewCommunity,
        createdNPCs = created,
        liveNPCs = 0,
        abstractNPCs = created,
        authority = "PsychopatzCore",
    }, true
end

function Generator.Commit(plan, context)
    Generator.Metrics.attempts =
        Generator.Metrics.attempts + 1
    context = context or {}
    local valid, reason = Generator.Validate(plan, context)
    if not valid then
        if plan then
            Candidates.Release(
                plan.locationID,
                plan.generationID
            )
        end
        Generator.Metrics.failures =
            Generator.Metrics.failures + 1
        return { ok = false, reason = reason }
    end

    local now = tonumber(context.worldAge)
        or Store.WorldAgeHours()
    local coreResult, coreHandled = commitCorePlan(plan, context, now)
    if coreHandled then return coreResult end
    local location = Locations.Get(plan.locationID)
    local factionID = plan.factionID
    local createdFaction = false
    local faction = PNC.Factions.Get(factionID)

    if not faction then
        local factionPlan = plan.factionPlan or {}
        local ok
        local createReason
        ok, createReason, faction = PNC.Factions.Create({
            id = factionID,
            name = factionPlan.name,
            archetypeID = plan.factionArchetypeID,
            createdAt = now,
            tags = HoomansPolicy.FactionTags(
                plan.factionArchetypeID,
                "SETTLEMENT"
            ),
        })
        if not ok then
            Candidates.Release(
                plan.locationID,
                plan.generationID
            )
            Generator.Metrics.failures =
                Generator.Metrics.failures + 1
            return {
                ok = false,
                reason = string.upper(
                    tostring(createReason)
                ),
            }
        end
        createdFaction = true
    end

    local generation = {
        source = plan.source,
        generationID = plan.generationID,
        sectorID = plan.sectorID,
        createdAt = now,
        seed = plan.seed,
    }
    local presence = HoomansPolicy.PresenceSpec()
    local ok
    local createReason
    local result
    ok, createReason, result =
        PNC.CommunityDirector.GenerateForFaction(
            factionID,
            {
                useExisting = false,
                communityID = plan.communityID,
                communityName = plan.communityName,
                siteSpec = location.sourceSite,
                groupSize = plan.initialPopulation,
                actorIDs = plan.memberActorIDs,
                presenceMode = presence.presenceMode,
                allowLive = presence.allowLive,
                worldAgeHours = now,
                generation = generation,
                communityMode = "settled",
            }
        )
    if not ok then
        if createdFaction then
            rollbackFaction(factionID, now)
        end
        Candidates.Release(
            plan.locationID,
            plan.generationID
        )
        Generator.Metrics.failures =
            Generator.Metrics.failures + 1
        return {
            ok = false,
            reason = string.upper(tostring(createReason)),
        }
    end

    local community = result
        and PNC.Communities.Get(result.communityID)
        or nil
    if not community then
        if result and result.communityID
            and PNC.Communities.Destroy
        then
            PNC.Communities.Destroy(
                result.communityID,
                "population_generation_rollback",
                now
            )
        end
        for _, npcID in ipairs(
            result and result.npcIDs or {}
        ) do
            if PNC.Factions.RemoveNPC then
                PNC.Factions.RemoveNPC(
                    factionID,
                    npcID,
                    "population_generation_rollback",
                    now
                )
            end
            if PNC.API and PNC.API.Despawn then
                PNC.API.Despawn(npcID)
            end
        end
        if createdFaction then
            rollbackFaction(factionID, now)
        end
        Candidates.Release(
            plan.locationID,
            plan.generationID
        )
        Generator.Metrics.failures =
            Generator.Metrics.failures + 1
        return {
            ok = false,
            reason = "COMMUNITY_API_FAILURE",
        }
    end

    location.type = "SETTLEMENT"
    location.tags = location.tags or {}
    location.tags.SETTLEMENT = true
    location.tags.SAFE = true
    location.sourceSite =
        community.site or location.sourceSite
    location.revision =
        (tonumber(location.revision) or 0) + 1
    Store.Touch("population_settlement_location")

    Sectors.RegisterCommunity(community)
    Sectors.SetProvenance(community.id, generation)
    Sectors.SetProvenance(factionID, generation)
    Sectors.SetProvenance(location.id, generation)
    Sectors.MarkCommitted(plan.generationID)

    local state = Sectors.Ensure(plan.sectorID)
    local recovery = context.resolved
        and context.resolved
            .settlementRegenerationMultiplier
        or 1
    state.settlementGenerationCooldownUntil = now
        + Config.SETTLEMENT_INITIAL_COOLDOWN_HOURS
            / math.max(0.25, recovery)
    Store.Touch("population_settlement_cooldown")
    Candidates.Release(
        plan.locationID,
        plan.generationID
    )

    Generator.Metrics.successes =
        Generator.Metrics.successes + 1
    Generator.Metrics.npcRecordsCreated =
        Generator.Metrics.npcRecordsCreated
        + (tonumber(result.createdCount) or 0)

    Sectors.AddHistory("SETTLEMENT_CREATED", {
        sectorID = plan.sectorID,
        communityID = community.id,
        factionID = factionID,
        locationID = location.id,
        population = result.createdCount,
        generationID = plan.generationID,
        seed = plan.seed,
    }, now)
    Store.Emit("POPULATION_SETTLEMENT_CREATED", {
        communityId = community.id,
        generationID = plan.generationID,
        sectorID = plan.sectorID,
    })
    Store.Emit("SETTLEMENT_CREATED", {
        communityId = community.id,
        generationID = plan.generationID,
        sectorID = plan.sectorID,
    })

    return {
        ok = true,
        reason = "SETTLEMENT_CREATED",
        community = community,
        createdNPCs = result.createdCount or 0,
        liveNPCs = result.liveCount or 0,
        abstractNPCs = result.abstractCount or 0,
    }
end

return Generator
