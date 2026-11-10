if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Generator = PNC.GroupGenerator
local Config = PNC.DirectorConfig.Population
local Sectors = PNC.PopulationSectors
local Groups = PNC.AbstractGroups
local Store = PNC.HoomansWorldView
local CoreWorld = PNC.CoreSurvivorWorldAdapter

local function commitCorePlan(plan, context, now)
    if not CoreWorld
        or type(CoreWorld.CanCommitGeneratedPlans) ~= "function"
        or not CoreWorld.CanCommitGeneratedPlans()
    then
        -- SurvivorWorld is the only supported generation authority. Do not
        -- fall back to a second Hoomans-owned NPC/group pipeline.
        return {
            ok = false,
            reason = "CORE_GENERATION_REQUIRED",
        }
    end

    local group, reason = CoreWorld.CommitGeneratedGroupPlan(
        plan,
        "pnc_population_group_generation"
    )
    if not group then
        return {
            ok = false,
            reason = string.upper(tostring(reason)),
        }
    end

    local viewGroup = Groups.Get(plan.groupID) or group
    local generation = {
        source = plan.source,
        generationID = plan.generationID,
        sectorID = plan.sectorID,
        createdAt = now,
        seed = plan.seed,
    }
    local created = #(plan.memberActorIDs or {})

    Store.Touch("population_group_created_core")
    Sectors.RegisterGroup(viewGroup)
    Sectors.SetProvenance(viewGroup.id, generation)
    Sectors.SetProvenance(plan.factionID, generation)
    Sectors.MarkCommitted(plan.generationID)

    local state = Sectors.Ensure(plan.sectorID)
    local recovery = context.resolved
        and context.resolved.groupRegenerationMultiplier
        or 1
    state.groupGenerationCooldownUntil = now
        + Config.GROUP_INITIAL_COOLDOWN_HOURS
            / math.max(0.25, recovery)
    Store.Touch("population_group_cooldown")

    Generator.Metrics.successes =
        Generator.Metrics.successes + 1
    Generator.Metrics.npcRecordsCreated =
        Generator.Metrics.npcRecordsCreated + created
    Sectors.AddHistory("GROUP_CREATED", {
        sectorID = plan.sectorID,
        groupID = viewGroup.id,
        groupType = plan.groupType,
        generationID = plan.generationID,
        seed = plan.seed,
        authority = "PsychopatzCore",
    }, now)
    Store.Emit("POPULATION_GROUP_CREATED", {
        groupId = viewGroup.id,
        generationID = plan.generationID,
        sectorID = plan.sectorID,
    })

    return {
        ok = true,
        reason = "GROUP_CREATED",
        group = viewGroup,
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
