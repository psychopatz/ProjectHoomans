local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
})

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local TickRegistry = T.load("ProjectHoomans", "server",
    "PNC/Server/Server/PNC_Server_TickRegistry.lua")

-- 1. Priority ordering, phase isolation, idle skip, interval gating, unregister.
local order = {}
local isIdle = true
TickRegistry.Register("late_prep", {
    phase = "prepare",
    priority = 50,
    pump = function() order[#order + 1] = "late_prep" end,
})
TickRegistry.Register("early_prep", {
    phase = "prepare",
    priority = 10,
    pump = function() order[#order + 1] = "early_prep" end,
})
TickRegistry.Register("idle_finish", {
    phase = "finish",
    priority = 10,
    isIdle = function() return isIdle end,
    pump = function() order[#order + 1] = "idle_finish" end,
})
TickRegistry.Register("throttled_finish", {
    phase = "finish",
    priority = 20,
    intervalMs = 500,
    pump = function() order[#order + 1] = "throttled_finish" end,
})

local stages = {}
TickRegistry.PumpPhase("prepare", 1000, function(stage, fn, at)
    stages[#stages + 1] = stage
    fn(at)
end)
T.equal(#order, 2, "prepare phase runs both prepare pumps")
T.equal(order[1], "early_prep", "lower priority number runs first")
T.equal(order[2], "late_prep", "higher priority number runs second")
T.equal(stages[1], "tick_registry.early_prep",
    "profiler runner receives structured stage name")

order = {}
TickRegistry.PumpPhase("finish", 1000)
T.equal(#order, 1, "idle pump is skipped while throttled pump runs")
T.equal(order[1], "throttled_finish", "only non-idle finish pump runs")

order = {}
isIdle = false
TickRegistry.PumpPhase("finish", 1200)
T.equal(#order, 1, "throttled pump respects intervalMs while woken pump runs")
T.equal(order[1], "idle_finish", "woken pump executes once no longer idle")

order = {}
TickRegistry.PumpPhase("finish", 1600)
T.equal(#order, 2, "both finish pumps execute once interval elapses")

T.equal(TickRegistry.Unregister("early_prep"), true, "pump unregisters cleanly")
T.equal(#TickRegistry.List("prepare"), 1, "unregistered pump removed from list")

-- 2. Shared ActivityHelpers lifecycle primitives.
local releasedID
local interruptedReason
local clearedReason
local pathResetCalled = false

PNC = {
    FacilityReservations = {
        Release = function(id) releasedID = id end,
    },
    AnimationScenes = {
        Interrupt = function(_, _, reason) interruptedReason = reason end,
        ClearScene = function(rec, _, reason)
            clearedReason = reason
            rec.runtime.animationScene = nil
        end,
    },
    PathService = {
        Reset = function() pathResetCalled = true end,
    },
}

local Helpers = T.load("ProjectHoomans", "server",
    "PNC/World/WorldObjects/PNC_WorldObjectActivityHelpers.lua")

local state = { reservationId = "res-42", sceneId = "scene.sit" }
local record = { id = "npc-7", runtime = { animationScene = { id = "scene.sit" } } }
local runtimeObj = {}

Helpers.BindLiveObject(runtimeObj, record, { obj = true })
T.truthy(runtimeObj.LiveObjects["npc-7"], "BindLiveObject stores live object")
Helpers.ClearLiveObject(runtimeObj, record)
T.equal(runtimeObj.LiveObjects["npc-7"], nil, "ClearLiveObject removes live object")

Helpers.ReleaseReservation(state, "done")
T.equal(releasedID, "res-42", "ReleaseReservation calls FacilityReservations.Release")
T.equal(state.reservationId, nil, "ReleaseReservation clears state.reservationId")

T.equal(Helpers.InterruptScene(record, nil, state, "combat", "stop_seat"), true,
    "InterruptScene interrupts matching active scene")
T.equal(interruptedReason, "combat", "InterruptScene forwards interrupt reason")
T.equal(clearedReason, "stop_seat", "InterruptScene clears lingering scene")

Helpers.ResetPath(record, nil, "done")
T.equal(pathResetCalled, true, "ResetPath falls back to PathService.Reset")
