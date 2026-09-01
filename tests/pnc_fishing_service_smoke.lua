local T = require "tests/support/test"

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local now = 1000
local serial = 0
local records = {
    npc = {
        id = "npc", alive = true, recruited = true,
        x = 1.5, y = 1.5, z = 0, presenceState = "abstract",
    },
}
local squares = {}
local added = {}
local canAccept = true

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, item in pairs(value) do output[key] = copy(item) end
    return output
end

local function key(x, y, z)
    return tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
end

local Properties = {}
function Properties:has(flag) return flag == "water" and self.water == true end

for x = 0, 2 do
    for y = 0, 2 do
        local square = { water = x == 2 and y == 1, isFree = function() return true end }
        function square:getProperties() return setmetatable({ water = self.water }, { __index = Properties }) end
        squares[key(x, y, 0)] = square
    end
end

_G.IsoFlagType = { water = "water" }
_G.getCell = function()
    return {
        getGridSquare = function(_, x, y, z) return squares[key(x, y, z)] end,
    }
end

local GridRegion = {}
function GridRegion.validate(region) return true, nil, region end
function GridRegion.bounds(region)
    local level = region.levels[0]
    local minX, maxX, minY, maxY
    for y, span in pairs(level.rows) do
        minX = minX and math.min(minX, span[1]) or span[1]
        maxX = maxX and math.max(maxX, span[2]) or span[2]
        minY = minY and math.min(minY, y) or y
        maxY = maxY and math.max(maxY, y) or y
    end
    return { minX = minX, maxX = maxX, minY = minY, maxY = maxY,
        minZ = 0, maxZ = 0 }
end
package.preload["PsychopatzCore/World/PC_GridRegion"] = function() return GridRegion end
package.preload["PsychopatzCore/World/PC_ZoneRegistry"] = function()
    return { register = function() return true end }
end

local SharedFishing = T.load("ProjectHoomans", "shared",
    "PNC/Core/Fishing/PNC_Fishing.lua")

PNC = {
    Fishing = SharedFishing,
    Const = {
        FISHING_DEFAULT_RADIUS = 16,
        FISHING_MAX_ZONE_TILES = 10000,
        FISHING_MAX_WORKERS = 16,
        FISHING_WORK_POINTS_PER_SECOND = 20,
        FISHING_REQUIRED_WORK_POINTS = 100,
        FISHING_BASE_CATCH_CHANCE = 0.25,
        FISHING_SKILL_CATCH_BONUS = 0.05,
        FISHING_FATIGUE_STOP = 0.70,
        ORDER_FISHING = "fishing",
    },
    Core = {
        Now = function() return now end,
        GenerateID = function(prefix)
            serial = serial + 1
            return tostring(prefix) .. ":" .. tostring(serial)
        end,
        DeepCopy = copy,
    },
    Registry = {
        Get = function(id) return records[tostring(id)] end,
        GetLiveZombie = function() return nil end,
    },
    Inventory = {
        CanAccept = function() return canAccept, canAccept and "accepted" or "no_capacity" end,
        AddItems = function(_, specs)
            added[#added + 1] = specs[1]
            return true, "added"
        end,
    },
    Skills = {
        GetLevel = function() return 4 end,
        AddXP = function() return true end,
    },
    OrderSystem = {
        SetOrder = function(record, order) record.orderSpec = copy(order) end,
    },
    Tasking = { Events = { Emit = function() end } },
}

local Service = T.load("ProjectHoomans", "server",
    "PNC/Fishing/PNC_FishingService.lua")
local zone, reason = Service.CreateZone({
    id = "fishing:test", minX = 0, minY = 0, maxX = 2, maxY = 2, z = 0,
    npcIds = { "npc" }, catchChance = 1, requiredWorkPoints = 100,
    workPointsPerSecond = 20,
})
T.truthy(zone, reason or "fishing zone creation")
T.equal(zone.valid, true, "water and land validate")
T.truthy(#zone.fishingSpots > 0, "shoreline spot derived")
T.equal(zone.fishingSpots[1].waterX, 2.5, "spot faces water")

local lease = { npcId = "npc", leaseId = "lease:fishing", executionMode = "ABSTRACT" }
T.truthy(Service.StartJob(lease), "abstract fishing start")
now = 12000
local ticked, _, tickReason = Service.TickJob(lease)
T.truthy(ticked, tickReason or "abstract fishing tick")
T.truthy(#added > 0, "catch enters canonical inventory")
T.truthy(Service.GetJob("npc").catches > 0, "catch count advances")

records.npc.fatigue = 0.71
local tiredOK, _, tiredReason = Service.TickJob(lease)
T.falsy(tiredOK, "tired NPC stops fishing")
T.equal(tiredReason, "fishing_npc_tired", "tired stop reason")
records.npc.fatigue = 0
records.npc.x, records.npc.y = 100, 100
local farOK, _, farReason = Service.TickJob(lease)
T.falsy(farOK, "far abstract NPC cannot fish")
T.equal(farReason, "fishing_npc_not_nearby", "nearby gate reason")
records.npc.x, records.npc.y = 1.5, 1.5
canAccept = false
local fullOK, _, fullReason = Service.TickJob(lease)
T.falsy(fullOK, "full inventory stops fishing")
T.equal(fullReason, "fishing_inventory_full", "full inventory stop reason")

T.finish("pnc_fishing_service_smoke")
