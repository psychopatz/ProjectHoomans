local ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"
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

dofile(ROOT .. "PNC_PathService/PNC_PathService_Context.lua")
dofile(ROOT .. "PNC_PathService/PNC_PathService_Facing.lua")

local faceCalls = 0
local body = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    faceLocation = function()
        faceCalls = faceCalls + 1
    end,
}
local lane = {}

assert(
    PNC.PathService.ApplyTravelFacing(body, lane, 1, 0, 100),
    "initial locomotion facing was not applied"
)
local angle = math.rad(2)
assert(
    PNC.PathService.ApplyTravelFacing(
        body,
        lane,
        math.cos(angle),
        math.sin(angle),
        140
    ),
    "small continuous heading change was suppressed"
)
assert(faceCalls == 2, "locomotion heading was not refreshed dynamically")

print("pnc_path_facing_smoothing_smoke: ok")
