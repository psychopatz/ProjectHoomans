if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SettlementGenerationPlan = PNC.SettlementGenerationPlan or {}

function PNC.SettlementGenerationPlan.New(spec)
    spec = type(spec) == "table" and spec or {}
    return {
        generationId = spec.generationId, sectorId = spec.sectorId,
        source = spec.source or "WORLD_POPULATION_DIRECTOR",
        locationId = spec.locationId, factionId = spec.factionId,
        factionArchetypeId = spec.factionArchetypeId or "settler",
        initialPopulation = math.floor(tonumber(spec.initialPopulation) or 0),
        seed = math.floor(tonumber(spec.seed) or 0),
        candidateScore = spec.candidateScore,
    }
end

return PNC.SettlementGenerationPlan
