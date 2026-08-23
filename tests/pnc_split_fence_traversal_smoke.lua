local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

local now = 1000
local bumpTypes = {}
local finished = false

local fromSquare = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}
local toSquare = {
    getX = function() return 1 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}
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

PNC = {
    Core = { Now = function() return now end },
    PathService = {
        Internal = {
            Core = { Now = function() return now end },
            syncRecordPosition = function(record, body)
                record.x = body:getX()
                record.y = body:getY()
                record.z = body:getZ()
            end,
        },
    },
    Animation = {
        PlayBump = function(_, _, bumpType)
            bumpTypes[#bumpTypes + 1] = bumpType
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

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Pathing/PNC_TraversalAction.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Pathing/PNC_PathService/PNC_PathService_TraversalRuntime.lua"
)

local lane = {}
local record = { id = "split-fence" }
T.truthy(PNC.PathService.Internal.beginTraversalAction(
    zombie,
    record,
    lane,
    {
        kind = "fence_climb",
        anim = "PNC_ClimbFence",
        startAnim = "PNC_LegacyClimbFenceStart",
        endAnim = "PNC_LegacyClimbFenceEnd",
        upDurationMs = 420,
        crossingDurationMs = 560,
        finishHoldMs = 320,
        fromX = 0.5,
        fromY = 0.5,
        fromZ = 0,
        toX = 1.5,
        toY = 0.5,
        toZ = 0,
        fromSquare = fromSquare,
        toSquare = toSquare,
        travelDurationMs = 600,
    }
), "split fence traversal did not start")
T.equal(bumpTypes[1], "PNC_LegacyClimbFenceStart",
    "split fence did not start with the raise clip")

now = 1200
T.truthy(PNC.PathService.Internal.updateTraversalAction(
    zombie, record, lane, now
), "raise phase ended early")
T.equal(zombie.x, 0.5, "raise phase moved before the transfer event")

zombie.variables.PNCTraversalPhase = "transfer"
now = 1420
T.truthy(PNC.PathService.Internal.updateTraversalAction(
    zombie, record, lane, now
), "crossing phase did not start")
T.equal(bumpTypes[2], nil,
    "split fence changed clips before the transition settled")
T.equal(lane.traversalAction.phase, "cross_pending",
    "split fence did not hold the transition boundary")
T.equal(zombie.x, 0.5, "crossing did not begin at the fence contact")

now = 1480
T.truthy(PNC.PathService.Internal.updateTraversalAction(
    zombie, record, lane, now
), "split fence did not resume after the transition settled")
T.equal(bumpTypes[2], "PNC_LegacyClimbFenceEnd",
    "split fence did not select the landing clip")
T.equal(lane.traversalAction.phase, "cross",
    "split fence did not enter its crossing phase")

now = 1700
T.truthy(PNC.PathService.Internal.updateTraversalAction(
    zombie, record, lane, now
), "crossing phase was released before the landing clip")
T.truthy(zombie.x > 0.5 and zombie.x < 1.5,
    "crossing phase did not move toward the landing square")

zombie.variables.PNCTraversalPhase = "finished"
zombie.variables.BumpAnimFinished = true
now = 2050
T.falsy(PNC.PathService.Internal.updateTraversalAction(
    zombie, record, lane, now
), "split fence did not finish after crossing")
T.equal(zombie.x, 1.5, "split fence did not land on the other side")
T.falsy(lane.traversalAction, "split fence action was not cleared")
T.truthy(finished, "split fence did not release its bump")

-- Missing XML phase/finish events must still complete on the bounded
-- profile deadline. This characterizes the fallback before phase policy is
-- extracted from the scripted executor.
finished = false
zombie.variables = {}
zombie.x = 0.5
zombie.y = 0.5
now = 3000
T.truthy(PNC.PathService.Internal.beginTraversalAction(
    zombie,
    record,
    lane,
    {
        kind = "fence_climb",
        anim = "PNC_ClimbFence",
        startAnim = "PNC_LegacyClimbFenceStart",
        endAnim = "PNC_LegacyClimbFenceEnd",
        upDurationMs = 420,
        crossingDurationMs = 560,
        finishHoldMs = 320,
        fromX = 0.5,
        fromY = 0.5,
        fromZ = 0,
        toX = 1.5,
        toY = 0.5,
        toZ = 0,
        fromSquare = fromSquare,
        toSquare = toSquare,
        travelDurationMs = 600,
    }
), "timeout traversal did not start")
now = 3420
T.truthy(PNC.PathService.Internal.updateTraversalAction(
    zombie, record, lane, now
), "deadline did not enter the pending handoff")
T.equal(lane.traversalAction.phase, "cross_pending",
    "missing transfer event did not use the profile deadline")
now = 3480
T.truthy(PNC.PathService.Internal.updateTraversalAction(
    zombie, record, lane, now
), "timeout traversal did not enter crossing")
now = 4300
T.falsy(PNC.PathService.Internal.updateTraversalAction(
    zombie, record, lane, now
), "missing finish event pinned scripted traversal")
T.equal(lane.lastTraversalFinishReason, "hard_timeout",
    "scripted timeout completion reason")
T.equal(zombie.x, 1.5, "timeout traversal did not reach its landing")
T.truthy(finished, "timeout traversal did not release its bump")

T.finish("pnc_split_fence_traversal_smoke")
