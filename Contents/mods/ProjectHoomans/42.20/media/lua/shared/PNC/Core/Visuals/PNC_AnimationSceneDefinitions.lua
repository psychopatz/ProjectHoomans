-- Built-in scene catalog. Keeping policy data separate from the arbiter makes
-- it straightforward for PNC or another shared mod to replace registrations.

local Scenes = PNC.AnimationScenes

local EAT_STEPS = {
    { id = "eat_1", bump = "Eat", durationMs = 3000 },
    { id = "eat_2", bump = "Eat", durationMs = 3000 },
    { id = "eat_3", bump = "Eat", durationMs = 3000 },
    { id = "wipe_brow", bump = "WipeBrow", durationMs = 1800 },
    { id = "wipe_head", bump = "WipeHead", durationMs = 1900 },
}

local DRINK_STEPS = {
    { id = "drink", bump = "Drink", durationMs = 3600 },
    { id = "wipe_brow", bump = "WipeBrow", durationMs = 1800 },
    { id = "wipe_head", bump = "WipeHead", durationMs = 1900 },
}

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
