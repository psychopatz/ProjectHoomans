--[[
    PNC NPC Voice Catalog
    Semantic voice events and presentation policy only.

    Keep engine aliases here as suffixes. PNC_NPCVoice resolves the
    gendered VoiceFemale/VoiceMale prefix from the NPC identity profile.
]]

PNC = PNC or {}
PNC.NPCVoice = PNC.NPCVoice or {}
PNC.NPCVoice.Catalog = PNC.NPCVoice.Catalog or {}

local Catalog = PNC.NPCVoice.Catalog

Catalog.Events = {
    ["injury.generic"] = {
        suffix = "PainMoodle",
        mode = "local",
        cooldown = 0.75,
    },
    ["injury.blunt"] = {
        suffix = "PainFromHitBlunt",
        mode = "local",
        cooldown = 0.75,
    },
    ["injury.bite"] = {
        suffix = "PainFromBite",
        mode = "local",
        cooldown = 0.75,
    },
    ["injury.glass_cut"] = {
        suffix = "PainFromGlassCut",
        mode = "local",
        cooldown = 0.75,
    },
    ["injury.fall_low"] = {
        suffix = "PainFromFallLow",
        mode = "local",
        cooldown = 0.75,
    },
    ["injury.fall_high"] = {
        suffix = "PainFromFallHigh",
        mode = "local",
        cooldown = 0.75,
    },
    ["injury.wall"] = {
        suffix = "PainFromRunIntoWall",
        mode = "local",
        cooldown = 0.75,
    },
    ["injury.scratch"] = {
        suffix = "PainFromScratch",
        mode = "local",
        cooldown = 0.75,
    },
    ["injury.lacerate"] = {
        suffix = "PainFromLacerate",
        mode = "local",
        cooldown = 0.75,
    },
    ["effort.exhausted"] = {
        suffix = "Exercise",
        mode = "local",
        cooldown = 3.0,
    },
    ["incapacitated.impact"] = {
        suffix = "DeathAlone",
        mode = "world",
        radius = 16,
        volume = 18,
        stressHumans = false,
        cooldown = 1.0,
    },
    ["death.alone"] = {
        suffix = "DeathAlone",
        mode = "world",
        radius = 18,
        volume = 20,
        stressHumans = false,
        cooldown = 1.0,
    },
    ["death.fall"] = {
        suffix = "DeathFall",
        mode = "world",
        radius = 18,
        volume = 20,
        stressHumans = false,
        cooldown = 1.0,
    },
    ["social.come_on"] = {
        suffix = "LureCmon",
        mode = "local",
        cooldown = 0.5,
    },
    ["social.tsk"] = {
        suffix = "LureTsk",
        mode = "local",
        cooldown = 0.5,
    },
    ["social.shout_hey"] = {
        suffix = "ShoutHey",
        mode = "world",
        radius = 30,
        volume = 30,
        stressHumans = false,
        cooldown = 0.5,
    },
    ["social.whisper_hey"] = {
        suffix = "WhisperHey",
        mode = "local",
        cooldown = 0.5,
    },
    ["respiratory.cough"] = {
        suffix = "Cough",
        mode = "local",
        cooldown = 2.0,
    },
    ["respiratory.sneeze_light"] = {
        suffix = "SneezeLight",
        mode = "local",
        cooldown = 2.0,
    },
    ["respiratory.sneeze_heavy"] = {
        suffix = "SneezeHeavy",
        mode = "local",
        cooldown = 2.0,
    },
    ["respiratory.muffled_cough"] = {
        suffix = "MuffledCough",
        mode = "local",
        cooldown = 2.0,
    },
    ["action.bandage"] = {
        suffix = "ApplyBandage",
        mode = "local",
        cooldown = 1.0,
        chancePercent = 80,
    },
    ["action.vomit"] = {
        suffix = "Vomit",
        mode = "local",
        cooldown = 2.0,
    },
    ["action.sleep"] = {
        suffix = "Sleep",
        mode = "local",
        cooldown = 2.0,
    },
    ["effort.jump_low"] = {
        suffix = "JumpLow",
        mode = "local",
        cooldown = 0.75,
    },
    ["effort.jump_high"] = {
        suffix = "JumpHigh",
        mode = "local",
        cooldown = 0.75,
    },
    ["effort.climb_window"] = {
        suffix = "ClimbWindow",
        mode = "local",
        cooldown = 1.0,
    },
    ["effort.corpse_low"] = {
        suffix = "CorpseLowEffort",
        mode = "local",
        cooldown = 1.0,
    },
    ["effort.corpse_high"] = {
        suffix = "CorpseHighEffort",
        mode = "local",
        cooldown = 1.0,
    },
}

-- Trigger rules are intentionally data-driven. The observer knows how to
-- evaluate this shape, but does not know which state, sound, or percentage a
-- future trigger should use. Match fields may be dotted snapshot paths; the
-- short visual names remain supported for compatibility.
Catalog.TriggerRules = {
    {
        id = "animation.sneeze",
        eventID = "respiratory.sneeze_light",
        match = {
            fields = {
                "visualState.anim",
                "visualState.sceneBump",
                "visualState.specialAnim",
            },
            values = { "sneeze" },
            mode = "contains",
        },
        chancePercent = 20,
        cooldown = 5.0,
    },
    {
        id = "animation.cough",
        eventID = "respiratory.cough",
        match = {
            fields = {
                "visualState.anim",
                "visualState.sceneBump",
                "visualState.specialAnim",
            },
            values = { "cough" },
            mode = "contains",
        },
        chancePercent = 20,
        cooldown = 5.0,
    },
    {
        id = "state.bandage",
        eventID = "action.bandage",
        match = {
            fields = {
                "treatmentState.phase",
                "visualState.anim",
                "visualState.sceneBump",
                "visualState.specialAnim",
            },
            values = { "bandaging", "bandage" },
            mode = "contains",
        },
        keyFields = {
            "treatmentState.partId",
            "treatmentState.startedAt",
            "visualState.sceneId",
            "visualState.sceneRevision",
            "visualState.scenePlaybackRevision",
            "visualState.sceneStepId",
            "visualState.sceneStepStartedAt",
            "visualState.anim",
            "visualState.sceneBump",
            "visualState.specialAnim",
        },
        chancePercent = 80,
        cooldown = 1.0,
    },
    {
        id = "state.sleep",
        eventID = "action.sleep",
        match = {
            fields = {
                "visualState.anim",
                "visualState.sceneBump",
                "visualState.specialAnim",
            },
            values = { "sleep" },
            mode = "contains",
        },
        cooldown = 2.0,
    },
}

-- Compatibility aliases for callers/tests that used the first animation-only
-- name before the matcher became a general snapshot trigger system.
Catalog.AnimationTriggers = Catalog.TriggerRules

function Catalog.Get(eventID)
    return Catalog.Events[tostring(eventID or "")]
end

function Catalog.All()
    return Catalog.Events
end

function Catalog.GetAnimationTriggers()
    return Catalog.TriggerRules
end

function Catalog.GetTriggerRules()
    return Catalog.TriggerRules
end

return Catalog
