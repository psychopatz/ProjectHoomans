local T = require "tests/support/test"

local setting
local logs = 0
local traces = 0
local lastTrace

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
    DebugSettings = {
        Register = function(spec) setting = spec end,
        IsEnabled = function() return false end,
    },
    DebugTrace = {
        Record = function(value)
            traces = traces + 1
            lastTrace = value
        end,
    },
}

PNC = {
    Core = {
        Now = function() return 1000 end,
        LogInfo = function() logs = logs + 1 end,
    },
    Equipment = {
        GetActivePrimaryLease = function()
            return { owner = "work:FISHING", priority = 50 }
        end,
    },
    FishingService = {},
}

local Diagnostics = T.load("ProjectHoomans", "server",
    "PNC/Fishing/PNC_FishingService_Diagnostics.lua")
T.equal(setting.id, "ProjectHoomans.FishingAudit",
    "fishing audit setting is registered centrally")
T.falsy(Diagnostics.IsEnabled(), "fishing audit defaults disabled")
T.equal(setting.defaultEnabled, false, "fishing audit is opt-in")
T.equal(setting.runtimeMutable, true, "fishing audit is runtime mutable")

setting.apply(true)
local record = {
    id = "npc:1",
    runtime = {
        fishingAnimationRequest = {
            scene = "fishing.cast", ok = true, reason = "requested",
        },
    },
}
local job = { id = "job:1", npcId = "npc:1", zoneId = "zone:1",
    phase = "WAITING_FOR_TOOL", catches = 0, attemptIndex = 0 }
local body = {
    getModData = function()
        return { PNCActionPropStatus = { ok = true } }
    end,
}
T.truthy(Diagnostics.RecordTransition(record, job, body,
    "fishing_tool_not_equipped", { event = "tool_wait" }),
    "first fishing transition is recorded")
T.equal(lastTrace.data.leaseOwner, "work:FISHING",
    "diagnostics expose the active lease owner")
T.equal(lastTrace.data.leasePriority, 50,
    "diagnostics expose the active lease priority")
T.equal(lastTrace.data.animationScene, "fishing.cast",
    "diagnostics expose the requested fishing scene")
T.equal(lastTrace.data.animationRequest, true,
    "diagnostics expose the animation request result")
T.equal(lastTrace.data.actionPropAttach, "attached",
    "diagnostics expose action-prop attachment")
T.equal(logs, 1, "fishing transition logs once")
T.equal(traces, 1, "fishing transition enters the debug trace")
T.falsy(Diagnostics.RecordTransition(record, job, body,
    "fishing_tool_not_equipped", { event = "tool_wait" }),
    "unchanged fishing transition is deduplicated")

job.requiredWorkPoints = 100
job.workPoints = 12
job.attemptIndex = 1
local roll = { chance = 0.45, roll = 0.20, success = true }
T.truthy(Diagnostics.RecordAttempt(record, job, nil, roll, {
    itemType = "Base.FishFillet", output = "accepted",
    outputReason = "fishing_catch",
}), "fishing attempt records chance and outcome")
T.equal(logs, 2, "fishing attempt logs once")
T.equal(traces, 2, "fishing attempt enters the debug trace")
T.falsy(Diagnostics.RecordAttempt(record, job, nil, roll, {
    itemType = "Base.FishFillet", output = "accepted",
    outputReason = "fishing_catch",
}), "unchanged fishing attempt is deduplicated")

job.catches = 1
T.truthy(Diagnostics.RecordTransition(record, job, nil, "catch",
    { event = "catch" }), "catch event records its attempt")
T.equal(logs, 3, "distinct fishing event logs once")

setting.apply(false)
T.falsy(Diagnostics.IsEnabled(), "fishing audit can be disabled")

T.finish("pnc_fishing_diagnostics_smoke")
