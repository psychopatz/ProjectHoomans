if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Generator = PNC.SettlementGenerator
local Config = PNC.DirectorConfig.Population
local Sectors = PNC.PopulationSectors
local Candidates = PNC.SettlementCandidates
local Locations = PNC.AbstractLocations
local Store = PNC.AbstractWorldStore
local Identity = PNC.PopulationIdentity

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

return Generator

