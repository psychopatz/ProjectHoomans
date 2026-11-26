local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
})

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local playedBumps = {}
local finishedCount = 0
local bumpActive = true

PNC = {
    Core = { Now = function() return 1000 end },
    Animation = {
        PlayBump = function(body, _, bump)
            playedBumps[#playedBumps + 1] = bump
            body:getModData().PNC_BumpRequestedType = bump
            return true
        end,
        ResolveBumpType = function(bump) return bump end,
        IsBumpActionActive = function() return bumpActive end,
        FinishBump = function() finishedCount = finishedCount + 1 end,
    },
    Choreography = {
        AnimVarAdapter = {
            Apply = function() return true end,
            UpdateProgress = function() end,
            Clear = function() end,
        },
        Telemetry = {},
    },
}

local Driver = T.load("ProjectHoomans", "shared",
    "PNC/Core/Visuals/PNC_AnimationDriver.lua")
local Scenes = T.load("ProjectHoomans", "shared",
    "PNC/Core/Visuals/PNC_AnimationScenes.lua")
local Packs = T.load("ProjectHoomans", "shared",
    "PNC/Core/Visuals/PNC_AnimationPacks.lua")
local OperaAnim = T.load("ProjectHoomans", "server",
    "PNC/Choreography/PNC_Choreography_NPCAnimationAdapter.lua")

local modData = {}
local body = {
    getModData = function() return modData end,
    getVariableBoolean = function() return not bumpActive end,
}
local record = { id = "npc-1", runtime = {} }

-- 1. Ownership isolation between two callers on the same body.
local ok1 = Driver.Start(body, record, {
    ownerToken = "scene:sit",
    bump = "Sit_Clip",
})
T.equal(ok1, true, "first owner starts bump via AnimationDriver")
T.equal(Driver.IsOwnedBy(body, "scene:sit"), true, "body owned by scene:sit")

local ok2, err2 = Driver.Start(body, record, {
    ownerToken = "opera:sess1",
    bump = "Opera_Wave",
})
T.equal(ok2, false, "second owner rejected without forceTakeover")
T.equal(err2, "anim_driver_owned_by_other", "ownership conflict reported")

-- 2. Observe playing -> finished, then Stop releases ownership cleanly.
local obs1, state1 = Driver.Observe(body, "scene:sit", {
    startedAt = 1000, durationMs = 500, now = 1100,
})
T.equal(obs1, true, "observe succeeds while owned")
T.equal(state1, "playing", "active bump reports playing")

bumpActive = false
local obs2, state2 = Driver.Observe(body, "scene:sit", {
    startedAt = 1000, durationMs = 500, now = 1600,
})
T.equal(obs2, true, "observe succeeds on completion")
T.equal(state2, "finished", "finished bump reports finished")

T.equal(Driver.Stop(body, record, "scene:sit"), true, "owner stops cleanly")
T.equal(Driver.GetOwner(body), nil, "ownership marker cleared on stop")
T.equal(finishedCount, 1, "FinishBump invoked on stop")

-- 3. Choreography beat referencing a sceneId inherits AnimationPacks overrides!
Scenes.Register("ambient.roam.eat", { bump = "Base_Eat", durationMs = 1500 })
Packs.RegisterPack("apple_pack", {
    priority = 100,
    scenes = {
        ["ambient.roam.eat"] = {
            mode = "replace",
            bumpType = "Pack_EatApple",
            props = { primary = "Base.Apple" },
        },
    },
})

local session = { sessionId = "sess-42", revision = 1, beatStartedAt = 1000 }
local actor = { body = body, record = record }
local beat = { durationMs = 1500, npc = { sceneId = "ambient.roam.eat" } }

local okOpera, operaReason = OperaAnim.Start(session, actor, beat)
T.equal(okOpera, true, "Choreography starts beat referencing registered sceneId")
T.equal(operaReason, "npc_animation_started", "opera start reason preserved")
T.equal(playedBumps[#playedBumps], "Pack_EatApple",
    "Choreography plays the modder AnimationPack's overridden bump")
T.equal(Driver.IsOwnedBy(body, "opera:sess-42"), true,
    "AnimationDriver tracks Choreography ownership token")

-- 4. Primitive anim_vars animations can be registered and played directly on
--    AnimationScenes too (with hand props)!
local okPrim, primDef = Scenes.Register("primitive.drink_apple", {
    route = "anim_vars",
    animVars = { action = "Drink", anim = "DrinkBottle" },
    durationMs = 1200,
    props = { primary = "Base.Apple" },
})
T.equal(okPrim, true, "primitive anim_vars scene registers on AnimationScenes")
T.equal(primDef.steps[1].route, "anim_vars",
    "step preserves route='anim_vars' without requiring a bump")
T.equal(primDef.steps[1].props.primary, "Base.Apple",
    "primitive anim_vars scene preserves hand props")

local okStartPrim, primReason = Driver.Start(body, record, {
    ownerToken = "scene:primitive.drink_apple",
    forceTakeover = true,
    route = primDef.steps[1].route,
    track = primDef.steps[1].animVars,
})
T.equal(okStartPrim, true, "AnimationDriver starts primitive anim_vars scene")
T.equal(primReason, "anim_vars_started", "anim_vars route executed cleanly")
