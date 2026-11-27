-- Base and social animation scene registrations.

PNC = PNC or {}
PNC.AnimationScenes = PNC.AnimationScenes or {}
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

Scenes.Register("social.reaction.wavehi", {
    label = "Wave Hi",
    description = "A short conversational wave that never owns movement.",
    category = "social",
    bump = "WaveHi",
    durationMs = 2200,
    priority = 15,
    repeatMode = "once",
    blocking = false,
    interrupts = {
        movement = true,
        combat = true,
        externalBump = true,
        abstract = true,
    },
})

Scenes.Register("suicide.handgun", {
    label = "Suicide (Handgun 1)",
    description = "Immersive Suicide handgun variant 1 (Bob_Suicide_Handgun).",
    category = "suicide",
    pool = "suicide_handgun",
    weight = 1,
    bump = "SuicideHandgun",
    durationMs = 2200,
    priority = 90,
    repeatMode = "once",
    blocking = true,
    props = {
        primary = "Base.Pistol",
    },
    interrupts = {
        movement = false,
        combat = true,
        externalBump = true,
        abstract = true,
    },
})

Scenes.Register("suicide.handgun_02", {
    label = "Suicide (Handgun 2)",
    description = "Immersive Suicide handgun variant 2 (Bob_Suicide_Handgun02).",
    category = "suicide",
    pool = "suicide_handgun",
    weight = 1,
    bump = "SuicideHandgun02",
    durationMs = 2100,
    priority = 90,
    repeatMode = "once",
    blocking = true,
    props = {
        primary = "Base.Pistol",
    },
    interrupts = {
        movement = false,
        combat = true,
        externalBump = true,
        abstract = true,
    },
})

Scenes.Register("suicide.handgun_03", {
    label = "Suicide (Handgun 3)",
    description = "Immersive Suicide handgun variant 3 (Bob_Suicide_Handgun03).",
    category = "suicide",
    pool = "suicide_handgun",
    weight = 1,
    bump = "SuicideHandgun03",
    durationMs = 2000,
    priority = 90,
    repeatMode = "once",
    blocking = true,
    props = {
        primary = "Base.Pistol",
    },
    interrupts = {
        movement = false,
        combat = true,
        externalBump = true,
        abstract = true,
    },
})

Scenes.Register("suicide.rifle", {
    label = "Suicide (Rifle)",
    description = "Immersive Suicide rifle variant (Bob_Suicide_Rifle).",
    category = "suicide",
    bump = "SuicideRifle",
    durationMs = 2400,
    priority = 90,
    repeatMode = "once",
    blocking = true,
    props = {
        primary = "Base.HuntingRifle",
    },
    interrupts = {
        movement = false,
        combat = true,
        externalBump = true,
        abstract = true,
    },
})


Scenes.Internal = Scenes.Internal or {}
Scenes.Internal.EAT_STEPS = EAT_STEPS
Scenes.Internal.DRINK_STEPS = DRINK_STEPS

return Scenes
