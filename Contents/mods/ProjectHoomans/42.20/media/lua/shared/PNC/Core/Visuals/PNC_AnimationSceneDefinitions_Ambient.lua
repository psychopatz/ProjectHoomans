-- Ambient and survival animation scene registrations.

PNC = PNC or {}
PNC.AnimationScenes = PNC.AnimationScenes or {}
local Scenes = PNC.AnimationScenes
local Internal = Scenes.Internal or {}
Scenes.Internal = Internal
local EAT_STEPS = Internal.EAT_STEPS or {}
local DRINK_STEPS = Internal.DRINK_STEPS or {}


local function ambientRoamTick(record, zombie, scene, now)
    local service = PNC and PNC.AutonomyExecutors
        and PNC.AutonomyExecutors.RoamAmbient
    if service and service.OnSceneTick then
        return service.OnSceneTick(record, zombie, scene, now)
    end
    return true
end

local function ambientRoamStopped(record, zombie, scene, reason)
    local service = PNC and PNC.AutonomyExecutors
        and PNC.AutonomyExecutors.RoamAmbient
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

Scenes.Register("ambient.roam.sleep.floor", {
    label = "Ambient Roam Sleep on Floor",
    description = "A persistent ground sleep pose for indoor rooms or outdoor camps.",
    category = "ambient",
    priority = 30,
    repeatMode = "loop",
    blocking = true,
    keepManagedUseless = true,
    steps = {
        { id = "sleep", bump = "Sleep", durationMs = 0, loop = true },
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

Scenes.Register("ambient.roam.camp.build", {
    label = "Ambient Night Campfire Build",
    description = "Crouched lower-reach animation while assembling and lighting a campfire.",
    category = "ambient",
    priority = 32,
    repeatMode = "loop",
    blocking = true,
    keepManagedUseless = true,
    steps = {
        { id = "build_fire", bump = "LootLow", durationMs = 1400, loop = true },
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

Scenes.Register("ambient.roam.camp.fireside", {
    label = "Ambient Night Camp Fireside Circle",
    description = "Seated fireside circle pose for evening stories and warming hands before sleep curfew.",
    category = "ambient",
    priority = 28,
    repeatMode = "loop",
    blocking = true,
    keepManagedUseless = true,
    retainBump = true,
    stepGapMs = 0,
    sequenceMode = "shuffle",
    steps = {
        { id = "warm_hands", bump = "SitRubHands", durationMs = 4500, loop = true },
        { id = "fireside_sit", bump = "Sit", durationMs = 5200, loop = true },
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

Scenes.Register("ambient.roam.camp.sentry", {
    label = "Ambient Night Camp Sentry",
    description = "An awake fireside watch pose for an outdoor night-camp sentry.",
    category = "ambient",
    priority = 28,
    repeatMode = "loop",
    blocking = true,
    keepManagedUseless = true,
    retainBump = true,
    stepGapMs = 0,
    sequenceMode = "shuffle",
    steps = {
        { id = "warm_hands", bump = "SitRubHands", durationMs = 4200, loop = true },
        { id = "watch_sit", bump = "Sit", durationMs = 4600, loop = true },
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

Scenes.Register("social.item_share_give", {
    label = "Share Item (Give)",
    description = "Hand a carried survival item to a teammate in need.",
    category = "social",
    bump = "ItemShare",
    durationMs = 2800,
    priority = 62,
    loop = false,
    blocking = true,
    interrupts = {
        movement = false,
        combat = true,
        externalBump = true,
        abstract = true,
    },
    onStop = function(record)
        if type(record) == "table" and type(record.runtime) == "table" then
            record.runtime.sceneActionProps = nil
        end
    end,
})

Scenes.Register("social.item_share_receive", {
    label = "Share Item (Receive)",
    description = "Receive a shared survival item from a teammate.",
    category = "social",
    bump = "ItemShare",
    durationMs = 2400,
    priority = 60,
    loop = false,
    blocking = true,
    interrupts = {
        movement = false,
        combat = true,
        externalBump = true,
        abstract = true,
    },
    onStop = function(record)
        if type(record) == "table" and type(record.runtime) == "table" then
            record.runtime.sceneActionProps = nil
        end
    end,
})

return Scenes
