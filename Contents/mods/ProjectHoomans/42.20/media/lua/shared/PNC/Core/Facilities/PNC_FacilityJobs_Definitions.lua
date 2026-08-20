PNC = PNC or {}
PNC.FacilityJobDefinitions = PNC.FacilityJobDefinitions or {}

local Definitions = PNC.FacilityJobDefinitions
Definitions.ByCapability = Definitions.ByCapability or {}

function Definitions.Register(capability, definition)
    capability = tostring(capability or "")
    if capability == "" or type(definition) ~= "table"
        or type(definition.sceneId) ~= "string"
    then
        return false, "INVALID_FACILITY_JOB"
    end
    definition.capability = capability
    Definitions.ByCapability[capability] = definition
    return true, definition
end

function Definitions.Get(capability)
    return Definitions.ByCapability[tostring(capability or "")]
end

Definitions.Register("sleep", {
    activeJob = "Sleep",
    sceneId = "facility.sleep.floor",
    role = "sleep.bed",
    needEffect = "need",
    needType = "fatigue",
    recoveryPerGameHour = 0.45,
    completionThreshold = 0.12,
    arrivalDistance = 1.15,
    activityLabel = "SLEEPING",
})

Definitions.Register("farm.work", {
    activeJob = "FarmWork",
    sceneId = "facility.farm.work",
    role = "farm.field",
    arrivalDistance = 0.8,
    activityLabel = "FARMING",
})

Definitions.Register("living", {
    activeJob = "LivingRoom",
    sceneId = "facility.living.sit",
    role = "living.chair",
    arrivalDistance = 0.85,
    activityLabel = "SITTING",
})

Definitions.Register("recreation", {
    activeJob = "Recreation",
    sceneId = "facility.living.sit",
    role = "living.chair",
    arrivalDistance = 0.85,
    activityLabel = "RECREATING",
    needEffect = "recreation",
    boredomReliefPerGameHour = 36,
    stressReliefPerGameHour = 0.08,
    completionThreshold = 15,
})

Definitions.Register("food.dine", {
    activeJob = "Dining",
    sceneId = "facility.living.sit",
    role = "dining.table",
    arrivalDistance = 0.85,
    activityLabel = "EATING",
    needEffect = "primitive",
    primitiveNeed = "hunger",
    effectDelayMs = 1200,
})

Definitions.Register("health.recover", {
    activeJob = "HospitalRecovery",
    sceneId = "facility.sleep.floor",
    role = "health.bed",
    arrivalDistance = 1.15,
    activityLabel = "RECOVERING",
    needEffect = "health",
    recoveryPerGameHour = 0.12,
    completionThreshold = 0.98,
})

Definitions.Register("water.drink", {
    activeJob = "Drink",
    sceneId = "facility.water.drink",
    role = "water.spigot",
    arrivalDistance = 0.85,
    activityLabel = "DRINKING",
    needEffect = "water",
    waterLiters = 1,
    thirstRelief = 0.50,
    effectDelayMs = 1800,
})

return Definitions
