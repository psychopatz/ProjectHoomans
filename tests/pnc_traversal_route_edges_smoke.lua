local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Pathing/"

instanceof = function(object, className)
    return object and object.__type == className
end

local function makeSquare(x, y)
    return {
        x = x,
        y = y,
        getX = function(self) return self.x end,
        getY = function(self) return self.y end,
        getZ = function() return 0 end,
        isFree = function() return true end,
        isSolid = function() return false end,
        isSolidTrans = function() return false end,
        getBuilding = function() return nil end,
        getRoom = function() return nil end,
        isWallTo = function() return false end,
        isBlockedTo = function() return false end,
    }
end

local squares = {
    ["0:0"] = makeSquare(0, 0),
    ["1:0"] = makeSquare(1, 0),
    ["2:0"] = makeSquare(2, 0),
    ["1:1"] = makeSquare(1, 1),
}
local cell = {
    getGridSquare = function(_, x, y)
        return squares[tostring(x) .. ":" .. tostring(y)]
    end,
}
getCell = function() return cell end

local door = {
    __type = "IsoDoor",
    IsOpen = function() return false end,
    isLocked = function() return false end,
    isLockedByKey = function() return false end,
    isBarricaded = function() return false end,
    isObstructed = function() return false end,
}
squares["0:0"].getDoorTo = function(_, other)
    return other == squares["1:0"] and door or nil
end

PNC = { Const = {} }

T.load(ROOT .. "PNC_TraversalQuery.lua")

local canPlan, kind = PNC.TraversalQuery.CanPlanStep(
    0.5, 0.5, 0, 1.5, 0.5, 0, cell, {}, {}
)
T.truthy(canPlan and kind == "door_open", "usable door was not routable")

door.isLocked = function() return true end
canPlan, kind = PNC.TraversalQuery.CanPlanStep(
    0.5, 0.5, 0, 1.5, 0.5, 0, cell, {}, {}
)
T.truthy(not canPlan and kind == "door_unusable", "locked door was routed")
door.isLocked = function() return false end
squares["0:0"].getDoorTo = function() return nil end

local window = {
    __type = "IsoWindow",
    IsOpen = function() return false end,
    isSmashed = function() return false end,
    isPermaLocked = function() return false end,
    isBarricaded = function() return false end,
}
squares["0:0"].getWindowTo = function(_, other)
    return other == squares["1:0"] and window or nil
end
canPlan, kind = PNC.TraversalQuery.CanPlanStep(
    0.5, 0.5, 0, 1.5, 0.5, 0, cell, {}, {}
)
T.truthy(canPlan and kind == "window_climb", "usable window was not routable")
squares["0:0"].getWindowTo = function() return nil end

squares["0:0"].getHoppableTo = function(_, other)
    return other == squares["1:0"] and window or nil
end
T.truthy(
    PNC.TraversalQuery.GetFenceBetween(squares["0:0"], squares["1:0"]) == nil,
    "window was incorrectly classified as a fence"
)
squares["0:0"].getHoppableTo = nil

local genericHoppable = {
    isHoppable = function() return true end,
}
squares["0:0"].getHoppableTo = function(_, other)
    return other == squares["1:0"] and genericHoppable or nil
end
T.truthy(
    PNC.TraversalQuery.GetFenceBetween(squares["0:0"], squares["1:0"]) == genericHoppable,
    "generic hoppable fence was rejected"
)
squares["0:0"].getHoppableTo = nil

local fenceProperties = {
    get = function(_, name)
        return name == "FenceTypeLow" and "Wood" or nil
    end,
}
local fence = {
    getProperties = function() return fenceProperties end,
    isHoppable = function() return true end,
}
squares["0:0"].getHoppableThumpable = function(_, northEdge)
    return northEdge == false and fence or nil
end
canPlan, kind = PNC.TraversalQuery.CanPlanStep(
    0.5, 0.5, 0, 1.5, 0.5, 0, cell, {}, {}
)
T.truthy(canPlan and kind == "fence_climb", "hoppable fence was not routable")
T.truthy(
    PNC.TraversalQuery.GetFenceBetween(squares["0:0"], squares["1:1"]) == nil,
    "diagonal fence lookup accepted a non-crossing edge"
)
local passageBody = {
    getX = function() return 0.1 end,
    getY = function() return 0.5 end,
    getZ = function() return 0 end,
}
T.truthy(
    PNC.TraversalQuery.FindPassageToward(
        passageBody, 2.5, 0.5, 0, cell
    ) == nil,
    "fence was selected before the body reached its edge"
)
passageBody.getX = function() return 0.5 end
T.truthy(
    PNC.TraversalQuery.FindPassageToward(
        passageBody, 2.5, 0.5, 0, cell
    ) ~= nil,
    "nearby fence edge was not selected"
)

local tallFenceProperties = {
    get = function(_, name)
        return name == "FenceTypeHigh" and "Metal" or nil
    end,
}
local tallFence = {
    getProperties = function() return tallFenceProperties end,
    isTallHoppable = function() return true end,
}
squares["0:0"].getHoppableTo = function(_, other)
    return other == squares["1:0"] and tallFence or nil
end
canPlan, kind = PNC.TraversalQuery.CanPlanStep(
    0.5, 0.5, 0, 1.5, 0.5, 0, cell, {}, {}
)
T.truthy(
    canPlan and kind == "fence_climb_tall",
    "pair-based tall hoppable fence was not routable"
)
T.finish("pnc_traversal_route_edges_smoke")
