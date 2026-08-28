local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")
local warnings = {}

PNC = {
    Core = {
        LogWarn = function(message) warnings[#warnings + 1] = message end,
    },
    Persistence = { Internal = {} },
}

local Repairs = T.load(ROOT ..
    "Persistence/PNC_Persistence/PNC_Persistence_Repairs.lua")

local calls = 0
local changed, applied, failures
Repairs.Register("test_scope", "normalize", 1, function(object)
    calls = calls + 1
    if object.value == 1 then return false, "already_normal" end
    object.value = 1
    return true, "normalized"
end)

local object = { value = 0, persistenceRepairVersions = {} }
changed, applied, failures = Repairs.Apply("test_scope", object,
    { objectId = "object:1" })
T.truthy(changed, "repair reports a state change")
T.equal(applied, 1, "repair revision is applied")
T.equal(failures, 0, "successful repair has no failures")
T.equal(object.value, 1, "repair normalizes state")
T.equal(calls, 1, "repair runs once")
T.equal(object.persistenceRepairVersions.normalize, 1,
    "repair revision is recorded")

Repairs.Register("test_scope", "normalize", 2, function(object, _, version)
    T.equal(version, 1, "next repair revision receives the prior version")
    object.value = 2
    return true, "normalized_again"
end)
changed, applied, failures = Repairs.Apply("test_scope", object,
    { objectId = "object:1" })
T.truthy(changed, "new repair revision changes the state")
T.equal(applied, 1, "new repair revision is applied")
T.equal(failures, 0, "new repair revision has no failures")
T.equal(object.value, 2, "new repair revision runs after the old revision")
T.equal(object.persistenceRepairVersions.normalize, 2,
    "latest repair revision is recorded")

changed, applied, failures = Repairs.Apply("test_scope", object,
    { objectId = "object:1" })
T.falsy(changed, "applied repair is not rerun")
T.equal(applied, 0, "no duplicate repair application")
T.equal(failures, 0, "repeat apply has no failures")
T.equal(calls, 1, "revision ledger prevents duplicate work")

local failed = true
Repairs.Register("test_scope", "retryable", 1, function()
    if failed then error("temporary repair failure") end
    return true, "retried"
end)
changed, applied, failures = Repairs.Apply("test_scope", object,
    { objectId = "object:1" })
T.falsy(changed, "failed repair does not claim a change")
T.equal(applied, 0, "failed repair does not advance revision")
T.equal(failures, 1, "failed repair is reported")
T.equal(object.persistenceRepairVersions.retryable, nil,
    "failed repair remains pending")
T.equal(#warnings, 1, "failed repair is logged")

failed = false
changed, applied, failures = Repairs.Apply("test_scope", object,
    { objectId = "object:1" })
T.truthy(changed, "retry succeeds")
T.equal(applied, 1, "retry advances revision")
T.equal(failures, 0, "successful retry has no failures")
T.equal(object.persistenceRepairVersions.retryable, 1,
    "retried revision is recorded")

local activity = {
    orderSpec = { kind = "facility_activity", taskLeaseId = "stale" },
    runtime = {
        facilityActivity = { taskLeaseId = "stale" },
        facilityDebugWork = { taskLeaseId = "stale" },
    },
    persistenceRepairVersions = {},
}
changed, applied, failures = Repairs.Apply("npc_record", activity,
    { objectId = "npc:activity" })
T.truthy(changed, "facility activity repair changes stale state")
T.equal(applied, 1, "facility repair revision is applied")
T.equal(failures, 0, "facility repair has no failures")
T.equal(activity.orderSpec, nil, "stale facility order is cleared")
T.equal(activity.runtime.facilityActivity, nil,
    "stale facility runtime is cleared")
T.equal(activity.runtime.facilityDebugWork, nil,
    "stale facility debug runtime is cleared")
T.equal(activity.persistenceRepairVersions.facility_activity_runtime, 1,
    "facility repair revision is recorded")

local normal = {
    orderSpec = { kind = "colony_home" },
    runtime = {}, persistenceRepairVersions = {},
}
changed, applied, failures = Repairs.Apply("npc_record", normal,
    { objectId = "npc:normal" })
T.falsy(changed, "normal order does not change")
T.equal(applied, 1, "normal record still records the repair revision")
T.equal(normal.orderSpec.kind, "colony_home", "normal order is preserved")

T.finish("pnc_persistence_repairs_smoke")
