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
    role = "growing.plot",
    domain = "farming",
    arrivalDistance = 0.8,
    activityLabel = "FARMING",
})

Definitions.Register("living", {
    activeJob = "LivingRoom",
    activityLabelKey = "UI_PNC_Activity_Relaxing",
    activityText = "Relaxing",
    sceneId = "facility.living.sitFurniture",
    role = "living.chair",
    arrivalDistance = 0.14,
    activityLabel = "SITTING",
})

Definitions.Register("recreation", {
    activeJob = "Recreation",
    activityLabelKey = "UI_PNC_Activity_Recreating",
    activityText = "Recreating",
    sceneId = "facility.living.sitFurniture",
    role = "living.chair",
    arrivalDistance = 0.14,
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
    sceneId = "survival.eat.inventory",
    role = "dining.table",
    arrivalDistance = 0.85,
    activityLabel = "EATING",
    needEffect = "primitive",
    primitiveNeed = "hunger",
    effectDelayMs = 1200,
    completeWithScene = true,
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
    completeWithScene = true,
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

-- Hydration is a survival action, not a settlement facility. Personal drinks
-- and world water sources share the same executor, but neither requires a
-- settlement water facility or an abstract water balance.
Definitions.Register("survival.drink.inventory", {
    activeJob = "Drink",
    activityLabelKey = "UI_PNC_Activity_Drinking",
    activityText = "Drinking",
    sceneId = "survival.drink.inventory",
    role = "survival.personal_drink",
    arrivalDistance = 0.85,
    activityLabel = "DRINKING",
    needEffect = "primitive",
    primitiveNeed = "thirst",
    effectDelayMs = 1200,
    completeWithScene = true,
})

Definitions.Register("survival.drink.world", {
    activeJob = "Drink",
    activityLabelKey = "UI_PNC_Activity_Drinking",
    activityText = "Drinking",
    sceneId = "survival.drink.world",
    role = "survival.world_water",
    arrivalDistance = 0.85,
    activityLabel = "DRINKING",
    needEffect = "world_water",
    effectDelayMs = 1800,
    completeWithScene = true,
})

Definitions.Register("survival.fill.water", {
    activeJob = "Fill Water Container",
    activityLabelKey = "UI_PNC_Activity_FillingWater",
    activityText = "Filling Water",
    sceneId = "survival.fill.water",
    role = "survival.water_refill",
    arrivalDistance = 0.85,
    activityLabel = "FILLING WATER",
    needEffect = "water_refill",
    effectDelayMs = 1200,
    completeWithScene = true,
})

return Definitions
