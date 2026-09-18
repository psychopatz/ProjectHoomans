local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
})

local now = 1000
local renewals = {}
local failID
local taskLease = {
    leaseId = "task-1", reservationId = "task-reservation",
}

PNC = {
    Core = {
        Now = function() return now end,
    },
    FacilityReservations = {
        Start = function(id, ttl)
            local key = tostring(id)
            renewals[key] = (renewals[key] or 0) + 1
            if key == failID then return false, "RESERVATION_NOT_FOUND" end
            T.equal(ttl, 30000, "Puppet reservation heartbeat TTL")
            return true
        end,
    },
    TaskLeaseService = {
        Get = function(id)
            if tostring(id or "") == "task-1" then
                return taskLease
            end
            return nil
        end,
        ForNPC = function() return taskLease end,
    },
    Tasking = {
        Internal = {
            MarkPuppetOperaResumed = function(lease, at)
                lease.puppetOperaResumeAt = at
            end,
        },
    },
}

local ActorControl = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/ActorControl/PNC_ActorControl.lua"
)
PNC.ActorControl = ActorControl
local Override = T.load(
    "ProjectHoomans",
    "server",
    "PNC/PuppetOpera/PNC_PuppetOpera_OverrideAdapter.lua"
)

local record = {
    id = "heartbeat-npc",
    runtime = {
        puppetOperaOverride = { sessionId = "session-1" },
        reservationId = "camp-reservation",
        taskLeaseId = "task-1",
        facilityActivity = {
            reservationId = "facility-reservation",
            taskLeaseId = "task-1",
        },
        roamAmbient = { reservationId = "ambient-reservation" },
        roamingSeat = { reservationId = "seat-reservation" },
    },
}
local session = { sessionId = "session-1" }
local actor = { record = record }

T.truthy(Override.Maintain(session, actor, now),
    "owner heartbeat did not renew existing provider reservations")
T.equal(renewals["camp-reservation"], 1,
    "camp reservation was not renewed")
T.equal(renewals["facility-reservation"], 1,
    "facility reservation was not renewed")
T.equal(renewals["ambient-reservation"], 1,
    "ambient reservation was not renewed")
T.equal(renewals["seat-reservation"], 1,
    "seat reservation was not renewed")
T.equal(renewals["task-reservation"], 1,
    "task lease reservation was not renewed")

T.truthy(Override.Maintain(session, actor, now + 5000),
    "heartbeat throttling rejected a healthy owner")
T.equal(renewals["camp-reservation"], 1,
    "heartbeat renewed before its bounded interval")

now = now + 10000
T.truthy(Override.Maintain(session, actor, now),
    "owner heartbeat failed after its renewal interval")
T.equal(renewals["camp-reservation"], 2,
    "heartbeat did not renew at the next interval")

failID = "seat-reservation"
now = now + 10000
local maintained, reason = Override.Maintain(session, actor, now)
T.falsy(maintained, "lost provider reservation was not surfaced")
T.contains(reason, "puppet_opera_reservation_lost",
    "reservation loss did not produce a Puppet ownership reason")
T.truthy(record.runtime.puppetOperaOverride.reservationLost,
    "reservation loss was not recorded on the owner state")

local released, releaseReason = Override.Release(session, actor)
T.truthy(released == true, releaseReason or "owner release failed")
T.equal(taskLease.puppetOperaResumeAt, now,
    "owner release did not hand the task watchdog a resume baseline")

return T.finish("pnc_puppet_opera_owner_heartbeat_smoke")
