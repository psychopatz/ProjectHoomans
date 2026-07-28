local FILE = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"
    .. "Pathing/PNC_FakeLocomotion.lua"

PNC = {
    Core = {
        Distance = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return math.sqrt((dx * dx) + (dy * dy))
        end,
    },
    LocomotionProfiles = {
        GetBaseProfile = function()
            return {
                speed = 1,
                moveAnim = "Walk",
            }
        end,
    },
    TraversalQuery = {
        -- Block every candidate that advances toward the goal. Lateral and
        -- return-to-origin candidates stay walkable, reproducing the old
        -- orbit/walk-in-place loop.
        CanStep = function(_, _, _, toX)
            if toX > 0.00001 then
                return false, "wall"
            end
            return true, "clear"
        end,
    },
    LiveBodyControl = {
        SetAuthoritativePosition = function(body, x, y, z)
            body.x = x
            body.y = y
            body.z = z
            return true
        end,
    },
}

dofile(FILE)

local body = {
    x = 0,
    y = 0,
    z = 0,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function(self) return self.z end,
    faceLocation = function() end,
}
local record = { x = 0, y = 0, z = 0 }
local lane = {
    mode = "walk",
    resolvedMode = "walk",
    lastStepAt = 0,
    lastProgressAt = 100,
}
local goal = { x = 1, y = 0, z = 0, mode = "walk" }
local result
local stalled = false

for index = 1, 40 do
    local moved
    moved, result = PNC.FakeLocomotion.StepTowardGoal(
        body,
        record,
        lane,
        goal,
        1000 + (index * 50)
    )
    if not moved and result == "stalled" then
        stalled = true
        break
    end
end

assert(stalled, "non-progress oscillation never became stalled")
assert(
    lane.lastProgressAt == 100,
    "lateral/return steps incorrectly refreshed goal progress"
)
assert(
    (tonumber(lane.nonProgressStepCount) or 0) >= 24,
    "non-progress steps were not accumulated"
)
assert(lane.lastStepLabel == "stalled", "stall was not exposed on lane")

PNC.TraversalQuery.CanStep = function()
    return true, "clear"
end
local facedX
local facedY
PNC.PathService = {
    ApplyTravelFacing = function(_, _, x, y)
        facedX = x
        facedY = y
        return true
    end,
}
body.x = 0
body.y = 0
record = { x = 0, y = 0, z = 0 }
lane = {
    mode = "walk",
    resolvedMode = "walk",
    lastStepAt = 1000,
    steeringDirX = 1,
    steeringDirY = 0,
}
local curvedMove = PNC.FakeLocomotion.StepTowardGoal(
    body,
    record,
    lane,
    { x = 0, y = 1, z = 0, mode = "walk" },
    1050
)
assert(curvedMove, "smoothed turn did not move")
assert(
    body.x > 0 and body.y > 0,
    "sharp waypoint turn snapped instead of blending its heading"
)
assert(
    math.sqrt((facedX * facedX) + (facedY * facedY)) >= 0.99,
    "locomotion facing still used the sub-threshold tiny step"
)

print("pnc_fake_locomotion_stall_smoke: ok")
