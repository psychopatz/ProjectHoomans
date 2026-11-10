if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Generator = PNC.SettlementGenerator
local Config = PNC.DirectorConfig.Population
local Sectors = PNC.PopulationSectors
local Candidates = PNC.SettlementCandidates
local Locations = PNC.AbstractLocations
local Store = PNC.HoomansWorldView
local CoreWorld = PNC.CoreSurvivorWorldAdapter

local function commitCorePlan(plan, context, now)
    if not CoreWorld
        or type(CoreWorld.CanCommitGeneratedPlans) ~= "function"
        or not CoreWorld.CanCommitGeneratedPlans()
    then
        -- SurvivorWorld is the only supported generation authority. Do not
        -- fall back to a second Hoomans-owned NPC/community pipeline.
        return {
            ok = false,
            reason = "CORE_GENERATION_REQUIRED",
        }
    end

    local community, reason = CoreWorld.CommitGeneratedCommunityPlan(
        plan,
        "pnc_population_community_generation"
    )
    if not community then
        Candidates.Release(plan.locationID, plan.generationID)
        return {
            ok = false,
            reason = string.upper(tostring(reason)),
        }
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
    }
end

function Generator.Commit(plan, context)
    Generator.Metrics.attempts =
        Generator.Metrics.attempts + 1
    context = context or {}

    local valid, reason = Generator.Validate(plan, context)
    if not valid then
        if plan then
            Candidates.Release(plan.locationID, plan.generationID)
        end
        Generator.Metrics.failures =
            Generator.Metrics.failures + 1
        return { ok = false, reason = reason }
    end

    local now = tonumber(context.worldAge)
        or Store.WorldAgeHours()
    local result = commitCorePlan(plan, context, now)
    if result.ok ~= true then
        Generator.Metrics.failures =
            Generator.Metrics.failures + 1
    end
    return result
end

return Generator
