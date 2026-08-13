if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.GroupGenerationPlan = PNC.GroupGenerationPlan or {}

function PNC.GroupGenerationPlan.New(spec)
    spec = type(spec) == "table" and spec or {}
    return {
        generationId = spec.generationId, sectorId = spec.sectorId,
        source = spec.source or "WORLD_POPULATION_DIRECTOR",
        archetype = spec.archetype, factionId = spec.factionId,
        factionArchetypeId = spec.factionArchetypeId,
        locationId = spec.locationId, initialMission = spec.initialMission or "SCAVENGE",
        memberCount = math.floor(tonumber(spec.memberCount) or 0),
        seed = math.floor(tonumber(spec.seed) or 0),
    }
end

return PNC.GroupGenerationPlan
