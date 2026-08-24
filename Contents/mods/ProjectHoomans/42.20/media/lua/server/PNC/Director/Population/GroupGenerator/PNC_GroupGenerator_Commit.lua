if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Generator = PNC.GroupGenerator
local H = Generator.Internal
local Config = PNC.DirectorConfig.Population
local Sectors = PNC.PopulationSectors
local Locations = PNC.AbstractLocations
local Groups = PNC.AbstractGroups
local Store = PNC.AbstractWorldStore
local Identity = PNC.PopulationIdentity

function Generator.Commit(plan, context)
    Generator.Metrics.attempts = Generator.Metrics.attempts + 1
    context = context or {}
    local valid, reason = Generator.Validate(plan, context)
    if not valid then
        Generator.Metrics.failures = Generator.Metrics.failures + 1
        return { ok = false, reason = reason }
    end
    local now = tonumber(context.worldAge) or Store.WorldAgeHours()
    local location = Locations.Get(plan.locationId)
    local factionID = plan.factionId
    local createdFaction = false
    if not factionID then
        local ok, createReason, faction = PNC.Factions.Create({
            name = Identity.FactionName(plan.factionArchetypeId, plan.seed),
            archetypeID = plan.factionArchetypeId, createdAt = now,
            tags = Identity.FactionTags(plan.factionArchetypeId,
                "MOBILE_GROUP"),
        })
        if not ok then
            Generator.Metrics.failures = Generator.Metrics.failures + 1
            return { ok = false, reason = string.upper(tostring(createReason)) }
        end
        factionID, createdFaction = faction.id, true
    end
    local generation = { source = plan.source, generationId = plan.generationId,
        sectorId = plan.sectorId, createdAt = now, seed = plan.seed }
    local presence = Identity.PresenceSpec()
    local ok, createReason, result = PNC.MobileGroupDirector.GenerateForFaction(
        factionID, { siteSpec = location.sourceSite,
            groupSize = plan.memberCount, presenceMode = presence.presenceMode,
            allowLive = presence.allowLive, mobilePathMode = "random",
            worldAgeHours = now, generation = generation })
    if not ok then
        if createdFaction then H.RollbackFaction(factionID, now) end
        Generator.Metrics.failures = Generator.Metrics.failures + 1
        return { ok = false, reason = string.upper(tostring(createReason)) }
    end
    local faction = PNC.Factions.Get(factionID)
    local group, groupReason = Groups.ImportMobileFaction(faction)
    if not group then
        if createdFaction then H.RollbackFaction(factionID, now)
        else H.RollbackGeneratedMembers(factionID, result, now) end
        Generator.Metrics.failures = Generator.Metrics.failures + 1
        return { ok = false, reason = string.upper(tostring(groupReason)) }
    end
    group.groupType = plan.archetype
    group.mission = plan.initialMission
    group.generation = generation
    group.diagnostics = group.diagnostics or {}
    group.diagnostics.generation = generation
    Groups.MarkCombatProfileDirty(group, "population_generation")
    Store.Touch("population_group_created")
    Sectors.RegisterGroup(group)
    Sectors.SetProvenance(group.id, generation)
    Sectors.SetProvenance(factionID, generation)
    Sectors.MarkCommitted(plan.generationId)
    local state = Sectors.Ensure(plan.sectorId)
    local recovery = context.resolved and context.resolved.groupRegenerationMultiplier or 1
    state.groupGenerationCooldownUntil = now
        + Config.GROUP_INITIAL_COOLDOWN_HOURS / math.max(0.25, recovery)
    Store.Touch("population_group_cooldown")
    Generator.Metrics.successes = Generator.Metrics.successes + 1
    Generator.Metrics.npcRecordsCreated = Generator.Metrics.npcRecordsCreated
        + (tonumber(result and result.createdCount) or 0)
    Sectors.AddHistory("GROUP_CREATED", { sectorId = plan.sectorId,
        groupId = group.id, archetype = plan.archetype,
        generationId = plan.generationId, seed = plan.seed }, now)
    Store.Emit("POPULATION_GROUP_CREATED", { groupId = group.id,
        generationId = plan.generationId, sectorId = plan.sectorId })
    return { ok = true, reason = "GROUP_CREATED", group = group,
        createdNPCs = result and result.createdCount or 0,
        liveNPCs = result and result.liveCount or 0,
        abstractNPCs = result and result.abstractCount or 0 }
end
