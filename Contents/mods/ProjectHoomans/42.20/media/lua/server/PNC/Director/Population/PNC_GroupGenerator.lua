-- Plan/validate/commit pipeline for new roaming strategic groups.

if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.GroupGenerator = PNC.GroupGenerator or {}

local Generator = PNC.GroupGenerator
local Config = PNC.DirectorConfig.Population
local Sectors = PNC.PopulationSectors
local Locations = PNC.AbstractLocations
local Candidates = PNC.SettlementCandidates
local Groups = PNC.AbstractGroups
local Store = PNC.AbstractWorldStore
local Identity = PNC.PopulationIdentity

Generator.Metrics = Generator.Metrics or { attempts = 0, successes = 0,
    failures = 0, npcRecordsCreated = 0 }

local function currentComposition(sectorID)
    local counts = {}
    for groupID in pairs(Sectors.GroupIDs[sectorID] or {}) do
        local group = Groups.Get(groupID)
        if group then counts[group.groupType] = (counts[group.groupType] or 0) + 1 end
    end
    return counts
end

function Generator.ChooseArchetype(sectorID, worldAge, seed)
    local counts = currentComposition(sectorID)
    local age = PNC.PopulationBudget.WorldAgeWeights(worldAge)
    local weights = {}
    for archetype, weight in pairs(Config.GROUP_ARCHETYPE_WEIGHTS) do
        local ageWeight = archetype == "REFUGEE" and age.refugee or age.established
        weights[archetype] = math.max(0.01, weight * ageWeight)
            / (1 + (counts[archetype] or 0) * 1.75)
    end
    return Sectors.WeightedChoice(weights, seed) or "WANDERER"
end

local function chooseLocation(sectorID, resolved, seed)
    local center = Sectors.Center(sectorID)
    if not center then return nil, "invalid_sector" end
    Locations.DiscoverLoadedNear(center.x, center.y, center.z,
        Config.SECTOR_SIZE * 0.75, Config.CANDIDATE_EVALUATION_BUDGET)
    local function selectLocation()
        local best, bestScore
        for _, entry in ipairs(Locations.GetNearby(center.x, center.y,
            Config.SECTOR_SIZE * 0.75, Config.CANDIDATE_EVALUATION_BUDGET * 4)) do
            local location = entry.location
            if Sectors.IDForPosition(location.x, location.y) == sectorID
                and location.sourceSite then
                local distance = Sectors.PlayerDistance(location.x, location.y)
                if distance >= resolved.minPlayerGenerationDistance then
                    local preferred = resolved.preferredPlayerGenerationDistance
                    local score = distance >= preferred
                        and 1000 - math.abs(distance - preferred)
                        or distance - resolved.minPlayerGenerationDistance
                    score = score - (tonumber(location.danger) or 0) * 2
                    score = score + (Sectors.Seed(tostring(seed) .. ":GROUP_SITE:"
                        .. tostring(location.id)) % 2500) / 100
                    if not bestScore or score > bestScore
                        or score == bestScore and location.id < best.id then
                        best, bestScore = location, score
                    end
                end
            end
        end
        return best
    end
    local best = selectLocation()
    if not best and Candidates and Candidates.DiscoverMeta then
        Candidates.DiscoverMeta(sectorID, seed, "GROUP_FALLBACK")
        best = selectLocation()
    end
    return best, best and "selected" or "no_valid_location"
end

function Generator.BuildPlan(request, context)
    request, context = request or {}, context or {}
    local resolved = context.resolved or PNC.PopulationSandbox.Resolve()
    local generationID, serial = Sectors.NextGenerationID("GROUP")
    local seed = Sectors.GenerationSeed("GROUP", request.sectorId, serial,
        request.source)
    local archetype = Generator.ChooseArchetype(request.sectorId,
        context.worldAge, seed)
    local location, reason = chooseLocation(request.sectorId, resolved, seed)
    if not location then return nil, reason end
    local range = Config.GROUP_SIZE_MAX - Config.GROUP_SIZE_MIN + 1
    return PNC.GroupGenerationPlan.New({
        generationId = generationID, sectorId = request.sectorId,
        source = request.source, archetype = archetype,
        factionArchetypeId = Config.GROUP_FACTION_ARCHETYPES[archetype],
        locationId = location.id, initialMission = "SCAVENGE",
        memberCount = Config.GROUP_SIZE_MIN + seed % range, seed = seed,
    }), "planned"
end

function Generator.Validate(plan, context)
    context = context or {}
    local resolved = context.resolved or PNC.PopulationSandbox.Resolve()
    if not plan or not plan.generationId then return false, "INVALID_PLAN" end
    if Sectors.IsCommitted(plan.generationId) then return false, "GENERATION_ID_DUPLICATE" end
    if not resolved.enabled or not resolved.groupsEnabled then return false, "GENERATION_DISABLED" end
    if #Groups.List() >= Config.HARD_MAX_ABSTRACT_GROUPS then return false, "HARD_CAP_REACHED" end
    if Sectors.CountAllGroups(plan.sectorId) >= Config.HARD_MAX_GROUPS_PER_SECTOR then
        return false, "SECTOR_HARD_CAP_REACHED"
    end
    local sector = Sectors.Get(plan.sectorId)
    if not sector or not sector.relevant then return false, "SECTOR_NOT_RELEVANT" end
    local now = tonumber(context.worldAge) or Store.WorldAgeHours()
    if now < (tonumber(sector.groupGenerationCooldownUntil) or 0) then
        return false, "GENERATION_COOLDOWN"
    end
    local budget = PNC.PopulationBudget.Calculate(sector, context)
    if budget.groups.deficit <= 0 then return false, "NO_DEFICIT" end
    local location = Locations.Get(plan.locationId)
    if not location or not location.sourceSite then return false, "INVALID_LOCATION" end
    if Sectors.IDForPosition(location.x, location.y) ~= plan.sectorId then
        return false, "WRONG_SECTOR"
    end
    if Sectors.LivePlayerDistance(location.x, location.y)
        < resolved.minPlayerGenerationDistance then return false, "PLAYER_TOO_CLOSE" end
    if not PNC.FactionArchetypes.Get(plan.factionArchetypeId) then
        return false, "INVALID_FACTION"
    end
    return true, "VALID"
end

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

local function rollbackGeneratedMembers(factionID, result, at)
    for _, npcID in ipairs(result and result.npcIDs or {}) do
        if PNC.Factions.RemoveNPC then
            PNC.Factions.RemoveNPC(factionID, npcID,
                "population_generation_rollback", at)
        end
        if PNC.API and PNC.API.Despawn then PNC.API.Despawn(npcID) end
    end
    if PNC.Factions.ClearMobileGroup then
        PNC.Factions.ClearMobileGroup(factionID,
            "population_generation_rollback")
    end
end

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
        if createdFaction then rollbackFaction(factionID, now) end
        Generator.Metrics.failures = Generator.Metrics.failures + 1
        return { ok = false, reason = string.upper(tostring(createReason)) }
    end
    local faction = PNC.Factions.Get(factionID)
    local group, groupReason = Groups.ImportMobileFaction(faction)
    if not group then
        if createdFaction then rollbackFaction(factionID, now)
        else rollbackGeneratedMembers(factionID, result, now) end
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

return Generator
