local T = require "tests/support/test"

local fenceVisible = false
local forward = {
    getX = function() return 1 end,
    getY = function() return 0 end,
}
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
local fence = {}

getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            if x == 0 and y == 0 and z == 0 then return fromSquare end
            if x == 1 and y == 0 and z == 0 then return toSquare end
            return nil
        end,
    }
end

PNC = {
    Core = { Now = function() return 1000 end },
    Const = {},
    TraversalQuery = {
        GetPassageBetween = function() return nil end,
        GetFenceBetween = function(from, to)
            if fenceVisible and from == fromSquare and to == toSquare then
                return fence, false
            end
            return nil, false
        end,
    },
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Pathing/PNC_EnginePathPlanner_Context.lua"
)

local body = {
    getX = function() return 0.5 end,
    getY = function() return 0.5 end,
    getZ = function() return 0 end,
    getForwardDirection = function() return forward end,
}
local navigation = {
    requestX = 3.5,
    requestY = 0.5,
    requestRevision = 1,
}

T.equal(
    PNC.EnginePathPlanner.Internal.GetUpcomingPathPassage(body, navigation),
    nil,
    "pre-route passage"
)
fenceVisible = true
navigation.lastBehaviorResult = "Working"
local passage =
    PNC.EnginePathPlanner.Internal.GetUpcomingPathPassage(body, navigation)
T.truthy(passage, "post-route passage reused stale negative cache")
T.equal(passage.object, fence, "post-route fence")

T.finish("pnc_native_passage_cache_smoke")
