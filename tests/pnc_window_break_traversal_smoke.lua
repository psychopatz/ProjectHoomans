local T = require "tests/support/test"

local FILE =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Pathing/PNC_PathService/PNC_PathService_TraversalRuntime.lua"

local now = 1000
local smashed = false
local finished = false

local zombie = {
    x = 0.5,
    y = 0.5,
    z = 0,
    variables = {},
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function(self) return self.z end,
    setX = function(self, value) self.x = value end,
    setY = function(self, value) self.y = value end,
    setZ = function(self, value) self.z = value end,
    setVariable = function(self, key, value)
        self.variables[key] = value
    end,
    getVariableBoolean = function(self, key)
        return self.variables[key] == true
    end,
    getVariableString = function(self, key)
        return tostring(self.variables[key] or "")
    end,
    getActionStateName = function() return "bumped" end,
    setTarget = function() end,
    setPath2 = function() end,
    setRunning = function() end,
}

local obstacle = {
    isSmashed = function() return smashed end,
}

PNC = {
    PathService = {
        Internal = {
            Core = { Now = function() return now end },
            syncRecordPosition = function(record, body)
                record.x = body:getX()
                record.y = body:getY()
                record.z = body:getZ()
            end,
            smashWindowForNPC = function(_, object)
                T.truthy(object == obstacle,
                    "window traversal lost its obstacle")
                smashed = true
                return true
            end,
        },
    },
    Animation = {
        PlayBump = function(_, _, bumpType)
            T.truthy(bumpType == "PNC_WindowSmash",
                "wrong window breach selector")
        end,
        FinishBump = function()
            finished = true
        end,
    },
    LiveBodyControl = {
        IsMultiplayer = function() return false end,
        SetManagedBodyUseless = function() end,
        SuppressZombieState = function() end,
        SetAuthoritativePosition = function(body, x, y, z)
            body:setX(x)
            body:setY(y)
            body:setZ(z)
        end,
    },
}

T.load(FILE)

local lane = {}
local record = { id = "window_breaker" }
T.truthy(PNC.PathService.Internal.beginTraversalAction(
    zombie,
    record,
    lane,
    {
        kind = "window_smash",
        anim = "PNC_WindowSmash",
        obstacle = obstacle,
        fromX = 0.5,
        fromY = 0.5,
        fromZ = 0,
        toX = 0.5,
        toY = 0.5,
        toZ = 0,
        travelDurationMs = 600,
        finishHoldMs = 200,
    }
), "window breach traversal did not start")

now = 1600
local active = PNC.PathService.Internal.updateTraversalAction(
    zombie,
    record,
    lane,
    now
)
T.truthy(active == true, "window breach released before animation tail")
T.truthy(smashed == true, "window was not smashed at breach impact")

now = 1850
active = PNC.PathService.Internal.updateTraversalAction(
    zombie,
    record,
    lane,
    now
)
T.truthy(active == false, "window breach ignored its hard timeout")
T.truthy(lane.traversalAction == nil,
    "window breach retained a stale traversal action")
T.truthy(finished == true, "window breach did not release its bump")
T.finish("pnc_window_break_traversal_smoke")

T.finish("pnc_window_break_traversal_smoke")
