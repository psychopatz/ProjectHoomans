-- Ambient and survival animation scene registrations.

PNC = PNC or {}
PNC.AnimationScenes = PNC.AnimationScenes or {}
local Scenes = PNC.AnimationScenes
local Internal = Scenes.Internal or {}
Scenes.Internal = Internal
local EAT_STEPS = Internal.EAT_STEPS or {}
local DRINK_STEPS = Internal.DRINK_STEPS or {}


local function ambientRoamTick(record, zombie, scene, now)
    local service = PNC and PNC.RoamAmbient
    if service and service.OnSceneTick then
        return service.OnSceneTick(record, zombie, scene, now)
    end
    return true
end

local function ambientRoamStopped(record, zombie, scene, reason)
    local service = PNC and PNC.RoamAmbient
    if service and service.OnSceneStopped then
        service.OnSceneStopped(record, zombie, scene, reason)
    end
end

Scenes.Register("ambient.roam.eat", {
    label = "Ambient Roam Eat",
    description = "A visual eating sequence for an idle roaming NPC.",
    category = "ambient",
    priority = 25,
    repeatMode = "once",
    blocking = true,
    stepGapMs = 180,
    steps = EAT_STEPS,
    interrupts = {
        movement = true,
        combat = true,
        externalBump = true,
        abstract = true,
    },
    onTick = ambientRoamTick,
    onStop = ambientRoamStopped,
})

Scenes.Register("ambient.roam.drink", {
    label = "Ambient Roam Drink",
    description = "A visual drinking sequence for an idle roaming NPC.",
    category = "ambient",
    priority = 25,
    repeatMode = "once",
    blocking = true,
    stepGapMs = 180,
    steps = DRINK_STEPS,
    interrupts = {
        movement = true,
        combat = true,
        externalBump = true,
        abstract = true,
    },
    onTick = ambientRoamTick,
    onStop = ambientRoamStopped,
})

local function registerAmbientSleep(sceneId, label)
    Scenes.Register(sceneId, {
        label = label,
        description = "A persistent sleep pose for an idle roaming NPC.",
        category = "ambient",
        priority = 30,
        repeatMode = "loop",
        blocking = true,
        keepManagedUseless = true,
        steps = {
            { id = "sleep", bump = "SleepBed", durationMs = 0, loop = true },
        },
        interrupts = {
            movement = true,
            combat = true,
            externalBump = true,
            abstract = true,
        },
        onTick = ambientRoamTick,
        onStop = ambientRoamStopped,
    })
end

registerAmbientSleep("ambient.roam.sleep.bed", "Ambient Roam Sleep in Bed")
registerAmbientSleep("ambient.roam.sleep.sofa", "Ambient Roam Sleep on Sofa")

Scenes.Register("survival.drink.inventory", {
    label = "Drink from Personal Inventory",
    description = "Pause a follow order to drink from a carried item.",
    category = "survival",
    priority = 60,
    repeatMode = "once",
    blocking = true,
    stepGapMs = 180,
    steps = DRINK_STEPS,
    interrupts = {
        movement = true,
        combat = true,
        externalBump = true,
        abstract = true,
    },
    onTick = function(record, zombie, scene, now)
        local jobs = PNC and PNC.FacilityJobs
        if jobs and jobs.OnSceneTick then
            return jobs.OnSceneTick(record, zombie, scene, now)
        end
        return true
    end,
    onStop = function(record, zombie, scene, reason)
        local jobs = PNC and PNC.FacilityJobs
        if jobs and jobs.OnSceneStopped then
            jobs.OnSceneStopped(record, zombie, scene, reason)
        end
    end,
})

Scenes.Register("survival.drink.world", {
    label = "Drink from World Water",
    description = "Drink clean water from a valid nearby world object.",
    category = "survival",
    priority = 60,
    repeatMode = "once",
    blocking = true,
    stepGapMs = 180,
    steps = DRINK_STEPS,
    interrupts = {
        movement = true,
        combat = true,
        externalBump = true,
        abstract = true,
    },
    onTick = function(record, zombie, scene, now)
        local jobs = PNC and PNC.FacilityJobs
        if jobs and jobs.OnSceneTick then
            return jobs.OnSceneTick(record, zombie, scene, now)
        end
        return true
    end,
    onStop = function(record, zombie, scene, reason)
        local jobs = PNC and PNC.FacilityJobs
        if jobs and jobs.OnSceneStopped then
            jobs.OnSceneStopped(record, zombie, scene, reason)
        end
    end,
})

Scenes.Register("survival.fill.water", {
    label = "Fill Water Container",
    description = "Fill an empty liquid container from a clean world source.",
    category = "survival",
    priority = 59,
    repeatMode = "once",
    blocking = true,
    stepGapMs = 180,
    steps = {
        { id = "fill", bump = "PourWateringCan", durationMs = 3800 },
        { id = "wipe_brow", bump = "WipeBrow", durationMs = 1800 },
    },
    interrupts = {
        movement = true,
        combat = true,
        externalBump = true,
        abstract = true,
    },
    onTick = function(record, zombie, scene, now)
        local jobs = PNC and PNC.FacilityJobs
        if jobs and jobs.OnSceneTick then
            return jobs.OnSceneTick(record, zombie, scene, now)
        end
        return true
    end,
    onStop = function(record, zombie, scene, reason)
        local jobs = PNC and PNC.FacilityJobs
        if jobs and jobs.OnSceneStopped then
            jobs.OnSceneStopped(record, zombie, scene, reason)
        end
    end,
})

Scenes.Register("survival.eat.inventory", {
    label = "Eat from Personal Inventory",
    description = "Pause a follow order to eat carried food.",
    category = "survival",
    priority = 65,
    repeatMode = "once",
    blocking = true,
    stepGapMs = 180,
    steps = EAT_STEPS,
    interrupts = {
        movement = true,
        combat = true,
        externalBump = true,
        abstract = true,
    },
    onTick = function(record, zombie, scene, now)
        local jobs = PNC and PNC.FacilityJobs
        if jobs and jobs.OnSceneTick then
            return jobs.OnSceneTick(record, zombie, scene, now)
        end
        return true
    end,
    onStop = function(record, zombie, scene, reason)
        local jobs = PNC and PNC.FacilityJobs
        if jobs and jobs.OnSceneStopped then
            jobs.OnSceneStopped(record, zombie, scene, reason)
        end
    end,
})


return Scenes
