-- Facility animation scene registrations.

PNC = PNC or {}
PNC.AnimationScenes = PNC.AnimationScenes or {}
local Scenes = PNC.AnimationScenes

Scenes.Register("facility.sleep.floor", {
    label = "Sleep on Floor",
    description = "A persistent ground sleep loop used when no bed is present.",
    category = "facility",
    bump = "Sleep",
    priority = 45,
    repeatMode = "loop",
    blocking = true,
    -- Sleeping is a presentation lease. Keep the managed body useless so
    -- the vanilla zombie brain cannot reacquire alert/pathing ownership.
    keepManagedUseless = true,
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

Scenes.Register("facility.sleep.bed", {
    label = "Sleep in Bed",
    description = "A persistent bed sleep loop owned by a facility job.",
    category = "facility",
    bump = "SleepBed",
    priority = 45,
    repeatMode = "loop",
    blocking = true,
    -- Sleeping is a presentation lease. Keep the managed body useless so
    -- the vanilla zombie brain cannot reacquire alert/pathing ownership.
    keepManagedUseless = true,
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

Scenes.Register("facility.farm.work", {
    label = "Work Farm Plot",
    description = "A loop of cultivation primitives for farm work.",
    category = "facility",
    priority = 40,
    repeatMode = "loop",
    blocking = true,
    stepGapMs = 350,
    steps = {
        { id = "dig", bump = "DigShovel", durationMs = 4600 },
        { id = "water", bump = "PourWateringCan", durationMs = 3800 },
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

Scenes.Register("facility.living.sit", {
    label = "Sit in Living Room",
    description = "A relaxed sitting sequence for idle companions.",
    category = "facility",
    priority = 20,
    repeatMode = "loop",
    blocking = true,
    -- Ground sitting is a presentation lease. Keep the managed body useless
    -- so the vanilla zombie brain cannot reacquire alert/pathing ownership.
    keepManagedUseless = true,
    -- The ground clips are compatible sitting poses. Switch their selector
    -- without releasing the active bump, so the body never stands between
    -- two sitting variants.
    retainBump = true,
    stepGapMs = 0,
    sequenceMode = "shuffle",
    steps = {
        { id = "sit", bump = "Sit", durationMs = 4200, loop = true },
        { id = "sit_action", bump = "SitAction", durationMs = 3600,
            loop = true },
        { id = "sit_making", bump = "SitMaking", durationMs = 3600,
            loop = true },
        { id = "sit_rub_hands", bump = "SitRubHands", durationMs = 3600,
            loop = true },
    },
    interrupts = {
        movement = true,
        combat = true,
        externalBump = true,
        abstract = true,
    },
    onTick = function(record, zombie, scene, now)
        local roaming = PNC and PNC.RoamingSeat
        if record and record.runtime and record.runtime.roamingSeat then
            if roaming and roaming.OnSceneTick then
                return roaming.OnSceneTick(record, zombie, scene, now)
            end
            return true
        end
        local jobs = PNC and PNC.FacilityJobs
        if jobs and jobs.OnSceneTick then
            return jobs.OnSceneTick(record, zombie, scene, now)
        end
        return true
    end,
    onStop = function(record, zombie, scene, reason)
        local roaming = PNC and PNC.RoamingSeat
        if record and record.runtime and record.runtime.roamingSeat then
            if roaming and roaming.OnSceneStopped then
                roaming.OnSceneStopped(record, zombie, scene, reason)
            end
            return
        end
        local jobs = PNC and PNC.FacilityJobs
        if jobs and jobs.OnSceneStopped then
            jobs.OnSceneStopped(record, zombie, scene, reason)
        end
    end,
})

Scenes.Register("facility.sleep.sofa", {
    label = "Sleep on Sofa",
    description = "A persistent sofa sleep loop owned by a facility job.",
    category = "facility",
    -- Keep the same lying pose as a bed until the in-game sofa validation
    -- pass confirms whether a dedicated sofa animation is needed.
    bump = "SleepBed",
    priority = 45,
    repeatMode = "loop",
    blocking = true,
    -- Sleeping is a presentation lease. Keep the managed body useless so
    -- the vanilla zombie brain cannot reacquire alert/pathing ownership.
    keepManagedUseless = true,
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

Scenes.Register("facility.living.sitFurniture", {
    label = "Sit on Furniture",
    description = "A persistent chair pose anchored to a discovered seat.",
    category = "facility",
    priority = 20,
    repeatMode = "loop",
    blocking = true,
    -- The seat pose is a presentation lease. Keep the managed body useless so
    -- the vanilla zombie brain cannot reacquire alert/pathing ownership.
    keepManagedUseless = true,
    steps = {
        { id = "sit_chair", bump = "SitChair", durationMs = 0, loop = true },
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

Scenes.Register("ambient.roam.sitFurniture", {
    label = "Ambient Roam Sit",
    description = "A transient chair pose for an idle roaming NPC.",
    category = "ambient",
    priority = 20,
    repeatMode = "loop",
    blocking = true,
    -- The seat pose is a presentation lease. Keep the managed body useless so
    -- the vanilla zombie brain cannot reacquire alert/pathing ownership.
    keepManagedUseless = true,
    steps = {
        { id = "sit_chair", bump = "SitChair", durationMs = 0, loop = true },
    },
    interrupts = {
        movement = true,
        combat = true,
        externalBump = true,
        abstract = true,
    },
    onTick = function(record, zombie, scene, now)
        local service = PNC and PNC.RoamingSeat
        if service and service.OnSceneTick then
            return service.OnSceneTick(record, zombie, scene, now)
        end
        -- The authoritative server owns this transient service. A client
        -- without the server module should keep rendering the synchronized
        -- presentation lease rather than clearing it locally.
        return true
    end,
    onStop = function(record, zombie, scene, reason)
        local service = PNC and PNC.RoamingSeat
        if service and service.OnSceneStopped then
            service.OnSceneStopped(record, zombie, scene, reason)
        end
    end,
})

return Scenes
