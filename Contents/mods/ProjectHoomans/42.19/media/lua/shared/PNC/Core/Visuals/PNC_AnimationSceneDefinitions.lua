-- Built-in scene catalog. Keeping policy data separate from the arbiter makes
-- it straightforward for PNC or another shared mod to replace registrations.

local Scenes = PNC.AnimationScenes

Scenes.Register("idle.shift_weight", {
    label = "Shift Weight",
    description = "A subtle weight shift for the weighted idle pool.",
    bump = "ShiftWeight",
    durationMs = 2600,
    priority = 10,
    pool = "idle",
    weight = 5,
    interrupts = {
        movement = true,
        externalBump = true,
    },
})

Scenes.Register("idle.smell_bad", {
    label = "Notice Bad Smell",
    description = "A short idle reaction to an unpleasant smell.",
    bump = "SmellBad",
    durationMs = 3200,
    priority = 10,
    pool = "idle",
    weight = 1,
    interrupts = {
        movement = true,
        externalBump = true,
    },
})

Scenes.Register("idle.smell_gag", {
    label = "Smell and Gag",
    description = "A stronger idle smell reaction.",
    bump = "SmellGag",
    durationMs = 3000,
    priority = 10,
    pool = "idle",
    weight = 1,
    interrupts = {
        movement = true,
        externalBump = true,
    },
})

Scenes.Register("idle.sneeze", {
    label = "Sneeze",
    description = "A brief sneeze used as an idle variation.",
    bump = "Sneeze",
    durationMs = 2200,
    priority = 10,
    pool = "idle",
    weight = 2,
    interrupts = {
        movement = true,
        externalBump = true,
    },
})

Scenes.Register("social.surrender", {
    label = "Surrender",
    description = "A persistent blocking surrender pose.",
    bump = "Surrender",
    priority = 80,
    loop = true,
    blocking = true,
    interrupts = {
        movement = false,
        combat = false,
        externalBump = true,
    },
})

return Scenes
