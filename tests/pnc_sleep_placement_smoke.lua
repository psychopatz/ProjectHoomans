local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "PsychopatzCore", "common" },
})

local squares = {}
local other = {}
local blocked = false
local body = { x = 10.5, y = 20.5, z = 0 }
function body:getX() return self.x end
function body:getY() return self.y end
function body:getZ() return self.z end

local function square(free, moving)
    return {
        isFree = function() return free end,
        getMovingObjects = function() return moving or {} end,
    }
end

getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            return squares[tostring(x) .. ":" .. tostring(y) .. ":"
                .. tostring(z)] or blocked and square(true, { other })
        end,
    }
end

PNC = {
    Core = {
        IsAuthority = function() return true end,
        Distance = function(x1, y1, x2, y2)
            local dx, dy = x2 - x1, y2 - y1
            return math.sqrt(dx * dx + dy * dy)
        end,
    },
    LiveBodyControl = {
        SetAuthoritativePosition = function(target, x, y, z)
            target.x, target.y, target.z = x, y, z
        end,
    },
}

squares["10:20:0"] = square(true, { body })
local placement = require
    "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_SleepPlacement"
local Internal = PNC.FacilityJobsBehaviorInternal
local record = { id = "npc:placement", runtime = {} }
local runtime = {
    capability = "sleep", positioned = false,
    approachCandidates = {},
    approachPosition = nil,
}
local order = {
    capability = "sleep", x = 10.5, y = 20.5, z = 0,
    interactionX = 11.5, interactionY = 20.5, interactionZ = 0,
    sleepAnchorX = 11, sleepAnchorY = 20.5, sleepGridWidth = 2,
    sleepGridHeight = 1,
}
T.truthy(placement == Internal, "sleep placement module exports its internal API")
local entered, entryReason = Internal.TrySnapToSleep(
    record, body, runtime, order)
T.truthy(entered, "sleep entry snaps from a valid approach square")
T.equal(entryReason, "SLEEP_POSITIONED", "sleep entry reports its snap state")
T.equal(body.x, 11.5, "sleep entry writes the interaction pose")

squares["10:20:0"] = square(true, {})
local exit, exitReason = Internal.FindSleepExit(record, body, runtime, order)
T.truthy(exit, "sleep wake finds a free exit square")
T.equal(exitReason, nil, "free sleep exit has no rejection reason")
local exited = Internal.CommitSleepExit(record, body, runtime, exit)
T.truthy(exited, "sleep wake commits the validated exit square")
T.equal(body.x, 10.5, "sleep wake returns to the free approach square")

squares["10:20:0"] = square(true, { other })
blocked = true
runtime.positioned = true
runtime.approachPosition = { x = 10.5, y = 20.5, z = 0 }
local blockedExit, blockedReason = Internal.FindSleepExit(
    record, body, runtime, order)
T.equal(blockedExit, nil, "occupied sleep exit is not selected")
T.equal(blockedReason, "SLEEP_SQUARE_OCCUPIED",
    "occupied sleep exit reports the moving-object guard")

blocked = false
local floorBody = { x = 30.5, y = 40.5, z = 0 }
function floorBody:getX() return self.x end
function floorBody:getY() return self.y end
function floorBody:getZ() return self.z end
squares["30:40:0"] = square(true, { floorBody })
local floorRecord = { id = "npc:floor-placement", runtime = {} }
local floorRuntime = {
    capability = "sleep", positioned = false,
    approachPosition = nil, approachCandidates = {},
}
local floorOrder = {
    capability = "sleep", x = 30.5, y = 40.5, z = 0,
}
local floorEntered, floorEntryReason = Internal.TrySnapToSleep(
    floorRecord, floorBody, floorRuntime, floorOrder)
T.truthy(floorEntered, "floor sleep records its live approach position")
T.equal(floorEntryReason, "SLEEP_APPROACH_RECORDED",
    "floor sleep reports its non-object placement state")
T.truthy(floorRuntime.approachPosition,
    "floor sleep retained a wake position")
floorRuntime.approachPosition = nil
local floorExit, floorExitReason = Internal.FindSleepExit(
    floorRecord, floorBody, floorRuntime, floorOrder)
T.truthy(floorExit, "floor sleep finds the current free body square")
T.equal(floorExitReason, nil,
    "floor sleep current-square exit has no rejection reason")
T.truthy(Internal.CommitSleepExit(
    floorRecord, floorBody, floorRuntime, floorExit),
    "floor sleep commits its validated exit")
T.equal(floorBody.x, 30.5,
    "floor sleep exit keeps the body in the validated free square")

T.finish("pnc_sleep_placement_smoke")
