if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Generator = PNC.GroupGenerator
local H = Generator.Internal
local Config = PNC.DirectorConfig.Population
local Sectors = PNC.PopulationSectors
local Locations = PNC.AbstractLocations
local Groups = PNC.AbstractGroups
local Store = PNC.HoomansWorldView
local HoomansPolicy = PNC.PopulationHoomansPolicy
local CoreWorld = PNC.CoreSurvivorWorldAdapter

local function commitCorePlan(plan, context, now)
    if not CoreWorld
        or type(CoreWorld.CanCommitGeneratedPlans) ~= "function"
        or not CoreWorld.CanCommitGeneratedPlans()
    then
        return nil, false
    end

    local group, reason = CoreWorld.CommitGeneratedGroupPlan(
        plan,
        "pnc_population_group_generation"
    )
    if not group then
        return { ok = false, reason = string.upper(tostring(reason)) }, true
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
    }, true
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
                "MOBILE_GROUP"
            ),
        })
        if not ok then
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
        PNC.MobileGroupDirector.GenerateForFaction(
            factionID,
            {
                siteSpec = location.sourceSite,
                groupSize = plan.memberCount,
                actorIDs = plan.memberActorIDs,
                groupID = plan.groupID,
                presenceMode = presence.presenceMode,
                allowLive = presence.allowLive,
                mobilePathMode = "random",
                worldAgeHours = now,
                generation = generation,
            }
        )
    if not ok then
        if createdFaction then
            H.RollbackFaction(factionID, now)
        end
        Generator.Metrics.failures =
            Generator.Metrics.failures + 1
        return {
            ok = false,
            reason = string.upper(tostring(createReason)),
        }
    end

    faction = PNC.Factions.Get(factionID)
    local group
    local groupReason
    group, groupReason = Groups.ImportMobileFaction(
        faction,
        { groupID = plan.groupID }
    )
    if not group then
        if createdFaction then
            H.RollbackFaction(factionID, now)
        else
            H.RollbackGeneratedMembers(
                factionID,
                result,
                now
            )
        end
        Generator.Metrics.failures =
            Generator.Metrics.failures + 1
        return {
            ok = false,
            reason = string.upper(tostring(groupReason)),
        }
    end

    group.groupType = plan.groupType
    group.mission = plan.initialMission
    group.generation = generation
    group.diagnostics = group.diagnostics or {}
    group.diagnostics.generation = generation
    Groups.MarkCombatProfileDirty(
        group,
        "population_generation"
    )
    Store.Touch("population_group_created")
    Sectors.RegisterGroup(group)
    Sectors.SetProvenance(group.id, generation)
    Sectors.SetProvenance(factionID, generation)
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
        Generator.Metrics.npcRecordsCreated
        + (tonumber(result and result.createdCount) or 0)

    Sectors.AddHistory("GROUP_CREATED", {
        sectorID = plan.sectorID,
        groupID = group.id,
        groupType = plan.groupType,
        generationID = plan.generationID,
        seed = plan.seed,
    }, now)
    Store.Emit("POPULATION_GROUP_CREATED", {
        groupId = group.id,
        generationID = plan.generationID,
        sectorID = plan.sectorID,
    })

    return {
        ok = true,
        reason = "GROUP_CREATED",
        group = group,
        createdNPCs = result and result.createdCount or 0,
        liveNPCs = result and result.liveCount or 0,
        abstractNPCs = result and result.abstractCount or 0,
    }
end
