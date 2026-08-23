local T = require "tests/support/test"

PNC = {}
T.load("ProjectHoomans", "shared",
    "PNC/Core/Pathing/PNC_TraversalAction.lua")

local Contract = PNC.TraversalAction
local scripted = {
    twoPhase = true,
    phase = "up",
    startedAt = 1000,
    phaseStartedAt = 1000,
    upDurationMs = 420,
    travelDurationMs = 560,
}
local native = {
    twoPhase = true,
    phase = "up",
    startedAt = 1000,
    upFinishAt = 1420,
    crossingDurationMs = 560,
}

local function advance(action, now, observedPhase)
    local phase
    local progress
    local phaseStartedAt
    local crossPendingAt
    local startedCrossing
    phase,
        progress,
        phaseStartedAt,
        crossPendingAt,
        startedCrossing = Contract.Evaluate(
            action,
            now,
            observedPhase
        )
    action.phase = phase
    action.crossPendingAt = crossPendingAt
    if startedCrossing then
        action.phaseStartedAt = phaseStartedAt
        action.crossingStartedAt = phaseStartedAt
    end
    return phase, progress, startedCrossing
end

local phaseA, progressA = advance(scripted, 1200, "")
local phaseB, progressB = advance(native, 1200, "")
T.equal(phaseA, "up", "scripted raise phase")
T.equal(phaseB, phaseA, "native/scripted raise parity")
T.equal(progressA, 0, "raise phase progress")
T.equal(progressB, progressA, "native/scripted raise progress parity")

phaseA, progressA = advance(scripted, 1420, "transfer")
phaseB, progressB = advance(native, 1420, "transfer")
T.equal(phaseA, "cross_pending", "transfer event enters settle phase")
T.equal(phaseB, phaseA, "native/scripted transfer parity")
T.equal(progressA, 0, "settle phase progress")
T.equal(progressB, progressA, "native/scripted settle progress parity")

local startedA
local startedB
phaseA, progressA, startedA = advance(scripted, 1480, "")
phaseB, progressB, startedB = advance(native, 1480, "")
T.equal(phaseA, "cross", "scripted crossing phase")
T.equal(phaseB, phaseA, "native/scripted crossing parity")
T.truthy(startedA and startedB, "crossing transition signal")
T.equal(progressA, 0, "crossing starts at zero progress")
T.equal(progressB, progressA, "native/scripted crossing start parity")

phaseA, progressA = advance(scripted, 1700, "")
phaseB, progressB = advance(native, 1700, "")
T.equal(phaseB, phaseA, "native/scripted active phase parity")
T.near(progressB, progressA, 0.000001,
    "native/scripted crossing progress parity")

local untouched = { twoPhase = true, phase = "up", upFinishAt = 2000 }
Contract.Evaluate(untouched, 1500, "")
T.equal(untouched.phase, "up", "phase evaluator mutated its input")

T.finish("pnc_traversal_action_contract_smoke")
