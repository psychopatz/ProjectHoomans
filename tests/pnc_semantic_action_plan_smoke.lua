local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {}
PNC = {}

T.load(
    "PsychopatzCore",
    "common",
    "PsychopatzCore/Semantics/PsychopatzSemantic.lua"
)
local Plan = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticActionPlan.lua"
)

local plan, reason = Plan.Normalize({
    planID = "conversation:1",
    npcID = "npc:alice",
    source = "semantic_dialogue",
    rawText = "Eat your food, refill your bottle and go to sleep.",
    confidence = 0.96,
    steps = {
        {
            id = "eat",
            action = "EAT",
            parameters = {
                selector = { concept = "FOOD", owner = "actor" },
            },
        },
        {
            id = "refill",
            action = "REFILL",
            parameters = {
                selector = { concept = "WATER_CONTAINER", owner = "actor" },
            },
        },
        {
            id = "sleep",
            action = "SLEEP",
            parameters = { target = { concept = "SLEEP_SURFACE" } },
        },
    },
})

T.truthy(plan, "ordered plan normalizes")
T.equal(reason, nil, "valid plan has no normalization reason")
T.equal(plan.kind, "semantic_action_plan", "plan kind is stable")
T.equal(#plan.steps, 3, "all steps are retained")
T.equal(plan.steps[1].action, "EAT", "step action is canonical")
T.equal(plan.steps[2].parameters.selector.concept, "WATER_CONTAINER",
    "step parameters remain structured")

local valid, validationReason = Plan.Validate(plan)
T.equal(valid, true, "normalized plan validates")
T.equal(validationReason, plan, "validation returns the plan")

local started, startReason = Plan.Start(plan, 10)
T.equal(started, true, "plan starts")
T.equal(startReason, plan, "start returns the plan")
T.equal(plan.state, "RUNNING", "plan enters running state")
T.equal(plan.steps[1].state, "RESOLVING", "first step resolves first")

T.equal(Plan.SetStepState(plan, "EXECUTING", nil, 20), false,
    "resolution cannot skip assignment")

T.equal(Plan.SetStepState(plan, "ASSIGNED", { leaseID = "lease:1" }, 21),
    true, "step becomes assigned")
T.equal(Plan.SetStepState(plan, "TRAVEL", nil, 22), true,
    "assigned step enters travel")
T.equal(Plan.SetStepState(plan, "ARRIVED", { reason = "path_arrived" }, 23),
    true, "arrival is an explicit state")
T.equal(Plan.SetStepState(plan, "EXECUTING", nil, 24), true,
    "arrival transfers ownership to execution")
T.equal(Plan.SetStepState(plan, "COMPLETED", { itemID = "item:food" }, 25),
    true, "step completes")

local advanced, advanceReason = Plan.Advance(plan, { consumed = true }, 26)
T.equal(advanced, true, "completed step advances once")
T.equal(advanceReason, plan, "advance returns the plan")
T.equal(plan.currentStep, 2, "current step moves to the next action")
T.equal(plan.steps[2].state, "PENDING", "next action is pending")

local advancedAgain = Plan.Advance(plan, nil, 27)
T.equal(advancedAgain, false, "a step cannot advance before completion")

local paused, pauseReason = Plan.Pause(plan, "combat", 28)
T.equal(paused, true, "running plan pauses")
T.equal(pauseReason, plan, "pause returns the plan")
T.equal(plan.state, "PAUSED", "plan pause is durable")
T.equal(plan.steps[2].state, "PAUSED", "active step pauses")

local resumed = Plan.Resume(plan, 29)
T.equal(resumed, true, "paused plan resumes")
T.equal(plan.state, "RUNNING", "plan returns to running")
T.equal(plan.steps[2].state, "PENDING", "pending step resumes for re-resolution")

local cancelled = Plan.Cancel(plan, "new_command", 30)
T.equal(cancelled, true, "plan cancellation is explicit")
T.equal(plan.state, "CANCELLED", "cancelled plan is terminal")
T.equal(Plan.SetStepState(plan, "RESOLVING"), false,
    "terminal plans cannot mutate steps")

local tooMany = { planID = "conversation:many", npcID = "npc:alice", steps = {} }
for index = 1, Plan.MAX_STEPS + 1 do
    tooMany.steps[index] = { id = "step:" .. tostring(index), action = "WAIT" }
end
local rejected, rejectedReason = Plan.Normalize(tooMany)
T.falsy(rejected, "oversized plans are rejected")
T.equal(rejectedReason, "plan_steps_exceeded",
    "oversized plan failure is diagnosable")

local unsafe = Plan.Normalize({
    planID = "conversation:unsafe",
    npcID = "npc:alice",
    steps = {
        { id = "step:1", action = "SAY", parameters = { callback = function() end } },
    },
})
T.falsy(unsafe, "functions cannot enter a plan")

T.finish("pnc_semantic_action_plan_smoke")
