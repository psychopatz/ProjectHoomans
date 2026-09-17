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
local wetFloor = object(10, 10, 0, "floors_interior_tilesandwood_01_42",
    "floors_interior_tilesandwood_01_42")
wetFloor.hasFluid = function() return true end
wetFloor.getFluidAmount = function() return 0 end
wetFloor.getWaterAmount = function() return 0 end
local bodyWater = object(10, 10, 0, "Water", "water_01")
local bodyWaterProperties = {
    has = function(_, key) return key == "water" end,
}
bodyWater.getSprite = function()
    return {
        getProperties = function() return bodyWaterProperties end,
    }
end
local depletedCooler = object(10, 10, 0, "Water Cooler", "water_cooler")
depletedCooler.getFluidAmount = function() return 0 end
local campfire = object(14, 10, 0, "Campfire", "campfire")
campfire.isCampfire = function() return true end

local objects = { chair, bed, sink, bin, wetFloor, bodyWater, depletedCooler }
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
local DebugSettings = T.load("ProjectHoomans", "client",
    "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_Settings.lua")
T.falsy(DebugSettings.Defaults.enabled,
    "overlay activation is not persisted in shared nameplate settings")
T.falsy(DebugSettings.Get("enabled", false),
    "perception settings reject the nameplate enabled key")

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
T.falsy(byName["floors_interior_tilesandwood_01_42"],
    "ordinary floor is not a perception candidate")
T.equal(byName.Water.facts.waterState, "ACTIVE",
    "water sprite is recognized as an active body-water source")
T.equal(byName["Water Cooler"].facts.waterState, "DEPLETED",
    "named finite water sources preserve their depleted state")

local unknownSnapshot = Perception.BuildSnapshot({
    origin = player,
    cell = cell,
    nowMs = 110,
    cacheMs = 0,
    includeUnknown = true,
})
local unknownFloor
for _, item in ipairs(unknownSnapshot.objects) do
    if item.facts.nativeName == "floors_interior_tilesandwood_01_42" then
        unknownFloor = item
    end
end
T.truthy(unknownFloor,
    "explicit unknown-object mode can inspect ordinary floor entries")
T.falsy(unknownFloor.facts.waterDetected,
    "ordinary floor fluid methods do not create a water source fact")

local sittingOnly = {
    showObjectNames = true,
    showSemanticNames = false,
    showUsage = true,
    showSitting = true,
    showSleeping = false,
    showWater = false,
    showCampZones = false,
    showJobs = false,
}
T.truthy(Model.ObjectVisible(byName["Wooden chair"], sittingOnly),
    "sitting-only filters keep valid sitting objects")
T.falsy(Model.ObjectVisible(byName["Recycling container"], sittingOnly),
    "sitting-only filters hide semantic-only objects")
T.falsy(Model.ObjectVisible(byName.Bed, sittingOnly),
    "sitting-only filters hide sleeping objects")

ISUIElement = {}
package.preload["ISUI/ISUIElement"] = function() return ISUIElement end
local DebugOverlay = T.load("ProjectHoomans", "client",
    "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_Overlay.lua")
local sittingColor = DebugOverlay.ColorForObject(
    byName["Wooden chair"], sittingOnly)
T.near(sittingColor.r, 0.24, 0.001,
    "valid sitting objects use the dedicated overlay color")
T.near(sittingColor.g, 1.00, 0.001,
    "sitting overlay color is visibly green")
local OverlayPrimitives = PNC.PerceptionDebug.OverlayPrimitives
T.equal(OverlayPrimitives.ZoneLabel({
    kind = "room", label = "living room", roomType = "LIVING_ROOM",
}), "living room", "room overlays expose their friendly zone label")
T.equal(OverlayPrimitives.ZoneLabel({
    kind = "room", roomType = "BEDROOM",
}), "bedroom", "room labels have a readable type fallback")
T.equal(OverlayPrimitives.ZoneLabel({
    kind = "room", roomType = "UNCLASSIFIED",
}), "room", "unclassified rooms use the generic zone label")

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

-- Some loaded-cell versions expose the room on the current square before the
-- building index is populated. The player's current indoor room is still a
-- valid first-choice camp site in that state.
local originalBuildingList = cell.getBuildingList
cell.getBuildingList = function() return {} end
local clientCampHints = PNC.Semantics.ClientCampSiteHints
if clientCampHints and clientCampHints.ClearCache then
    clientCampHints.ClearCache()
end
Perception.ClearSnapshotCache()
local directRoomSnapshot = Perception.BuildSnapshot({
    origin = player, cell = cell, nowMs = 125, cacheMs = 0,
})
T.equal(directRoomSnapshot.campPreview.status, "SAFE",
    "current room remains safe when building enumeration is incomplete")
T.equal(directRoomSnapshot.campPreview.source, "client_loaded_rooms",
    "current-room fast path remains room-first")
cell.getBuildingList = originalBuildingList

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
    candidate = function(value)
        return value and value.plant == true
    end,
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

-- GlobalObject campfires must remain discoverable even when ordinary objects
-- exhaust the bounded observation budget on the player's square.
local denseObjects = {}
for index = 1, 520 do
    denseObjects[index] = object(0, 0, 0, "clutter " .. tostring(index),
        "clutter_test")
end
local lateChair = object(0, 0, 0, "Late wooden chair",
    "furniture_seating_01_0")
lateChair.seatCount = 1
denseObjects[#denseObjects + 1] = lateChair
local denseCampfire = object(0, 0, 0, "Dense campfire", "campfire")
denseCampfire.isCampfire = function() return true end
local denseSquare = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getRoom = function() return nil end,
    isInARoom = function() return false end,
    getObjects = function() return denseObjects end,
    getCampfire = function() return denseCampfire end,
}
local denseCell = {
    getBuildingList = function() return {} end,
    getGridSquare = function(_, x, y, z)
        if x == 0 and y == 0 and z == 0 then return denseSquare end
        return nil
    end,
}
local densePlayer = {
    getX = function() return 0.5 end,
    getY = function() return 0.5 end,
    getZ = function() return 0 end,
    getCurrentSquare = function() return denseSquare end,
}
getCell = function() return denseCell end
Perception.ClearSnapshotCache()
local denseSnapshot = Perception.BuildSnapshot({
    origin = densePlayer, cell = denseCell, nowMs = 325, cacheMs = 0,
})
T.equal(denseSnapshot.campPreview.status, "SAFE",
    "campfire remains visible after ordinary-object truncation")
T.equal(denseSnapshot.campPreview.source, "client_loaded_campfire",
    "dense scan preserves the campfire fallback source")
local denseCampfireFacts
for _, item in ipairs(denseSnapshot.objects) do
    if item.facts.isCampfire then denseCampfireFacts = item.facts end
end
T.truthy(denseCampfireFacts,
    "detailed perception retains the prioritized campfire observation")
local lateChairFacts
for _, item in ipairs(denseSnapshot.objects) do
    if item.facts.nativeName == "Late wooden chair" then
        lateChairFacts = item.facts
    end
end
T.truthy(lateChairFacts and lateChairFacts.validSitting,
    "recognized objects survive irrelevant floor/clutter entries")
T.falsy(denseSnapshot.diagnostics.scan.truncated,
    "irrelevant objects do not consume the ordinary-object cap")
T.truthy((denseSnapshot.diagnostics.scan.inspectedObjectCount or 0) >= 521,
    "scan diagnostics distinguish inspected entries from candidates")

-- The bounded budget still applies when the loaded square really contains
-- more recognized candidates; this keeps the debug scan finite.
local cappedObjects = {}
for index = 1, 520 do
    cappedObjects[index] = object(0, 0, 0,
        "table clutter " .. tostring(index), "table_test")
end
local cappedCampfire = object(0, 0, 0, "Capped campfire", "campfire")
cappedCampfire.isCampfire = function() return true end
local cappedSquare = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getRoom = function() return nil end,
    isInARoom = function() return false end,
    getObjects = function() return cappedObjects end,
    getCampfire = function() return cappedCampfire end,
}
local cappedCell = {
    getBuildingList = function() return {} end,
    getGridSquare = function(_, x, y, z)
        if x == 0 and y == 0 and z == 0 then return cappedSquare end
        return nil
    end,
}
getCell = function() return cappedCell end
Perception.ClearSnapshotCache()
local cappedSnapshot = Perception.BuildSnapshot({
    origin = densePlayer, cell = cappedCell, nowMs = 337, cacheMs = 0,
})
T.truthy(cappedSnapshot.diagnostics.scan.truncated,
    "recognized candidates still report a bounded scan cap")
T.equal(cappedSnapshot.diagnostics.scan.objectCount, 512,
    "candidate cap counts recognized objects rather than floor entries")
local cappedCampfireFacts
for _, item in ipairs(cappedSnapshot.objects) do
    if item.facts.isCampfire then cappedCampfireFacts = item.facts end
end
T.truthy(cappedCampfireFacts,
    "prioritized campfire remains visible beside capped candidates")

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
T.falsy(Model.ObjectVisible({ facts = {
    indoor = true, usage = { "Indoor room: kitchen" },
} }, {
    showObjectNames = true, showSemanticNames = true, showUsage = true,
}), "room membership alone does not create an object marker")
T.truthy(Model.ObjectVisible(byName["Recycling container"], {
    showObjectNames = true, showSemanticNames = true,
}), "semantic command objects remain inspectable")
T.contains(Model.ObjectLabel({ facts = {
    nativeName = "Campfire", semanticName = "campfire",
    usage = { "Campfire" }, jobs = { "camp" },
} }, { showJobs = true }), "[campfire]",
    "presentation model includes NPC command name")

-- The world highlight API is a per-frame native queue. Verify the overlay
-- keeps its render plan stable between frames and enforces the visual budget
-- without changing the underlying snapshot contents.
local previousPlayer = getSpecificPlayer
local previousScreenLeft = getPlayerScreenLeft
local previousScreenTop = getPlayerScreenTop
local previousScreenWidth = getPlayerScreenWidth
local previousScreenHeight = getPlayerScreenHeight
local previousIsoX = isoToScreenX
local previousIsoY = isoToScreenY
local previousMouseX = getMouseX
local previousMouseY = getMouseY
local previousCameraX = getCameraOffX
local previousCameraY = getCameraOffY
local previousHighlights = addAreaHighlightForPlayer
local previousEvents = Events
local highlightCalls = 0
local renderPlayer = {
    getPlayerNum = function() return 0 end,
    getX = function() return 0.5 end,
    getY = function() return 0.5 end,
    getZ = function() return 0 end,
}
getSpecificPlayer = function() return renderPlayer end
getPlayerScreenLeft = function() return 0 end
getPlayerScreenTop = function() return 0 end
getPlayerScreenWidth = function() return 1920 end
getPlayerScreenHeight = function() return 1080 end
isoToScreenX = function(_, x, y) return 960 + (x - y) * 20 end
isoToScreenY = function(_, x, y) return 540 + (x + y) * 10 end
getMouseX = function() return 99999 end
getMouseY = function() return 99999 end
getCameraOffX = function() return 0 end
getCameraOffY = function() return 0 end
addAreaHighlightForPlayer = function() highlightCalls = highlightCalls + 1 end
Events = {
    OnPreUIDraw = {
        Add = function() end,
        Remove = function() end,
    },
}
ISUIElement.new = function(_, x, y, width, height)
    local drawer = { x = x, y = y, width = width, height = height }
    function drawer:initialise() end
    function drawer:setCapture() end
    function drawer:setX(value) self.x = value end
    function drawer:setY(value) self.y = value end
    function drawer:setWidth(value) self.width = value end
    function drawer:setHeight(value) self.height = value end
    return drawer
end
DebugSettings.Set("showSitting", true, false)
DebugSettings.Set("showSleeping", false, false)
DebugSettings.Set("showWater", false, false)
DebugSettings.Set("showCampZones", false, false)
DebugSettings.Set("showSemanticNames", false, false)
DebugSettings.Set("showJobs", false, false)
DebugSettings.Set("showUnknownObjects", false, false)
DebugSettings.Set("showObjectNames", true, false)
DebugSettings.Set("showUsage", true, false)
DebugSettings.Set("showTooltip", true, false)
local renderObjects = {}
for index = 1, 70 do
    renderObjects[index] = {
        x = (index - 1) % 8,
        y = math.floor((index - 1) / 8),
        z = 0,
        facts = { validSitting = true },
    }
end
DebugOverlay.SetSnapshot({
    status = "READY", objects = renderObjects, zones = {},
})
DebugOverlay.SetEnabled(true)
DebugOverlay.Render()
local firstFrameCalls = highlightCalls
local firstPlan = DebugOverlay.renderPlan
DebugOverlay.Render()
T.equal(firstFrameCalls, DebugOverlay.MAX_RENDER_OBJECTS,
    "overlay enforces the native object highlight budget")
T.equal(highlightCalls, firstFrameCalls * 2,
    "overlay submits only the bounded plan on each native frame")
T.equal(DebugOverlay.renderPlan, firstPlan,
    "overlay reuses its render plan between unchanged frames")

-- Presentation-only settings must not make the enabled overlay pay the
-- world-render cost.  This is the state reached when the hub is open but the
-- user has unchecked every visualization layer.
DebugSettings.Set("showSitting", false, false)
DebugOverlay.Render()
T.equal(highlightCalls, firstFrameCalls * 2,
    "overlay submits no native highlights when every world layer is hidden")

DebugOverlay.SetEnabled(false)
T.falsy(DebugOverlay.snapshot,
    "explicitly disabling the overlay releases its retained snapshot")
getSpecificPlayer = previousPlayer
getPlayerScreenLeft = previousScreenLeft
getPlayerScreenTop = previousScreenTop
getPlayerScreenWidth = previousScreenWidth
getPlayerScreenHeight = previousScreenHeight
isoToScreenX = previousIsoX
isoToScreenY = previousIsoY
getMouseX = previousMouseX
getMouseY = previousMouseY
getCameraOffX = previousCameraX
getCameraOffY = previousCameraY
addAreaHighlightForPlayer = previousHighlights
Events = previousEvents

T.finish("pnc_perception_debug_smoke")
