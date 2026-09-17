local T = require "tests/support/test"
T.addPackagePaths()

local SquareRules = {
    GetObjectProperty = function() return nil end,
    ClassifySleepSurface = function(object)
        return object and object.sleepSurface
    end,
}
PsychopatzCore = {
    RuntimeRole = { AllowsClientCode = function() return true end },
    World = { SquareRules = SquareRules },
}
PNC = { Semantics = {} }

T.load("ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticWorldTargetCatalog.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticCampSite.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticCampSiteGeometry.lua")

SeatingManager = {
    getInstance = function()
        return {
            getTilePositionCount = function(_, object)
                return tonumber(object and object.seatCount) or 0
            end,
        }
    end,
}

local function object(x, y, z, name, sprite)
    local value = {
        x = x, y = y, z = z, name = name, sprite = sprite,
    }
    value.getX = function(self) return self.x end
    value.getY = function(self) return self.y end
    value.getZ = function(self) return self.z end
    value.getName = function(self) return self.name end
    value.getObjectName = function(self) return self.name end
    value.getSpriteName = function(self) return self.sprite end
    value.getSprite = function() return nil end
    value.getContainer = function() return nil end
    return value
end

local roomDefinition = {
    getIDString = function() return "living-room-1" end,
    getName = function() return "living room" end,
    getX = function() return 10 end,
    getY = function() return 10 end,
    getX2 = function() return 14 end,
    getY2 = function() return 14 end,
    getZ = function() return 0 end,
}
local room = {}
local roomSquare
local building
room.getRoomDef = function() return roomDefinition end
room.getIDString = function() return "living-room-1" end
room.getName = function() return "living room" end
room.getSquares = function() return { roomSquare } end
room.getFreeTile = function() return roomSquare end

local chair = object(10, 10, 0, "Wooden chair", "furniture_seating_01_0")
chair.seatCount = 1
local bed = object(11, 10, 0, "Bed", "furniture_bedding_01_0")
bed.sleepSurface = "bed"
local sink = object(12, 10, 0, "Sink", "fixtures_sinks_01_0")
sink.isWaterSource = function() return true end
sink.getFluidAmount = function() return 0 end
sink.transferFluidTo = function() end
local bin = object(13, 10, 0, "Recycling container", "trashcontainers_01_16")
local campfire = object(14, 10, 0, "Campfire", "campfire")
campfire.isCampfire = function() return true end

local objects = { chair, bed, sink, bin }
roomSquare = {
    getX = function() return 10 end,
    getY = function() return 10 end,
    getZ = function() return 0 end,
    getRoom = function() return room end,
    isInARoom = function() return true end,
    isFree = function() return true end,
    getObjects = function() return objects end,
    getCampfire = function() return campfire end,
}
room.getBuilding = function() return building end

building = {
    getID = function() return "building-1" end,
    getDef = function()
        return { getIDString = function() return "building-1" end }
    end,
    getRooms = function() return { room } end,
    isToxic = function() return false end,
    isResidential = function() return true end,
}

local squares = {
    ["10:10:0"] = roomSquare,
}
local cell = {
    getBuildingList = function() return { building } end,
    getGridSquare = function(_, x, y, z)
        return squares[tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)]
    end,
}
local player = {
    getX = function() return 10.5 end,
    getY = function() return 10.5 end,
    getZ = function() return 0 end,
    getCurrentSquare = function() return roomSquare end,
}
getCell = function() return cell end
package.loaded["PsychopatzCore/World/PsychopatzSquareRules"] = SquareRules

local Perception = T.load("ProjectHoomans", "client",
    "PNC/Perception/WorldObjectPerception/PNC_ClientWorldObjectPerception.lua")
local Model = T.load("ProjectHoomans", "client",
    "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_Model.lua")

local snapshot = Perception.BuildSnapshot({
    origin = player,
    cell = cell,
    nowMs = 100,
    cacheMs = 0,
})
T.equal(snapshot.status, "READY", "perception snapshot is ready")
T.equal(snapshot.diagnostics.clientOnly, true,
    "perception snapshot declares client-only observation")
T.equal(snapshot.diagnostics.serverRequests, 0,
    "perception snapshot does not send server search requests")

local byName = {}
for _, item in ipairs(snapshot.objects) do
    byName[item.facts.nativeName] = item
end
T.truthy(byName["Wooden chair"].facts.validSitting,
    "chair uses the seating classifier")
T.contains(table.concat(byName["Wooden chair"].facts.usage, ","), "Sitting",
    "chair exposes sitting usage")
T.truthy(byName["Wooden chair"].facts.validCampZone,
    "indoor object is associated with a valid room camp zone")

-- A client may not expose the server-side SeatingManager. The debug surface
-- must still show a useful, explicitly approximate perception result.
SeatingManager = nil
Perception.ClearSnapshotCache()
local approximateSnapshot = Perception.BuildSnapshot({
    origin = player, cell = cell, nowMs = 150, cacheMs = 0,
})
local approximateChair
for _, item in ipairs(approximateSnapshot.objects) do
    if item.facts.nativeName == "Wooden chair" then approximateChair = item end
end
T.truthy(approximateChair and approximateChair.facts.validSitting,
    "client metadata fallback still detects a sitting object")
T.equal(approximateChair.facts.sittingValidation,
    "client_metadata_approximation",
    "client sitting fallback is visibly marked approximate")
SeatingManager = {
    getInstance = function()
        return {
            getTilePositionCount = function(_, value)
                return tonumber(value and value.seatCount) or 0
            end,
        }
    end,
}

local classifySleepSurface = SquareRules.ClassifySleepSurface
SquareRules.ClassifySleepSurface = nil
Perception.ClearSnapshotCache()
local approximateSleepSnapshot = Perception.BuildSnapshot({
    origin = player, cell = cell, nowMs = 175, cacheMs = 0,
})
local approximateBed
for _, item in ipairs(approximateSleepSnapshot.objects) do
    if item.facts.nativeName == "Bed" then approximateBed = item end
end
T.truthy(approximateBed and approximateBed.facts.validSleeping,
    "client metadata fallback still detects a sleeping object")
T.equal(approximateBed.facts.sleepingValidation,
    "client_metadata_approximation",
    "client sleeping fallback is visibly marked approximate")
SquareRules.ClassifySleepSurface = classifySleepSurface

T.truthy(byName.Bed and byName.Bed.facts.validSleeping,
    "bed uses the sleep-surface classifier: "
        .. tostring(byName.Bed and byName.Bed.facts.sleepingSurface)
        .. " / " .. tostring(byName.Bed and byName.Bed.facts.nativeName))
T.equal(byName.Sink.facts.waterState, "ACTIVE",
    "marked zero-amount source is shown as active")
T.truthy(byName.Sink.facts.validDrinking,
    "active source exposes drinking capability")
T.equal(byName["Recycling container"].facts.semanticName, "bin",
    "recycle bin exposes the NPC command name")
T.truthy(byName["Recycling container"].targetID,
    "observed object has a primitive target identity")
T.equal(snapshot.campPreview.status, "SAFE",
    "camp preview finds the nearby indoor room first")
T.equal(snapshot.campPreview.source, "client_loaded_rooms",
    "camp preview preserves room-first policy")
T.equal(snapshot.campPreview.roomType, "LIVING_ROOM",
    "camp preview keeps normalized room type")
local chairDetails = Model.DetailRows(byName["Wooden chair"], {
    showObjectNames = true, showSemanticNames = true, showUsage = true,
    showJobs = true,
})
local roomCampDetail
for _, row in ipairs(chairDetails) do
    if row.label == "camp zone" then roomCampDetail = row.value end
end
T.contains(roomCampDetail or "", "VALID / room",
    "object details identify the room-based camp zone")

local campfireZone
for _, zone in ipairs(snapshot.zones) do
    if zone.kind == "campfire" then campfireZone = zone end
end
T.truthy(campfireZone, "snapshot exposes campfire zone")
T.equal(campfireZone.radius, 16, "campfire zone uses the shared radius")

local plant = object(10, 10, 0, "test plant", "plant_test")
plant.plant = true
objects[#objects + 1] = plant
T.truthy(Perception.RegisterProvider("plant", {
    order = 70,
    label = "Plants",
    describe = function(value)
        return value.plant and { plantDetected = true } or nil
    end,
}), "future perception providers can register")
Perception.ClearSnapshotCache()
snapshot = Perception.BuildSnapshot({
    origin = player, cell = cell, nowMs = 200, cacheMs = 0,
})
local plantFacts
for _, item in ipairs(snapshot.objects) do
    if item.facts.plantDetected then plantFacts = item.facts end
end
T.truthy(plantFacts,
    "a future provider can decorate the shared perception snapshot")

local campfireSquare = {
    getX = function() return 4 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getRoom = function() return nil end,
    isInARoom = function() return false end,
    getObjects = function() return {} end,
    getCampfire = function() return campfire end,
}
local campfireCell = {
    getBuildingList = function() return {} end,
    getGridSquare = function(_, x, y, z)
        if x == 4 and y == 0 and z == 0 then return campfireSquare end
        return nil
    end,
}
local outsidePlayer = {
    getX = function() return 0.5 end,
    getY = function() return 0.5 end,
    getZ = function() return 0 end,
    getCurrentSquare = function() return campfireSquare end,
}
getCell = function() return campfireCell end
Perception.ClearSnapshotCache()
local campfireSnapshot = Perception.BuildSnapshot({
    origin = outsidePlayer,
    cell = campfireCell,
    nowMs = 300,
    cacheMs = 0,
})
T.equal(campfireSnapshot.campPreview.status, "SAFE",
    "camp preview falls back to a nearby campfire")
T.equal(campfireSnapshot.campPreview.source, "client_loaded_campfire",
    "camp preview reports campfire fallback source")

local emptyCell = {
    getBuildingList = function() return {} end,
    getGridSquare = function() return nil end,
}
local emptyPlayer = {
    getX = function() return 40.5 end,
    getY = function() return 40.5 end,
    getZ = function() return 0 end,
}
getCell = function() return emptyCell end
Perception.ClearSnapshotCache()
local unsafeSnapshot = Perception.BuildSnapshot({
    origin = emptyPlayer,
    cell = emptyCell,
    nowMs = 350,
    cacheMs = 0,
})
T.equal(unsafeSnapshot.campPreview.status, "UNSAFE",
    "camp preview is unsafe when no room or campfire is visible")
T.truthy(unsafeSnapshot.campPreview.reason,
    "unsafe camp preview retains its rejection reason")

local rows = Model.ObjectRows(snapshot, {
    showObjectNames = true,
    showSemanticNames = true,
    showUsage = true,
    showJobs = true,
})
T.truthy(#rows > 0, "presentation model builds object rows")
T.contains(Model.ObjectLabel({ facts = {
    nativeName = "Campfire", semanticName = "campfire",
    usage = { "Campfire" }, jobs = { "camp" },
} }, { showJobs = true }), "[campfire]",
    "presentation model includes NPC command name")

T.finish("pnc_perception_debug_smoke")
