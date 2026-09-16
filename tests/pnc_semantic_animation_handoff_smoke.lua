local T = require "tests/support/test"
T.addPackagePaths()

local now = 100
local finishCalls = 0
local maintainCalls = 0
local holdCalls = 0
local modData = {}

PsychopatzCore = {
    RuntimeRole = {
        AllowsServerCode = function() return true end,
    },
}
PNC = {
    Core = {
        Now = function() return now end,
    },
    Const = {
        PRESENCE_LIVE = "live",
        ANIMATION_IDLE_SCENE_MIN_MS = 8000,
        ANIMATION_IDLE_SCENE_JITTER_MS = 12000,
    },
    Animation = {
        FinishBump = function()
            finishCalls = finishCalls + 1
            return true
        end,
        MaintainBump = function()
            maintainCalls = maintainCalls + 1
            return true
        end,
        PlayBump = function() return true end,
    },
    BehaviorMoveIntent = {
        Hold = function()
            holdCalls = holdCalls + 1
            return true
        end,
    },
    Semantics = {
        ActionPlanService = {
            GetExecutionOwner = function()
                return PNC.TestMovementOwner
            end,
        },
    },
}

local Scenes = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Visuals/PNC_AnimationScenes.lua"
)
Scenes.Register("social.conversation", {
    blocking = true,
    repeatMode = "loop",
    interrupts = { movement = false },
    steps = {
        { id = "shift", bump = "ShiftWeight", durationMs = 1000 },
    },
})

local record = {
    id = "npc:conversation",
    alive = true,
    presenceState = "live",
    runtime = {
        animationScene = {
            id = "social.conversation",
            revision = 1,
            playbackRevision = 1,
            stepPosition = 1,
            order = { 1 },
            stepIndex = 1,
            stepId = "shift",
            bump = "ShiftWeight",
            loop = true,
            finishAt = 0,
        },
        pathing = {
            phase = "active",
        },
    },
}
local zombie = {
    getModData = function() return modData end,
    isDead = function() return false end,
}

PNC.TestMovementOwner = {
    action = "MOVE_TO",
    stepState = "TRAVEL",
}
local blocked = Scenes.Tick(record, zombie, now)
T.equal(blocked, false,
    "conversation presentation yields to semantic movement")
T.equal(record.activeBehavior, "SemanticActionPlan:MOVE_TO",
    "movement remains the authoritative behavior owner")
T.equal(record.runtime.animationScene.semanticMovementHandoff, true,
    "conversation scene records the movement handoff")
T.equal(finishCalls, 1, "the active conversation bump is released once")
T.equal(maintainCalls, 0,
    "conversation playback is not replayed over the movement lane")
T.equal(holdCalls, 0,
    "conversation blocking does not hold an owned movement lane")

now = 101
Scenes.Tick(record, zombie, now)
T.equal(finishCalls, 1, "movement handoff does not repeatedly finish bumps")

PNC.TestMovementOwner = {
    action = "WAIT",
    stepState = "WAITING",
}
now = 102
local waiting = Scenes.Tick(record, zombie, now)
T.equal(waiting, true,
    "conversation blocking resumes after movement reaches the next step")
T.equal(record.runtime.animationScene.semanticMovementHandoff, nil,
    "movement handoff is cleared when movement ownership ends")
T.equal(holdCalls, 1,
    "conversation can hold the actor again during the wait step")

PNC.Semantics.ActionPlanService.GetExecutionOwner = function()
    return nil
end
record.semanticActionPlan = {
    planID = "plan:replicated-move",
    state = "RUNNING",
    currentStep = 1,
    steps = {
        { id = "move", action = "MOVE_TO", state = "TRAVEL" },
    },
}
record.runtime.pathing = { phase = "active" }
now = 103
local replicatedHandoff = Scenes.Tick(record, zombie, now)
T.equal(replicatedHandoff, false,
    "replicated movement state also yields the conversation scene")
T.equal(record.activeBehavior, "SemanticActionPlan:MOVE_TO",
    "replicated movement remains the visual owner")
T.equal(finishCalls, 2,
    "replicated movement releases the resumed presentation bump once")

T.finish("pnc_semantic_animation_handoff_smoke")
