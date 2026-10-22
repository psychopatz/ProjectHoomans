local T = require "tests/support/test"

T.addPackagePaths()

local clearCalls = 0
PNC = {
    EnginePathPlanner = {
        Internal = {
            ClearEngineRequest = function()
                clearCalls = clearCalls + 1
            end,
        },
    },
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Pathing/PNC_EnginePathPlanner/"
        .. "PNC_EnginePathPlanner_Lifecycle.lua"
)

local navigation = {
    provider = "engine_path",
    nativeActive = false,
    requestPending = false,
}
local record = { runtime = { localNavigation = navigation } }

local invalidated, reason = PNC.EnginePathPlanner.Invalidate(
    record,
    "follow_hold",
    {}
)
T.falsy(invalidated, "inactive native route was invalidated again")
T.equal(reason, "native_already_inactive",
    "inactive native route exposes the idempotent result")
T.equal(clearCalls, 0, "inactive native route still ran native cleanup")

navigation.nativeActive = true
invalidated, reason = PNC.EnginePathPlanner.Invalidate(
    record,
    "follow_hold",
    {}
)
T.truthy(invalidated, "active native route was not invalidated")
T.equal(reason, nil, "active native invalidation changed its return contract")
T.equal(clearCalls, 1, "active native route did not run native cleanup")

T.finish("pnc_native_invalidate_idempotence_smoke")
