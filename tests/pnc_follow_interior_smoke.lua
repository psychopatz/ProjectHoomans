local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local queryFile = T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Pathing/PNC_TraversalQuery.lua"
local companionInternalFile = T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_Internal.lua"
local formationFile = T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowFormation.lua"

local playerRegion = {}
local ownerSquare
local slotSquare
local record

local function square(x, y, indoor, region)
    return {
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return 0 end,
        isInARoom = function() return indoor end,
        getRoom = function() return nil end,
        getBuilding = function() return nil end,
        getIsoWorldRegion = function() return region end,
    }
end

ownerSquare = square(5, 5, true, playerRegion)
slotSquare = square(3, 5, false, nil)

getCell = function()
    return {
        getGridSquare = function(_, x, y)
            if x == 5 and y == 5 then return ownerSquare end
            if x == 3 and y == 5 then return slotSquare end
            return nil
        end,
    }
end

PNC = {
    Core = {
        Now = function() return 1000 end,
    },
    Const = {
        ORDER_FOLLOW = "follow",
        FOLLOW_SLOT_DISTANCE = 2.25,
        FOLLOW_SLOT_LATERAL = 1.15,
        FOLLOW_SLOT_ROW_DISTANCE = 0.85,
        FOLLOW_SLOT_ROW_LATERAL = 0.25,
        FOLLOW_SLOT_STOP_DISTANCE = 0.35,
        FOLLOW_INDOOR_APPROACH_DISTANCE = 1.6,
    },
    Registry = {
        ForEach = function(callback)
            callback(record)
        end,
    },
    BehaviorCompanion = { Internal = {} },
}

T.load(queryFile)
T.load(companionInternalFile)
T.load(formationFile)

local owner = {
    getX = function() return 5.5 end,
    getY = function() return 5.5 end,
    getZ = function() return 0 end,
    getForwardDirection = function()
        return {
            getX = function() return 1 end,
            getY = function() return 0 end,
        }
    end,
    getSquare = function() return ownerSquare end,
}

record = {
    id = "follow-interior",
    ownerOnlineID = 7,
    ownerUsername = "alice",
    orderSpec = { kind = "follow" },
    runtime = {},
}

local target = PNC.BehaviorCompanion.Internal.ResolveFollowSlot(
    record,
    owner,
    false
)
T.equal(target.x, owner:getX(),
    "player-built indoor follow target uses the owner square")
T.equal(target.y, owner:getY(),
    "player-built indoor follow target keeps the owner row")
T.equal(target.stopDistance, 1.6,
    "indoor follow approach uses the bounded approach distance")
T.equal(target.indoorApproach, true,
    "player-built indoor boundary marks an indoor approach")

T.finish("pnc_follow_interior_smoke")
