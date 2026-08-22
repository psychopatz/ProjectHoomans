local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "server", "")
PsychopatzCore = { RuntimeRole = { AllowsServerCode = function() return true end } }
local now, id = 1000, 0
local records = {
    one = { id = "one", alive = true, needs = { fatigue = 0.85 }, runtime = {} },
    two = { id = "two", alive = true, needs = { fatigue = 0.85 }, runtime = {} },
}
PNC = { Core = {
    Now = function() return now end,
    GenerateID = function(prefix) id = id + 1; return prefix .. ":" .. id end,
    DeepCopy = function(value)
        if type(value) ~= "table" then return value end
        local output = {}; for key, item in pairs(value) do output[key] = item end
        return output
    end,
}, Registry = { Get = function(value) return records[value] end,
    ForEach = function(callback) for _, record in pairs(records) do callback(record) end end },
FacilityReservations = { ByID = {}, Release = function(reservationId)
    PNC.FacilityReservations.ByID[reservationId] = nil; return true
end }, }
Events = { OnTick = { Add = function() end } }

local Priority = T.load(ROOT .. "PNC/Tasking/PNC_TaskPriority.lua")
local Intent = T.load(ROOT .. "PNC/Tasking/PNC_TaskIntent.lua")
local Leases = T.load(ROOT .. "PNC/Tasking/PNC_TaskLeaseService.lua")
package.preload["PNC/Tasking/PNC_TaskPriority"] = function() return Priority end
package.preload["PNC/Tasking/PNC_TaskIntent"] = function() return Intent end
package.preload["PNC/Tasking/PNC_TaskLeaseService"] = function() return Leases end
package.preload["PNC/Tasking/PNC_TaskExecutors"] = function() return {} end
package.preload[
    "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityTriggers"
] = function() return {} end
local Tasking = T.load(ROOT .. "PNC/Tasking/PNC_Tasking.lua")

local available, facilityValid = true, true
Tasking.Commands.RegisterProvider("Needs", {
    GetCandidates = function(npcId) return {{ taskId = "sleep:" .. npcId,
        npcId = npcId, kind = "SLEEP", sourceDomain = "Needs",
        sourceRef = "fatigue", precedence = "CRITICAL_NEED", urgency = 0.85,
        capability = "sleep" }} end,
    Validate = function() return facilityValid end,
    Assign = function(intent)
        if not available then return nil, "NO_ACTIVITY_CAPACITY" end
        available = false
        local reservationId = "bed:1"
        PNC.FacilityReservations.ByID[reservationId] = true
        return { facilityId = "barracks", componentId = "bed",
            reservationId = reservationId, executionMode = "ABSTRACT" }
    end,
    Start = function() return true end,
    CanContinue = function(lease)
        return PNC.FacilityReservations.ByID[lease.reservationId] ~= nil
    end,
    Cancel = function() available = true end,
})
T.truthy(Tasking.Commands.Reevaluate("one", "NEED_STATE_CHANGED"))
local first = Tasking.Queries.GetLease("one")
T.truthy(first and first.facilitySlotId == "bed", "sleep must lease the bed slot")
local second, reason = Tasking.Commands.Reevaluate("two", "NEED_STATE_CHANGED")
T.truthy(not second and reason == "NO_ACTIVITY_CAPACITY",
    "two NPCs must not own the same bed")
Tasking.Commands.CancelForNPC("one", "test_cancel")
available = true
T.truthy(Tasking.Commands.Reevaluate("two", "FACILITY_SLOT_RELEASED"),
    "released bed should become assignable")
PNC.FacilityReservations.ByID["bed:1"] = nil
facilityValid = false
Tasking.Commands.Reevaluate("two", "FACILITY_DESTROYED")
T.truthy(Tasking.Queries.GetLease("two") == nil,
    "destroyed facility must invalidate its lease")
local diagnostics = Tasking.Queries.GetDiagnostics("two")
T.truthy(diagnostics.counters.reevaluations == 4
    and diagnostics.dirtyQueueLength == 0,
    "task diagnostics should remain bounded and read-only")
T.finish("pnc_tasking_sleep_smoke")

T.finish("pnc_tasking_sleep_smoke")
