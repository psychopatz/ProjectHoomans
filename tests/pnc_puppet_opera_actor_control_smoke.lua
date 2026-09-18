local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

PNC = {
    Core = {
        Now = function() return 1000 end,
    },
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/ActorControl/PNC_ActorControl.lua"
)

local Control = PNC.ActorControl
local record = {
    runtime = {
        puppetOperaLease = {
            sessionId = "scene-1",
        },
        puppetOperaMovement = {
            sessionId = "scene-1",
        },
        moveIntent = {
            kind = "move",
            reason = "puppet_opera:scene-1",
            puppetOperaSessionId = "scene-1",
        },
    },
}

local allowed, allowedReason = Control.CanWrite(
    record,
    nil,
    "ordinary_idle",
    { reason = "facility_work" }
)
T.falsy(allowed,
    "ordinary writer bypassed the active Puppet Opera lease")
T.contains(allowedReason, "puppet_opera_writer_blocked",
    "blocked writer did not expose an ownership reason")

T.truthy(Control.CanPump(record),
    "owned movement was not recognized as the active pump lane")
T.truthy(Control.CanWrite(
    record,
    Control.MakeOwner("scene-1"),
    "puppet_movement",
    { reason = "puppet_opera:scene-1" }
), "matching Puppet Opera writer was rejected")
T.truthy(Control.CanWrite(
    record,
    nil,
    "combat_safety",
    { reason = "combat_attack" }
), "combat safety writer did not retain priority")
T.truthy(Control.CanWrite(
    record,
    nil,
    "vehicle_safety",
    { reason = "vehicle_boarding" }
), "vehicle safety writer did not retain priority")

record.runtime.moveIntent.reason = "facility_work"
T.falsy(Control.CanPump(record),
    "movement pump remained allowed after its owner marker was replaced")

return T.finish("pnc_puppet_opera_actor_control_smoke")
