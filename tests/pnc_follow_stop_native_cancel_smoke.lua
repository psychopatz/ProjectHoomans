local T = require "tests/support/test"

PNC = {
    Core = { Now = function() return 1000 end },
    Const = { PRESENCE_LIVE = "live" },
    PathService = {},
    BehaviorMoveIntent = {
        Hold = function(record, reason)
            record.runtime.moveIntent = {
                kind = "hold",
                reason = reason,
            }
        end,
    },
    EnginePathPlanner = {
        Invalidate = function(record, reason, body)
            record.runtime.localNavigation.nativeActive = false
            record.runtime.localNavigation.invalidatedReason = reason
            body.path2 = nil
            return true
        end,
    },
    Equipment = {},
    Combat = {},
    NavigationRouter = {},
}

T.load("ProjectHoomans", "shared",
    "PNC/Core/Behaviors/PNC_Behavior_Common.lua")

local body = { path2 = {} }
local navigation = {
    provider = "engine_path",
    nativeActive = true,
}
local record = {
    presenceState = PNC.Const.PRESENCE_LIVE,
    runtime = { localNavigation = navigation },
}

PNC.BehaviorCommon.HaltMovement(record, body, "follow_hold")

T.equal(record.runtime.moveIntent.kind, "hold",
    "follow stop did not publish a hold intent")
T.equal(navigation.invalidatedReason, "follow_hold",
    "follow stop did not invalidate the native route")
T.falsy(navigation.nativeActive,
    "follow stop left native movement active")
T.falsy(body.path2,
    "follow stop left path2 attached to the body")
T.finish("pnc_follow_stop_native_cancel_smoke")
