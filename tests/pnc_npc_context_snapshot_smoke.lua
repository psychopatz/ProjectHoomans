local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
})

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local liveLookups = 0
local sleepLookups = 0
local companionLookups = 0
local isTired = false

PNC = {
    Const = { ORDER_CAMP = "camp" },
    Core = { Now = function() return 2000 end },
    Registry = {
        GetLiveZombie = function()
            liveLookups = liveLookups + 1
            return { live = true }
        end,
    },
    CompanionCommands = {
        IsCompanion = function()
            companionLookups = companionLookups + 1
            return true
        end,
    },
    ActorControl = {
        IsPuppetOwned = function() return false end,
    },
    IndividualNeeds = {
        Queries = {
            GetSleepIntent = function()
                sleepLookups = sleepLookups + 1
                return isTired and { kind = "sleep" } or nil
            end,
        },
    },
    TaskLeaseService = {
        ForNPC = function() return nil end,
    },
}

local NPCContext = T.load("ProjectHoomans", "server",
    "PNC/Tasking/PNC_NPCContext.lua")
local FacilitySeat = T.load("ProjectHoomans", "server",
    "PNC/Tasking/Autonomy/Executors/PNC_AutonomyExecutor_FacilitySeat.lua")

local record = {
    id = "npc-ctx-1",
    alive = true,
    runtime = {},
    orderSpec = {
        kind = "camp",
        campId = "camp:1",
        placementState = "arrived",
    },
}

-- 1. One BeginEvaluation snapshot is reused across multiple consumers.
liveLookups = 0
sleepLookups = 0
companionLookups = 0
local active = NPCContext.BeginEvaluation(record, 2000)
T.truthy(active, "BeginEvaluation builds active snapshot")
T.equal(active.scope, "camp", "snapshot detects camp scope")
T.equal(active.campPlacementLocked, false, "arrived camp is not locked")

local ctxA = NPCContext.For(record)
local eligible, isCamp = FacilitySeat.IsEligible(record)
T.equal(ctxA, active, "NPCContext.For returns the exact active snapshot")
T.equal(eligible, true, "FacilitySeat accepts arrived camping companion")
T.equal(isCamp, true, "FacilitySeat reports camp scope from shared context")
T.equal(liveLookups, 1, "GetLiveZombie called once across consumers")
T.equal(sleepLookups, 1, "GetSleepIntent called once across consumers")
T.equal(companionLookups, 1, "IsCompanion called once across consumers")

NPCContext.EndEvaluation(record)
T.equal(NPCContext.GetActive(record), nil,
    "EndEvaluation clears active snapshot")

-- 2. Camp placement lock & sleep priority block FacilitySeat cleanly.
record.orderSpec.placementState = "moving"
T.equal(FacilitySeat.IsEligible(record), false,
    "moving camp placement blocks FacilitySeat via NPCContext")

record.orderSpec.placementState = "arrived"
isTired = true
T.equal(FacilitySeat.IsEligible(record), false,
    "actionable sleep need blocks FacilitySeat via NPCContext")
