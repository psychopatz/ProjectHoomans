local T = require "tests/support/test"

-- Verifies that individual need work is sliced across ticks instead of
-- processing the whole registry in one scheduler pump.

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local clock = 0
local updates = {}
local records = {}
for index = 1, 5 do
    local id = "npc:" .. tostring(index)
    records[id] = { id = id, alive = true }
end

PNC = {
    Core = { Now = function() return clock end },
    Registry = { Data = records, MarkDirty = function() end },
    Factions = { List = function() return {} end },
    GroupNeeds = {},
    IndividualNeeds = {
        IsEligible = function(record) return record.alive ~= false end,
        UpdateToNow = function(record)
            updates[#updates + 1] = record.id
            clock = clock + 1
        end,
        GetActivity = function() return "idle" end,
    },
    ConditionStats = {
        Ensure = function() return { lastUpdateWorldAge = 0 } end,
        Update = function() end,
    },
    NeedsUtils = { WorldAgeHours = function() return 1 end },
}

local root = T.path("ProjectHoomans", "root", "")
T.load(root .. "shared/PNC/Core/Needs/PNC_NeedsDefinitions.lua")
T.load(root .. "server/PNC/Needs/PNC_NeedsScheduler.lua")

local Scheduler = PNC.NeedsScheduler
local first = Scheduler.Pump(0)
T.equal(first, 2, "first slice processes only its time budget")
T.equal(#updates, 2, "first slice does not process the whole registry")

local second = Scheduler.Pump(clock)
T.equal(second, 2, "second slice resumes from the existing cursor")
T.equal(#updates, 4, "second slice continues without restarting")

local third = Scheduler.Pump(clock)
T.equal(third, 1, "final slice completes the cycle")
T.equal(#updates, 5, "all records are eventually processed")

local waiting = Scheduler.Pump(clock)
T.equal(waiting, 0, "completed cycle waits for the scheduler interval")

clock = 30000
local nextCycle = Scheduler.Pump(clock)
T.equal(nextCycle, 2, "next cycle starts on the configured cadence")
T.equal(#updates, 7, "next cycle resumes incremental processing")

T.finish("pnc_needs_scheduler_slicing_smoke")
