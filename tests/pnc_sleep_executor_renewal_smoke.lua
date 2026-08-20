local T = require "tests/support/test"

local now = 1000
local renewals = 0
local executors = {}
local record = { id = "npc:1", runtime = {
    facilityActivity = { phase = "TRAVELLING" },
} }

PsychopatzCore = { RuntimeRole = {
    AllowsServerCode = function() return true end,
} }
PNC = {
    Core = { Now = function() return now end },
    Registry = { Get = function() return record end },
    FacilityReservations = {
        ByID = { ["bed:1"] = { id = "bed:1" } },
        Start = function(id, ttl)
            T.equal(id, "bed:1", "renewed reservation")
            T.equal(ttl, 30000, "renewal ttl")
            renewals = renewals + 1
            return true
        end,
    },
    Tasking = { Commands = {
        RegisterExecutor = function(name, executor) executors[name] = executor end,
        MarkDirty = function() error("valid sleep lease was invalidated") end,
    } },
    TaskLeaseService = { SetPhase = function(_, phase)
        T.equal(phase, "TRAVEL", "travelling sleep phase")
    end },
    NeedsUtils = { WorldAgeHours = function() return 1 end },
    IndividualNeeds = { Commands = {} },
}

local Subject = T.load("ProjectHoomans", "server", "PNC/Tasking/PNC_TaskExecutors.lua")

T.truthy(Subject, "subject did not load")
local lease = { leaseId = "lease:1", npcId = record.id,
    reservationId = "bed:1" }
T.truthy(executors.LIVE.Tick(lease), "live sleep executor remains valid")
T.equal(renewals, 1, "travel renews the bed before expiry")
now = 5000
T.truthy(executors.LIVE.Tick(lease), "renewal interval keeps lease alive")
T.equal(renewals, 1, "bed is not renewed on every tick")
now = 12000
T.truthy(executors.LIVE.Tick(lease), "later travel tick remains valid")
T.equal(renewals, 2, "bed renews again during long travel")

T.finish("pnc_sleep_executor_renewal_smoke")
