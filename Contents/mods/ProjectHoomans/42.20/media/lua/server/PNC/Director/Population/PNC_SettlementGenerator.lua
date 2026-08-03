-- Transaction coordinator for canonical faction/community settlement creation.

if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.SettlementGenerator = PNC.SettlementGenerator or {}

local Generator = PNC.SettlementGenerator
local Config = PNC.DirectorConfig.Population
local Sectors = PNC.PopulationSectors
local Candidates = PNC.SettlementCandidates
local Locations = PNC.AbstractLocations
local Store = PNC.AbstractWorldStore
local Identity = PNC.PopulationIdentity

Generator.Metrics = Generator.Metrics or { attempts = 0, successes = 0,
    failures = 0, npcRecordsCreated = 0, candidateEvaluations = 0 }

local function factionScore(faction)
    local weight = Config.SETTLEMENT_FACTION_WEIGHTS[faction.archetypeID]
    if not weight or faction.status ~= "active" or faction.ownerPlayerKey
        or PNC.Factions.IsMobileGroup(faction) then return nil end
    local communities = PNC.Communities.GetForFaction(faction.id) or {}
    local active = 0
    for _, community in ipairs(communities) do
        if community.status == "active" then active = active + 1 end
    end
    return weight / (1 + active)
end

function Generator.ChooseFaction(seed)
    local factionWeights = {}
    for _, faction in ipairs(PNC.Factions.List()) do
        local score = factionScore(faction)
        if score then
            factionWeights[faction.id] = score
        end
    end
    local factionID = Sectors.WeightedChoice(factionWeights,
        tostring(seed) .. ":EXISTING_FACTION")
    if factionID then
        local faction = PNC.Factions.Get(factionID)
        return factionID, faction and faction.archetypeID or "settler"
    end
    local archetype = Sectors.WeightedChoice(Config.SETTLEMENT_FACTION_WEIGHTS,
        tostring(seed) .. ":NEW_FACTION")
    return nil, archetype or "settler"
end

function Generator.BuildPlan(request, context)
    request, context = request or {}, context or {}
    local resolved = context.resolved or PNC.PopulationSandbox.Resolve()
    local generationID, serial = Sectors.NextGenerationID("SETTLEMENT")
    local seed = Sectors.GenerationSeed("SETTLEMENT", request.sectorId,
        serial, request.source)
    local factionID, archetype = Generator.ChooseFaction(seed)
    local evaluationBudget = request.source == "WORLD_POPULATION_BOOTSTRAP"
        and Config.STARTER_META_CANDIDATE_LIMIT
        or Config.CANDIDATE_EVALUATION_BUDGET
    local best, evaluated = Candidates.Best(request.sectorId, archetype,
        resolved, context.worldAge, evaluationBudget, seed)
    Generator.Metrics.candidateEvaluations = Generator.Metrics.candidateEvaluations
        + #(evaluated or {})
    if not best then return nil, "NO_ELIGIBLE_SITE", evaluated end
    local reserved, reason = Candidates.Reserve(best.locationId, generationID,
        context.worldAge)
    if not reserved then return nil, string.upper(tostring(reason)), evaluated end
    local range = Config.SETTLEMENT_SIZE_MAX - Config.SETTLEMENT_SIZE_MIN + 1
    local basePopulation = Config.SETTLEMENT_SIZE_MIN + seed % range
    local age = PNC.PopulationBudget.WorldAgeWeights(context.worldAge)
    local pressure = Sectors.Runtime[request.sectorId]
        and Sectors.Runtime[request.sectorId].settlementPressure or 1
    local populationScale = (0.85 + 0.15 * resolved.populationMultiplier)
        * (0.85 + 0.15 * age.settlements)
    local initialPopulation = math.floor(basePopulation * populationScale + 0.5)
        + (pressure < 0.5 and 1 or 0)
    initialPopulation = math.max(Config.SETTLEMENT_SIZE_MIN,
        math.min(Config.SETTLEMENT_SIZE_MAX, initialPopulation))
    return PNC.SettlementGenerationPlan.New({ generationId = generationID,
        sectorId = request.sectorId, source = request.source,
        locationId = best.locationId, factionId = factionID,
        factionArchetypeId = archetype,
        initialPopulation = initialPopulation,
        seed = seed, candidateScore = best }), "planned", evaluated
end

function Generator.Validate(plan, context)
    context = context or {}
    local resolved = context.resolved or PNC.PopulationSandbox.Resolve()
    if not plan or not plan.generationId then return false, "INVALID_PLAN" end
    if Sectors.IsCommitted(plan.generationId) then return false, "GENERATION_ID_DUPLICATE" end
    if not resolved.enabled or not resolved.settlementsEnabled then
        return false, "GENERATION_DISABLED"
    end
    local activeSettlements = 0
    for _, community in ipairs(PNC.Communities.List()) do
        if community.status == "active" and community.mode ~= "nomadic" then
            activeSettlements = activeSettlements + 1
        end
    end
    if activeSettlements >= Config.HARD_MAX_SETTLEMENTS then
        return false, "HARD_CAP_REACHED"
    end
    if Sectors.CountSettlements(plan.sectorId)
        >= Config.HARD_MAX_SETTLEMENTS_PER_SECTOR then
        return false, "SECTOR_HARD_CAP_REACHED"
    end
    local sector = Sectors.Get(plan.sectorId)
    if not sector or not sector.relevant then return false, "SECTOR_NOT_RELEVANT" end
    local now = tonumber(context.worldAge) or Store.WorldAgeHours()
    if now < (tonumber(sector.settlementGenerationCooldownUntil) or 0) then
        return false, "GENERATION_COOLDOWN"
    end
    local budget = PNC.PopulationBudget.Calculate(sector, context)
    if budget.settlements.deficit <= 0 then return false, "NO_DEFICIT" end
    if not Candidates.HasReservation(plan.locationId, plan.generationId, now) then
        return false, "RESERVATION_LOST"
    end
    local evaluation = Candidates.Evaluate(plan.locationId,
        plan.factionArchetypeId, resolved, now, plan.generationId)
    if not evaluation.eligible then
        return false, evaluation.reason
    end
    local location = Locations.Get(plan.locationId)
    if not location or Sectors.LivePlayerDistance(location.x, location.y)
        < resolved.minPlayerGenerationDistance then return false, "PLAYER_TOO_CLOSE" end
    if plan.factionId then
        local faction = PNC.Factions.Get(plan.factionId)
        if not faction or faction.status ~= "active" or faction.ownerPlayerKey
            or PNC.Factions.IsMobileGroup(faction) then return false, "INVALID_FACTION" end
    elseif not PNC.FactionArchetypes.Get(plan.factionArchetypeId) then
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
