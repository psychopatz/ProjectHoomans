local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Pathing/"

PNC = {
    Core = {
        Now = function() return 0 end,
        Distance = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return math.sqrt((dx * dx) + (dy * dy))
        end,
    },
    PathService = {
        Internal = {},
    },
}

T.load(ROOT .. "PNC_PathService/PNC_PathService_Context.lua")
T.load(ROOT .. "PNC_PathService/PNC_PathService_Facing.lua")

local faceCalls = 0
local body = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    faceLocation = function()
        faceCalls = faceCalls + 1
    end,
}
local lane = {}

T.truthy(
    PNC.PathService.ApplyTravelFacing(body, lane, 1, 0, 100),
    "initial locomotion facing was not applied"
)
local angle = math.rad(2)
T.truthy(
    PNC.PathService.ApplyTravelFacing(
        body,
        lane,
        math.cos(angle),
        math.sin(angle),
        140
    ),
    "small continuous heading change was suppressed"
)
T.truthy(faceCalls == 2, "locomotion heading was not refreshed dynamically")

local traversalLane = {}
PNC.PathService.Internal.noteTraversalAttempt(
    traversalLane,
    "fence_climb",
    "fence:10:10:0",
    10.5,
    9.5,
    0,
    10.5,
    10.5,
    0,
    1000,
    1
)
T.truthy(PNC.PathService.Internal.isRepeatedTraversalAttempt(
    traversalLane,
    "fence:10:10:0",
    10.5,
    11.5,
    0,
    99,
    1200
), "moving goal allowed an immediate reverse fence crossing")
T.finish("pnc_path_facing_smoothing_smoke")
