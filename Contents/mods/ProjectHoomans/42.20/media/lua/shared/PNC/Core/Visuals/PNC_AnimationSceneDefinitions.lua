-- Built-in scene catalog. Keeping policy data separate from the arbiter makes
-- it straightforward for PNC or another shared mod to replace registrations.

local Scenes = PNC.AnimationScenes

Scenes.Register("idle.shift_weight", {
    label = "Shift Weight",
    description = "A subtle weight-shift primitive.",
    bump = "ShiftWeight",
    durationMs = 2600,
    priority = 10,
    interrupts = {
        movement = true,
        combat = true,
        externalBump = true,
    },
})

Scenes.Register("idle.smell_bad", {
    label = "Notice Bad Smell",
    description = "A short unpleasant-smell primitive.",
    bump = "SmellBad",
    durationMs = 3200,
    priority = 10,
    interrupts = {
        movement = true,
        combat = true,
        externalBump = true,
    },
})

Scenes.Register("idle.smell_gag", {
    label = "Smell and Gag",
    description = "A stronger smell-and-gag primitive.",
    bump = "SmellGag",
    durationMs = 3000,
    priority = 10,
    interrupts = {
        movement = true,
        combat = true,
        externalBump = true,
    },
})

Scenes.Register("idle.sneeze", {
    label = "Sneeze",
    description = "A brief sneeze primitive.",
    bump = "Sneeze",
    durationMs = 2200,
    priority = 10,
    interrupts = {
        movement = true,
        combat = true,
        externalBump = true,
    },
})

Scenes.Register("idle.ambient", {
    label = "Ambient Idle Sequence",
    description = "A shuffled, interruptible queue of ambient idle primitives.",
    category = "idle",
    pool = "idle",
    weight = 1,
    priority = 10,
    sequenceMode = "shuffle",
    repeatMode = "loop",
    stepGapMs = 250,
    stepGapJitterMs = 350,
    steps = {
        {
            id = "shift_weight",
            bump = "ShiftWeight",
            durationMs = 2600,
        },
        {
            id = "smell_bad",
            bump = "SmellBad",
            durationMs = 3200,
        },
        {
            id = "smell_gag",
            bump = "SmellGag",
            durationMs = 3000,
        },
        {
            id = "sneeze",
            bump = "Sneeze",
            durationMs = 2200,
        },
    },
    interrupts = {
        movement = true,
        combat = true,
        externalBump = true,
        abstract = true,
    },
})

Scenes.Register("social.surrender", {
    label = "Surrender",
    description = "A persistent blocking surrender pose.",
    bump = "Surrender",
    priority = 80,
    repeatMode = "loop",
    blocking = true,
    interrupts = {
        movement = false,
        combat = true,
        externalBump = true,
    },
})

Scenes.Register("facility.sleep.floor", {
    label = "Sleep on Floor",
    description = "A persistent ground sleep loop used when no bed is present.",
    category = "facility",
    bump = "Sleep",
    priority = 45,
    repeatMode = "loop",
    blocking = true,
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
    stepGapMs = 250,
    sequenceMode = "shuffle",
    steps = {
        { id = "sit", bump = "Sit", durationMs = 4200 },
        { id = "sit_action", bump = "SitAction", durationMs = 3600 },
        { id = "sit_making", bump = "SitMaking", durationMs = 3600 },
        { id = "sit_rub_hands", bump = "SitRubHands", durationMs = 3600 },
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

Scenes.Register("facility.water.drink", {
    label = "Drink from Spigot",
    description = "Drink clean water from the colony spigot.",
    category = "facility",
    priority = 60,
    repeatMode = "once",
    blocking = true,
    bump = "Drink",
    durationMs = 3600,
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

Scenes.Register("facility.water.drink.nearby", {
    label = "Drink from Nearby Water",
    description = "Drink clean water from a nearby container.",
    category = "facility",
    priority = 60,
    repeatMode = "once",
    blocking = true,
    bump = "Drink",
    durationMs = 3600,
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
