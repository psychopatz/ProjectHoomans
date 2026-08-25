local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" } })

local function event()
    return { Add = function() end }
end

local tickCallback
local loadSquareCallback
local removeCallback
Events = { OnInitGlobalModData = event(), OnGameStart = event(),
    OnTick = { Add = function(callback) tickCallback = callback end },
    LoadGridsquare = {
        Add = function(callback) loadSquareCallback = callback end,
    },
    OnObjectAboutToBeRemoved = {
        Add = function(callback) removeCallback = callback end,
    },
}

package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return {}
end

local function list(items)
    return {
        size = function() return #items end,
        get = function(_, index) return items[index + 1] end,
    }
end

local function region(x, y, z)
    return { levels = { [z] = { rows = { [y] = { x, x } } } } }
end

local squares = {}
local function newSquare(x, y, z)
    local square = { x = x, y = y, z = z, objects = {},
        removeCalls = 0 }
    function square:getX() return self.x end
    function square:getY() return self.y end
    function square:getZ() return self.z end
    function square:getObjects() return list(self.objects) end
    function square:AddTileObject(object)
        -- Simulate the engine's AddTileObject/createContainersFromSpriteProperties
        -- path for a furniture sprite carrying native container metadata.
        if object.objectType == "isoobject" then
            object.container = { engineCreated = true }
        end
        self.objects[#self.objects + 1] = object
    end
    function square:AddSpecialObject(object)
        self.specialCalls = (self.specialCalls or 0) + 1
        if object.objectType == "thumpable" then
            -- Simulate IsoObject.addToWorld/createContainersFromSpriteProperties.
            object.container = { engineCreated = true }
            object.outlineOnMouseover = true
        end
        self.objects[#self.objects + 1] = object
    end
    function square:transmitRemoveItemFromSquare(object)
        self.removeCalls = self.removeCalls + 1
        for index = #self.objects, 1, -1 do
            if self.objects[index] == object then
                table.remove(self.objects, index)
            end
        end
        return 0
    end
    function square:RemoveTileObject(object)
        return self:transmitRemoveItemFromSquare(object, true)
    end
    squares[tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)] = square
    return square
end

local squareA = newSquare(10, 20, 0)
local squareB = newSquare(30, 40, 0)
getCell = function()
    return { getGridSquare = function(_, x, y, z)
        return squares[tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)]
    end }
end

local transmitCount = 0
local now = 0
local isoObjectCreates = 0
local thumpableCreates = 0
local function newObject(objectType, square, sprite)
    local object = { square = square, sprite = sprite, data = {},
        objectType = objectType, container = { stale = true },
        outlineOnMouseover = true }
    if objectType == "thumpable" then
        object.thumpable = true
        object.dismantable = true
        object.barricade = true
        object.hoppable = true
        object.door = true
        object.canPassThrough = true
    end
    function object:getModData() return self.data end
    function object:getSpriteName() return self.sprite end
    function object:removeAllContainers() self.container = nil end
    function object:setOutlineOnMouseover(value)
        self.outlineOnMouseover = value
    end
    function object:setIsContainer(value) self.isContainer = value end
    function object:setIsThumpable(value) self.thumpable = value end
    function object:setIsDismantable(value) self.dismantable = value end
    function object:setCanBarricade(value) self.barricade = value end
    function object:setIsHoppable(value) self.hoppable = value end
    function object:setIsDoor(value) self.door = value end
    function object:setCanPassThrough(value) self.canPassThrough = value end
    function object:transmitCompleteItemToClients()
        transmitCount = transmitCount + 1
    end
    function object:transmitModData() end
    return object
end

IsoObject = {
    new = function(square, sprite)
        isoObjectCreates = isoObjectCreates + 1
        return newObject("isoobject", square, sprite)
    end,
}
IsoThumpable = {
    new = function(_, square, sprite)
        thumpableCreates = thumpableCreates + 1
        return newObject("thumpable", square, sprite)
    end,
}

local components = {
    storage = { id = "storage", facilityId = "facility-1",
        role = "storage.stockpile", region = region(10, 20, 0) },
    work = { id = "work", facilityId = "facility-1",
        role = "work.zone", region = region(99, 99, 0) },
}
local facility = {
    id = "facility-1", definitionId = "stockpile", level = 1,
    constructionState = "BUILT", componentIds = { storage = true, work = true },
    constructionRegion = region(99, 99, 0),
}

PNC = {
    Core = { Now = function() return now end },
    FacilityDefinitions = {},
    SettlementRepository = {
        Loaded = true,
        State = { facilities = { facility = facility } },
        GetComponent = function(id) return components[id] end,
        GetFacility = function() return facility end,
        MarkDirty = function() end,
    },
}

T.load("ProjectHoomans", "shared",
    "PNC/Core/Settlement/PNC_FacilityDefinitions/PNC_FacilityDefinitions_Core.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Settlement/PNC_FacilityDefinitions/PNC_FacilityDefinitions_Stockpile.lua")
local Service = T.load("ProjectHoomans", "server",
    "PNC/Settlement/PNC_StockpileVisualService.lua")

T.equal(Service.GetVisualSpec(1).sprite, "furniture_storage_01_53",
    "level 1 uses the captured table object")
T.equal(Service.GetVisualSpec(2).sprite, "furniture_storage_02_29",
    "level 2 uses the captured chest object")
T.equal(Service.GetVisualSpec(3).sprite, "furniture_storage_01_49",
    "level 3 uses the captured drawers object")
T.equal(Service.GetVisualSpec(4).sprite, "furniture_storage_01_46",
    "level 4 uses the captured drawers object")
T.equal(Service.GetVisualSpec(5).sprite, "furniture_storage_01_32",
    "level 5 uses the captured drawers object")
T.equal(Service.GetVisualSpec(1).objectType, "thumpable",
    "level 1 uses the persistent furniture object type")
T.equal(Service.GetVisualSpec(6).sprite, "furniture_storage_01_12",
    "level 6 continues the captured furniture objects")
T.equal(Service.GetVisualSpec(13).sprite, "furniture_storage_02_12",
    "tier 13 uses the last captured furniture sprite")
T.equal(Service.GetVisualSpec(19).sprite, "furniture_storage_02_12",
    "unconfigured future tiers fall back to the latest visual")

local ok, object = Service.Apply(facility)
T.equal(ok, true, "stockpile visual is created")
T.equal(object.sprite, "furniture_storage_01_53",
    "visual is placed on the stockpile region")
T.equal(object.objectType, "thumpable",
    "stockpile visual uses the persistent furniture object")
T.equal(isoObjectCreates, 0,
    "stockpile visual does not use the transient IsoObject constructor")
T.equal(thumpableCreates, 1,
    "stockpile visual uses the thumpable constructor")
T.equal(#squareA.objects, 1, "real world object is added to the target square")
T.equal(#squareB.objects, 0, "work zone does not receive the visual")
T.equal(transmitCount, 1, "created object is transmitted to clients")

-- A base-game/other-mod object on the same square must never be treated as
-- one of this mod's visuals, even if it happens to reuse the marker key.
local baseObject = newObject("thumpable", squareA, "furniture_storage_01_49")
baseObject.data.PNC_StockpileVisual = { owner = "OtherMod",
    facilityId = facility.id, sprite = baseObject.sprite, tier = 8,
    objectType = "thumpable" }
squareA.objects[#squareA.objects + 1] = baseObject

Service.Apply(facility)
squareA.objects[1].container = { persisted = true }
squareA.objects[1].outlineOnMouseover = true
Service.Apply(facility)
T.equal(#squareA.objects, 2, "reconcile does not duplicate the visual")
T.equal(transmitCount, 1, "idempotent reconcile does not retransmit")
T.equal(squareA.objects[2], baseObject,
    "other-mod object remains untouched during reconcile")
T.equal(squareA.objects[1].container, nil,
    "reconcile removes a persisted furniture container")
T.equal(squareA.objects[1].outlineOnMouseover, false,
    "reconcile removes the persisted interaction outline")

facility.level = 2
ok, object = Service.Apply(facility)
T.equal(ok, true, "tier upgrade swaps the visual")
T.equal(object.sprite, "furniture_storage_02_29",
    "level 2 object uses the requested sprite")
T.equal(#squareA.objects, 2, "tier swap leaves the base object and one visual")
T.truthy(squareA.removeCalls > 0, "tier swap removes the old world object")
T.equal(transmitCount, 2, "tier swap transmits the replacement object")
T.equal(squareA.objects[1], baseObject,
    "tier swap does not remove the other-mod object")

local previous = facility.stockpileVisual
components.storage.region = region(30, 40, 0)
ok, object = Service.Apply(facility, previous)
T.equal(ok, true, "moving the stockpile moves the visual")
T.equal(#squareA.objects, 1, "old stockpile tile keeps the base object")
T.equal(#squareB.objects, 1, "new stockpile tile receives the visual")
T.equal(object.sprite, "furniture_storage_02_29",
    "moved visual keeps the current level")

facility.level = 6
ok, object = Service.Apply(facility)
T.equal(ok, true, "level 6 swaps to the captured furniture object")
T.equal(object.sprite, "furniture_storage_01_12",
    "level 6 uses the captured drawers sprite")
T.equal(object.objectType, "thumpable",
    "level 6 creates the persistent furniture object")
T.truthy(squareB.specialCalls > 0,
    "thumpable visual uses the special-object insertion path")
T.equal(object.container, nil,
    "test object starts without a container after cleanup")
T.equal(object.outlineOnMouseover, false,
    "visual does not present a hover interaction outline")
T.equal(object.thumpable, false,
    "furniture visual cannot be damaged or opened as furniture")
T.equal(object.dismantable, false,
    "furniture visual cannot be dismantled")
T.equal(object.barricade, false,
    "furniture visual cannot be barricaded")
T.equal(object.hoppable, false,
    "furniture visual cannot be hopped through")
T.equal(object.door, false,
    "furniture visual cannot act as a door")
T.equal(object.canPassThrough, false,
    "furniture visual retains blocking collision")
T.equal(object.data.PNC_StockpileVisual.visualOnly, true,
    "world marker identifies the object as visual-only")
T.equal(object.data.PNC_StockpileVisual.hasContainer, false,
    "world marker records that no container is available")

-- The world object can disappear when its square is unloaded even though the
-- persisted facility record remains. The square-load event should repair it
-- without scanning every facility on every tick.
T.truthy(loadSquareCallback, "stockpile visual installs a square-load repair")
T.truthy(removeCallback, "stockpile visual observes visual removal")
T.truthy(tickCallback, "stockpile visual installs a bounded retry tick")
now = 500
tickCallback()
local missingObject = squareB.objects[1]
removeCallback(missingObject)
squareB.objects = {}
loadSquareCallback(squareB)
T.equal(#squareB.objects, 1,
    "square-load repair recreates a missing visual in a loaded square")

local savedSquareB = squareB
local unloadedObject = squareB.objects[1]
removeCallback(unloadedObject)
savedSquareB.objects = {}
squares["30:40:0"] = nil
now = 10000
tickCallback()
T.equal(#savedSquareB.objects, 0,
    "unloaded square defers visual repair")

squareB = newSquare(30, 40, 0)
loadSquareCallback(squareB)
T.equal(#squareB.objects, 1,
    "square-load repair applies when the stockpile square loads again")

-- A visual saved by the previous plain-object implementation must migrate to
-- the persistent thumpable furniture path on the next reconcile.
local legacyObject = squareB.objects[1]
legacyObject.objectType = "isoobject"
legacyObject.data.PNC_StockpileVisual.objectType = "isoobject"
ok, object = Service.Apply(facility)
T.equal(ok, true, "legacy stockpile visual is replaced")
T.equal(object.objectType, "thumpable",
    "legacy visual migrates to the persistent furniture object")
T.equal(object.container, nil,
    "migrated visual has no container")

T.finish("pnc_stockpile_visual_smoke")
