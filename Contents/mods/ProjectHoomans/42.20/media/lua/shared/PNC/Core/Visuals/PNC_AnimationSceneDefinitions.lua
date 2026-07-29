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

return Scenes
