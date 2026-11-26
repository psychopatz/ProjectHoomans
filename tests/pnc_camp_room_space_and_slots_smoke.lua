local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
})

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local nowMs = 1000
getTimestampMs = function() return nowMs end

local function makeRoom(id, name, minX, minY, width, height, building, options)
    options = options or {}
    local squares = {}
    local grid = {}
    local room = { id = id, squareListCalls = 0, freeChecks = 0 }
    local def = {
        getIDString = function() return id end,
        getName = function() return name end,
        getX = function() return minX end,
        getY = function() return minY end,
        getX2 = function() return minX + width end,
        getY2 = function() return minY + height end,
        getZ = function() return 0 end,
    }
    local blocked = options.blocked or {}
    local doors = options.doors or {}
    for x = minX, minX + width - 1 do
        for y = minY, minY + height - 1 do
            local key = tostring(x) .. ":" .. tostring(y)
            local isBlocked = blocked[key] == true
            local doorDir = doors[key]
            local sq = {
                x = x,
                y = y,
                getX = function() return x end,
                getY = function() return y end,
                getZ = function() return 0 end,
                getRoom = function() return room end,
                isInARoom = function() return true end,
                isFree = function()
                    room.freeChecks = room.freeChecks + 1
                    return not isBlocked
                end,
                isDoorTo = function(_, other)
                    return doorDir ~= nil and other == doorDir.target
                end,
                isBlockedTo = function(_, other)
                    if doorDir ~= nil and other == doorDir.target then
                        return false
                    end
                    return true
                end,
            }
            if doorDir then
                sq[doorDir.method] = function() return doorDir.target end
            end
            squares[#squares + 1] = sq
            grid[key] = sq
        end
    end
    room.getRoomDef = function() return def end
    room.getName = function() return name end
    room.getBuilding = function() return building end
    room.getSquares = function()
        room.squareListCalls = room.squareListCalls + 1
        return squares
    end
    room.getFreeTile = function() return squares[1] end
    room._grid = grid
    room._squares = squares
    return room
end

local building = {
    getID = function() return "bldg-shop" end,
    getDef = function()
        return { getIDString = function() return "bldg-shop" end }
    end,
    isToxic = function() return false end,
    isResidential = function() return false end,
    rooms = {},
}

local outsideDoorTarget = {
    getX = function() return 19 end,
    getY = function() return 14 end,
    getZ = function() return 0 end,
    getRoom = function() return nil end,
    isInARoom = function() return false end,
}

-- Tiny 2x4 hallway right next to an 8x8 main room in the same building.
local hallway = makeRoom("hall-1", "hallway", 10, 10, 2, 4, building)
local mainRoom = makeRoom("shop-1", "store", 20, 10, 8, 8, building, {
    doors = {
        ["20:14"] = { method = "getW", target = outsideDoorTarget },
    },
})
building.rooms = { hallway, mainRoom }

local allSquares = {}
for _, r in ipairs(building.rooms) do
    for k, sq in pairs(r._grid) do allSquares[k .. ":0"] = sq end
end

local cell = {
    getBuildingList = function() return { building } end,
    getGridSquare = function(_, x, y, z)
        return allSquares[tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)]
    end,
}
getCell = function() return cell end

local Geometry = T.load("ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticCampSiteGeometry.lua")

-- 1. Standing in a tiny hallway prefers the large room in the same building.
local playerInHall = {
    getX = function() return 10.5 end,
    getY = function() return 11.5 end,
    getZ = function() return 0 end,
    getCurrentSquare = function() return hallway._grid["10:11"] end,
}
local chosen, err = Geometry.FindNearestRoom(cell, playerInHall, {}, {
    radius = 24,
    groupSize = 5,
})
T.equal(err, nil, "room search succeeds from a cramped hallway")
T.truthy(chosen, "a camp site is returned")
T.equal(chosen.roomID, "shop-1",
    "large open room beats cramped hallway in the same building")
T.truthy(chosen.capacity >= 60, "large room reports real usable floor capacity")
T.falsy(chosen.narrow, "8x8 room is not flagged as narrow")

-- 2. Anchor sits in the open interior, away from the doorway at (20, 14).
local doorDist = math.abs(math.floor(chosen.movementX) - 20)
    + math.abs(math.floor(chosen.movementY) - 14)
T.truthy(doorDist >= 3,
    "room anchor stays well away from the doorway tile (20, 14)")
T.truthy(chosen.slots and #chosen.slots >= 5,
    "large room provides spaced interior slots for a 5-member group")

-- 3. Performance: two-phase selection only runs detailed floor analysis on
--    a bounded number of finalists when many rooms are present.
Geometry.ClearRoomAnalysisCache()
local manyBuilding = {
    getID = function() return "bldg-many" end,
    getDef = function()
        return { getIDString = function() return "bldg-many" end }
    end,
    isToxic = function() return false end,
    isResidential = function() return true end,
    rooms = {},
}
local manySquares = {}
for i = 1, 12 do
    local w = i == 12 and 8 or 3
    local h = i == 12 and 8 or 3
    local r = makeRoom("rm-" .. tostring(i), "room" .. tostring(i),
        100 + i * 4, 100, w, h, manyBuilding)
    manyBuilding.rooms[#manyBuilding.rooms + 1] = r
    for k, sq in pairs(r._grid) do manySquares[k .. ":0"] = sq end
end
local manyCell = {
    getBuildingList = function() return { manyBuilding } end,
    getGridSquare = function(_, x, y, z)
        return manySquares[tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)]
    end,
}
local outsideOrigin = {
    getX = function() return 100.5 end,
    getY = function() return 98.5 end,
    getZ = function() return 0 end,
}
local manyBest = Geometry.FindNearestRoom(manyCell, outsideOrigin, {}, {
    radius = 60,
    groupSize = 5,
})
T.truthy(manyBest, "multi-room selection resolves a room")
T.equal(manyBest.roomID, "rm-12", "largest room wins among 12 candidates")
local analyzedCount = 0
for i = 1, #manyBuilding.rooms do
    if manyBuilding.rooms[i].freeChecks > 0 then
        analyzedCount = analyzedCount + 1
    end
end
T.truthy(analyzedCount <= Geometry.MAX_DETAILED_ROOMS,
    "detailed square analysis is capped to MAX_DETAILED_ROOMS finalists")

-- 4. Analysis cache avoids re-scanning the same room within ANALYSIS_CACHE_MS.
local firstAnalysis = Geometry.AnalyzeRoom(mainRoom, chosen.roomBounds, cell)
T.truthy(firstAnalysis, "initial analysis after cache clear succeeds")
local checksBefore = mainRoom.freeChecks
local cachedAnalysis = Geometry.AnalyzeRoom(mainRoom, chosen.roomBounds, cell)
T.truthy(cachedAnalysis, "cached analysis is returned")
T.equal(mainRoom.freeChecks, checksBefore,
    "cached room analysis does not re-iterate room squares")

-- 5. Group camp coordinator spreads members across distinct room slots and
--    does not mark a member arrived on the doorway tile.
local records = {}
local bodies = {}
local now = 0
local function makeNPC(id, x, y)
    local rec = {
        id = id,
        alive = true,
        presenceState = "live",
        x = x,
        y = y,
        z = 0,
        runtime = {},
    }
    local body = { id = id, x = x, y = y, z = 0, sq = nil }
    function body:getX() return self.x end
    function body:getY() return self.y end
    function body:getZ() return self.z end
    function body:isDead() return false end
    function body:getCurrentSquare() return self.sq end
    records[id] = rec
    bodies[id] = body
    return rec
end

local group = {}
for i = 1, 5 do
    group[i] = makeNPC("npc-" .. tostring(i), 18, 14)
end

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        ORDER_CAMP = "camp",
        CAMP_RADIUS = 3,
        CAMP_STOP_DISTANCE = 0.45,
        JOB_AT_CAMP = "AtCamp",
    },
    Core = {
        Now = function() return now end,
        Distance = function(x1, y1, x2, y2)
            local dx = (tonumber(x2) or 0) - (tonumber(x1) or 0)
            local dy = (tonumber(y2) or 0) - (tonumber(y1) or 0)
            return math.sqrt(dx * dx + dy * dy)
        end,
    },
    Registry = {
        Get = function(id) return records[tostring(id)] end,
        GetLiveZombie = function(id) return bodies[tostring(id)] end,
    },
    Semantics = {
        CampSite = PNC.Semantics and PNC.Semantics.CampSite,
        CampSiteGeometry = Geometry,
    },
    CompanionCommands = {
        Get = function(commandID)
            if commandID ~= "camp" then return nil end
            return {
                buildOrder = function(_, _, options)
                    return {
                        kind = "camp",
                        x = options.x,
                        y = options.y,
                        z = options.z,
                        movementX = options.movementX,
                        movementY = options.movementY,
                        movementZ = options.movementZ,
                        radius = options.zone.radius,
                        stopDistance = options.zone.stopDistance,
                        hasSlot = options.zone.hasSlot,
                        scope = options.zone.scope,
                        siteScope = options.zone.siteScope,
                        siteID = options.zone.siteID,
                        roomID = options.zone.roomID,
                        buildingID = options.zone.buildingID,
                        roomBounds = options.zone.roomBounds,
                        campId = options.campId,
                        placementState = options.placementState,
                        placementCampID = options.placementCampID,
                        placementIndex = options.placementIndex,
                    }
                end,
            }
        end,
    },
    OrderSystem = {
        SetOrder = function(record, orderSpec) record.orderSpec = orderSpec end,
    },
    Network = { BroadcastRecord = function() end },
}

local Coordinator = T.load("ProjectHoomans", "server",
    "PNC/World/PNC_CampMovementCoordinator.lua")

local accepted, startReason = Coordinator.StartGroupCamp(
    chosen, group, nil, { campId = "camp:spread", ownerKey = "p1", now = 0 })
T.equal(accepted, 5, "all 5 group members accepted")
T.equal(startReason, "commanded", "group camp commanded")

local seenSlots = {}
for i = 1, 5 do
    local order = group[i].orderSpec
    T.equal(order.hasSlot, true, "member order marks analyzed interior slot")
    local key = tostring(order.movementX) .. ":" .. tostring(order.movementY)
    T.falsy(seenSlots[key],
        "each group member receives a distinct interior room slot")
    seenSlots[key] = true
end

-- Stepping onto the doorway tile (20, 14) inside the room must NOT complete
-- arrival when the member's interior slot is deeper inside the room.
local first = group[1]
local firstBody = bodies[first.id]
firstBody.x = 20.5
firstBody.y = 14.5
firstBody.sq = mainRoom._grid["20:14"]
first.x = 20.5
first.y = 14.5
Coordinator.Pump(400)
T.equal(first.orderSpec.placementState, "moving",
    "member standing on doorway tile is still moving toward interior slot")

-- Reaching the assigned interior slot completes arrival.
firstBody.x = first.orderSpec.movementX
firstBody.y = first.orderSpec.movementY
firstBody.sq = mainRoom._grid[tostring(math.floor(firstBody.x))
    .. ":" .. tostring(math.floor(firstBody.y))]
first.x = firstBody.x
first.y = firstBody.y
Coordinator.Pump(800)
T.equal(first.orderSpec.placementState, "arrived",
    "member reaching interior slot transitions to arrived")

-- 6. BehaviorAtCamp keeps moving a slotted member past the doorway.
local moveCalls = 0
local haltCalls = 0
PNC.BehaviorCommon = {
    ClearCombatTarget = function() end,
    HaltMovement = function() haltCalls = haltCalls + 1 end,
    MoveRecord = function() moveCalls = moveCalls + 1 end,
}
PNC.Animation = { Apply = function() end }
local AtCamp = T.load("ProjectHoomans", "shared",
    "PNC/Core/Behaviors/PNC_Behavior_AtCamp.lua")

local second = group[2]
second.orderSpec.placementState = "moving"
local secondBody = bodies[second.id]
secondBody.x = 20.5
secondBody.y = 14.5
secondBody.sq = mainRoom._grid["20:14"]
second.x = 20.5
second.y = 14.5
AtCamp.Tick(second, secondBody)
T.equal(moveCalls, 1,
    "AtCamp keeps walking a moving member from the doorway to its slot")
T.equal(haltCalls, 0,
    "AtCamp does not halt a moving member on the doorway tile")

secondBody.x = second.orderSpec.movementX
secondBody.y = second.orderSpec.movementY
secondBody.sq = mainRoom._grid[tostring(math.floor(secondBody.x))
    .. ":" .. tostring(math.floor(secondBody.y))]
second.x = secondBody.x
second.y = secondBody.y
AtCamp.Tick(second, secondBody)
T.equal(haltCalls, 1,
    "AtCamp halts once the member reaches its interior slot")
