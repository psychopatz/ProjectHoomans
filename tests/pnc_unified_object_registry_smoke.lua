local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
    { "PsychopatzCore", "shared" },
})

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local now = 1000
local getObjectsCalls = 0
local reservations = {}

local radioObj = { kind = "radio", id = "radio-1" }
local faucetObj = { kind = "faucet", id = "sink-1" }

local room = {}
local roomDef = {
    getIDString = function() return "den-1" end,
    getName = function() return "livingroom" end,
    getX = function() return 10 end,
    getY = function() return 10 end,
    getX2 = function() return 14 end,
    getY2 = function() return 14 end,
    getZ = function() return 0 end,
}
local building = {
    getID = function() return "bldg-den" end,
    getDef = function()
        return { getIDString = function() return "bldg-den" end }
    end,
}

local roomSquares = {}
local grid = {}
for x = 10, 13 do
    for y = 10, 13 do
        local objs = {}
        if x == 11 and y == 11 then objs = { radioObj }
        elseif x == 12 and y == 12 then objs = { faucetObj }
        end
        local sq = {
            getX = function() return x end,
            getY = function() return y end,
            getZ = function() return 0 end,
            getRoom = function() return room end,
            isInARoom = function() return true end,
            isFree = function() return #objs == 0 end,
            getObjects = function()
                getObjectsCalls = getObjectsCalls + 1
                return objs
            end,
        }
        roomSquares[#roomSquares + 1] = sq
        grid[tostring(x) .. ":" .. tostring(y)] = sq
    end
end
room.getRoomDef = function() return roomDef end
room.getBuilding = function() return building end
room.getSquares = function() return roomSquares end
room.getFreeTile = function() return roomSquares[1] end

local cell = {
    getGridSquare = function(_, x, y)
        return grid[tostring(math.floor(x)) .. ":" .. tostring(math.floor(y))]
    end,
}
getCell = function() return cell end

PNC = {
    Const = {
        ORDER_CAMP = "camp",
        CAMP_RADIUS = 3,
        CAMP_RESOURCE_RADIUS = 12,
        CAMP_RESOURCE_MAX = 32,
        CAMP_RESOURCE_SCAN_SQUARES_PER_TICK = 64,
    },
    Core = { Now = function() return now end },
    Registry = {
        MarkDirty = function() end,
        Get = function() return nil end,
        GetLiveZombie = function() return nil end,
    },
    NearbyWaterService = {
        IsCleanFaucet = function(obj) return obj and obj.kind == "faucet" end,
        IsFillableFaucet = function() return true end,
    },
    NearbyResourceLocator = {
        ObjectKeyFor = function(obj) return "faucet:" .. tostring(obj.id) end,
    },
    FacilityReservations = {
        IsReserved = function(_, key) return reservations[key] == true end,
        ReserveResource = function(_, resource)
            reservations[resource.resourceKey] = true
            return true, { id = "res:" .. tostring(resource.resourceKey) }
        end,
    },
}

local Geometry = T.load("ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticCampSiteGeometry.lua")
PNC.Semantics.CampSiteGeometry = Geometry

local Resources = T.load("ProjectHoomans", "server",
    "PNC/Settlement/PNC_FacilityResources.lua")

-- 1. Built-in object modules are all registered in one canonical registry.
T.truthy(Resources.GetDetector("bed"), "bed detector registered")
T.truthy(Resources.GetDetector("sofa"), "sofa detector registered")
T.truthy(Resources.GetDetector("seat"), "seat detector registered")
T.truthy(Resources.GetDetector("faucet"), "faucet detector registered")
T.equal(#Resources.ListByCapability("sleep"), 2,
    "sleep capability lists bed and sofa detectors")
T.equal(#Resources.ListByCapability("living"), 1,
    "living capability lists seat detector")
T.equal(#Resources.ListByCapability("survival.drink.world"), 1,
    "water capability lists faucet detector")

-- 2. Registering a brand-new object module requires zero core service edits.
local okReg = Resources.Register("radio", {
    resourceKind = "entertainment_device",
    capability = "entertainment",
    role = "leisure.radio",
    exclusive = false,
    matches = function(_, obj) return obj and obj.kind == "radio" end,
    describe = function(sq, obj)
        return {
            resourceKey = "radio:" .. tostring(obj.id),
            x = sq:getX() + 0.5,
            y = sq:getY() + 0.5,
            z = sq:getZ(),
            priority = 80,
        }
    end,
})
T.equal(okReg, true, "custom object module registers cleanly")
T.equal(#Resources.ListByCapability("entertainment"), 1,
    "custom capability is indexed immediately")

local CampResources = T.load("ProjectHoomans", "server",
    "PNC/World/CampResourceService/PNC_CampResourceService.lua")

local npc = {
    id = "npc-mod",
    alive = true,
    x = 11.5,
    y = 11.5,
    z = 0,
    runtime = {},
    orderSpec = {
        kind = "camp",
        campId = "camp:modular:1",
        scope = "room",
        siteScope = "room",
        siteID = "room:bldg-den:den-1",
        roomID = "den-1",
        buildingID = "bldg-den",
        roomBounds = { minX = 10, minY = 10, maxX = 13, maxY = 13, z = 0 },
        x = 11.5,
        y = 11.5,
        z = 0,
        radius = 3,
        resourceRadius = 12,
        placementState = "arrived",
    },
}

-- 3. Single-pass room capture discovers both built-in faucet AND custom radio
--    sharing one object loop across all 5 detectors (instead of 5x loops).
getObjectsCalls = 0
local snap = CampResources.Capture(npc, true)
T.truthy(snap, "unified room capture succeeds")
T.truthy(getObjectsCalls <= #roomSquares * 2,
    "single-pass InspectSquare avoids per-detector getObjects loops across 5 detectors")

local radioRes, radioTarget = CampResources.FindByCapability(
    npc, "entertainment", { abstract = true })
T.truthy(radioRes, "custom object found via generic FindByCapability")
T.equal(radioRes.resourceKey, "radio:radio-1",
    "custom radio resourceKey preserved")
T.truthy(radioTarget, "custom object resolves a valid target")

local acquired = CampResources.AcquireByCapability(
    npc, "entertainment", { abstract = true })
T.truthy(acquired and acquired.ok,
    "custom object acquired via generic AcquireByCapability")
T.equal(acquired.capability, "entertainment",
    "acquired payload carries capability")
T.equal(acquired.resourceKey, "radio:radio-1",
    "acquired payload carries custom resourceKey")

-- 4. Unregistering the custom object module cleanly removes it.
T.equal(Resources.Unregister("radio"), true, "custom detector unregisters")
T.equal(#Resources.ListByCapability("entertainment"), 0,
    "unregistered capability list is empty")
now = now + 5000
local snapAfter = CampResources.Capture(npc, true)
T.truthy(snapAfter, "re-capture after unregister succeeds")
local missingRadio = CampResources.FindByCapability(
    npc, "entertainment", { abstract = true })
T.equal(missingRadio, nil,
    "unregistered object type is no longer discovered or returned")
