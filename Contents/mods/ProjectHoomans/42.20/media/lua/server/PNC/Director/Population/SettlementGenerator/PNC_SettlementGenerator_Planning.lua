if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Generator = PNC.SettlementGenerator
local Config = PNC.DirectorConfig.Population
local Sectors = PNC.PopulationSectors
local Candidates = PNC.SettlementCandidates
local Locations = PNC.AbstractLocations
local Generation = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldGeneration"

function Generator.BuildPlan(request, context)
    request, context = request or {}, context or {}
    local resolved = context.resolved
        or PNC.PopulationSandbox.Resolve()
    local generationID, serial =
        Sectors.NextGenerationID("COMMUNITY")
    local seed = Sectors.GenerationSeed(
        "COMMUNITY",
        request.sectorId,
        serial,
        request.source
    )
    local factionID, archetype =
        Generator.ChooseFaction(seed)

    local evaluationBudget =
        request.source == "WORLD_POPULATION_BOOTSTRAP"
            and Config.STARTER_META_CANDIDATE_LIMIT
            or Config.CANDIDATE_EVALUATION_BUDGET
    local best
    local evaluated
    best, evaluated = Candidates.Best(
        request.sectorId,
        archetype,
        resolved,
        context.worldAge,
        evaluationBudget,
        seed
    )
    Generator.Metrics.candidateEvaluations =
        Generator.Metrics.candidateEvaluations
        + #(evaluated or {})
    if not best then
        return nil, "NO_ELIGIBLE_SITE", evaluated
    end

    local reserved, reason = Candidates.Reserve(
        best.locationId,
        generationID,
        context.worldAge
    )
    if not reserved then
        return nil, string.upper(tostring(reason)), evaluated
    end

    local range = Config.SETTLEMENT_SIZE_MAX
        - Config.SETTLEMENT_SIZE_MIN + 1
    local basePopulation =
        Config.SETTLEMENT_SIZE_MIN + seed % range
    local age = PNC.PopulationBudget.WorldAgeWeights(
        context.worldAge
    )
    local pressure = Sectors.Runtime[request.sectorId]
        and Sectors.Runtime[request.sectorId]
            .settlementPressure
        or 1
    local populationScale =
        (0.85 + 0.15 * resolved.populationMultiplier)
        * (0.85 + 0.15 * age.settlements)
    local initialPopulation = math.floor(
        basePopulation * populationScale + 0.5
    ) + (pressure < 0.5 and 1 or 0)
    initialPopulation = math.max(
        Config.SETTLEMENT_SIZE_MIN,
        math.min(
            Config.SETTLEMENT_SIZE_MAX,
            initialPopulation
        )
    )

    local location = Locations.Get(best.locationId)
    if not location then
        Candidates.Release(best.locationId, generationID)
        return nil, "INVALID_LOCATION", evaluated
    end
    local faction = factionID
        and PNC.Factions.Get(factionID) or nil
    local worldSeed = Sectors.WorldSeed()
    local plan
    plan, reason = Generation.BuildCommunityPlan({
        worldSeed = worldSeed,
        sectorID = request.sectorId,
        serial = serial,
        source = request.source,
        factionID = factionID,
        factionName = faction and faction.name or nil,
        factionArchetypeID = archetype,
        locationID = location.id,
        location = {
            x = location.x,
            y = location.y,
            z = location.z,
        },
        locationKind = location.type,
        initialPopulation = initialPopulation,
        createdAt = context.worldAge,
    })
    if not plan then
        Candidates.Release(best.locationId, generationID)
        return nil, reason, evaluated
    end
    if plan.generationID ~= generationID then
        Candidates.Release(best.locationId, generationID)
        return nil, "core_generation_id_mismatch", evaluated
    end
    return plan, "planned", evaluated
end

return Generator
