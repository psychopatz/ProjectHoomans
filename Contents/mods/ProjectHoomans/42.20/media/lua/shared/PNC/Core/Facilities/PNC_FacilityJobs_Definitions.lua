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
    activityLabelKey = "UI_PNC_Activity_Sleeping",
    activityText = "Sleeping",
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
    activityLabelKey = "UI_PNC_Activity_Farming",
    activityText = "Farming",
    sceneId = "facility.farm.work",
    role = "farm.field",
    arrivalDistance = 0.8,
    activityLabel = "FARMING",
})

Definitions.Register("living", {
    activeJob = "LivingRoom",
    activityLabelKey = "UI_PNC_Activity_Relaxing",
    activityText = "Relaxing",
    sceneId = "facility.living.sit",
    role = "living.chair",
    arrivalDistance = 0.85,
    activityLabel = "SITTING",
})

Definitions.Register("recreation", {
    activeJob = "Recreation",
    activityLabelKey = "UI_PNC_Activity_Recreating",
    activityText = "Recreating",
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
    activityLabelKey = "UI_PNC_Activity_Eating",
    activityText = "Eating",
    sceneId = "facility.living.sit",
    role = "dining.table",
    arrivalDistance = 0.85,
    activityLabel = "EATING",
    needEffect = "primitive",
    primitiveNeed = "hunger",
    effectDelayMs = 1200,
})

-- Away-from-home survival actions use the same FacilityJobs state machine as
-- home activities. The synthetic target is the follower's current square, so
-- completion restores the previous FollowOwner order without inventing a
-- second behavior executor.
Definitions.Register("survival.eat.inventory", {
    activeJob = "Eat",
    activityLabelKey = "UI_PNC_Activity_Eating",
    activityText = "Eating",
    sceneId = "survival.eat.inventory",
    role = "survival.personal_food",
    arrivalDistance = 0.85,
    activityLabel = "EATING",
    needEffect = "primitive",
    primitiveNeed = "hunger",
    effectDelayMs = 1200,
})

Definitions.Register("health.recover", {
    activeJob = "HospitalRecovery",
    activityLabelKey = "UI_PNC_Activity_Recovering",
    activityText = "Recovering",
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
    activityLabelKey = "UI_PNC_Activity_Drinking",
    activityText = "Drinking",
    sceneId = "facility.water.drink",
    role = "water.spigot",
    arrivalDistance = 0.85,
    activityLabel = "DRINKING",
    needEffect = "water",
    waterLiters = 1,
    thirstRelief = 0.50,
    effectDelayMs = 1800,
})

Definitions.Register("water.nearby", {
    activeJob = "Drink",
    activityLabelKey = "UI_PNC_Activity_Drinking",
    activityText = "Drinking",
    sceneId = "facility.water.drink.nearby",
    role = "water.nearby",
    arrivalDistance = 0.85,
    activityLabel = "DRINKING",
    needEffect = "nearby_water",
    effectDelayMs = 1800,
})

return Definitions
