local T = require "tests/support/test"

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local now = 1000
local serial = 0
local rod = { id = "rod", fullType = "Base.FishingRod", cond = 10 }
local body = {
    x = 0, y = 0, z = 0, primary = rod,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function(self) return self.z end,
    getPrimaryHandItem = function(self) return self.primary end,
}
local record = {
    id = "npc:live-fishing",
    alive = true,
    recruited = true,
    presenceState = "live",
    equipment = { primaryFullType = "Base.FishingRod" },
    inventory = {
        items = { rod = rod },
        equipped = { primary = "rod" },
    },
}

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, item in pairs(value) do output[key] = copy(item) end
    return output
end

local squares = {}
local function key(x, y, z)
    return tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
end

local Properties = {}
function Properties:has(flag)
    return flag == "water" and self.water == true
end

for x = 0, 2 do
    for y = 0, 2 do
        local square = {
            water = x == 2 and y == 1,
            isFree = function() return true end,
        }
        function square:getProperties()
            return setmetatable({ water = self.water }, { __index = Properties })
        end
        squares[key(x, y, 0)] = square
    end
end

_G.IsoFlagType = { water = "water" }
_G.getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            return squares[key(x, y, z)]
        end,
    }
end

local GridRegion = {}
function GridRegion.validate(region) return true, nil, region end
function GridRegion.bounds(region)
    return { minX = 0, maxX = 2, minY = 0, maxY = 2,
        minZ = 0, maxZ = 0 }
end
function GridRegion.countTiles() return 9 end
function GridRegion.isConnected() return true end
package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return GridRegion
end
package.preload["PsychopatzCore/World/PC_ZoneRegistry"] = function()
    return { register = function() return true end }
end

local added = 0
PNC = {
    Fishing = T.load("ProjectHoomans", "shared",
        "PNC/Core/Fishing/PNC_Fishing.lua"),
    Const = {
        FISHING_DEFAULT_RADIUS = 16,
        FISHING_INTERACTION_RADIUS = 1.75,
        FISHING_MAX_ZONE_TILES = 10000,
        FISHING_MAX_WORKERS = 16,
        FISHING_WORK_POINTS_PER_SECOND = 20,
        FISHING_REQUIRED_WORK_POINTS = 100,
        FISHING_BASE_CATCH_CHANCE = 1,
        FISHING_SKILL_CATCH_BONUS = 0,
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
        Get = function() return record end,
        GetLiveZombie = function() return body end,
    },
    Inventory = {
        CanAccept = function() return true, "accepted" end,
        AddItems = function(_, specs)
            added = added + #specs
            return true, "added"
        end,
    },
    Skills = { GetLevel = function() return 0 end,
        AddXP = function() return true end },
    OrderSystem = {
        SetOrder = function(target, order)
            target.orderSpec = copy(order)
        end,
    },
    Tasking = { Events = { Emit = function() end } },
}

local Service = T.load("ProjectHoomans", "server",
    "PNC/Fishing/PNC_FishingService.lua")
local zone, reason = Service.CreateZone({
    id = "fishing:live-arrival", minX = 0, minY = 0,
    maxX = 2, maxY = 2, z = 0, npcIds = { record.id },
    catchChance = 1, requiredWorkPoints = 100,
    workPointsPerSecond = 20,
})
T.truthy(zone, reason or "live fishing zone creation")
local spot = zone.fishingSpots[1]
T.truthy(spot, "live fishing stand point exists")

body.x, body.y, body.z = spot.standX + 0.46, spot.standY + 1.61, spot.standZ
record.x, record.y, record.z = body.x, body.y, body.z
T.truthy(Service.AssignWorker(zone.id, record.id), "live worker assigned")
local lease = {
    npcId = record.id, leaseId = "lease:live-fishing", executionMode = "LIVE",
}
T.truthy(Service.StartJob(lease), "live fishing started")
T.equal(Service.GetJob(record.id).phase, "TOOL_CHECK",
    "nearby live fishing starts in the explicit tool-check phase")

now = 2500
local ticked, _, tickReason = Service.TickJob(lease)
T.truthy(ticked, tickReason or "live fishing tick")
T.equal(Service.GetJob(record.id).phase, "WORKING",
    "nearby live fishing promotes into the working phase")
T.equal(record.runtime.fishing.phase, "WORKING",
    "shared fishing runtime exposes the working phase")

T.finish("pnc_fishing_live_arrival_smoke")
