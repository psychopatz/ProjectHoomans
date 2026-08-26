local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local now = 1000
local combatBumpActive = false

PNC = {
    Core = {
        Now = function() return now end,
    },
    Animation = {
        IsCombatBumpActionActive = function()
            return combatBumpActive
        end,
    },
    PathService = { Internal = {} },
}
PNC.PathService.Internal.Core = PNC.Core
PNC.PathService.Internal.Animation = PNC.Animation

T.load("ProjectHoomans", "shared",
    "PNC/Core/Pathing/PNC_PathService/Context/PNC_PathService_Context_WorldState.lua")

local Internal = PNC.PathService.Internal
local record = { runtime = {} }
local body = {}

T.falsy(
    Internal.hasActiveAttack(record, now, body),
    "non-combat bump lease blocked pathing"
)

combatBumpActive = true
T.truthy(
    Internal.hasActiveAttack(record, now, body),
    "combat bump lease did not block pathing"
)

record.runtime.attackAction = { finishAt = 1200 }
combatBumpActive = false
T.truthy(
    Internal.hasActiveAttack(record, now, body),
    "authoritative attack action was ignored"
)

now = 1300
T.falsy(
    Internal.hasActiveAttack(record, now, body),
    "expired authoritative attack action remained active"
)

T.finish("pnc_pathing_bump_classification_smoke")
