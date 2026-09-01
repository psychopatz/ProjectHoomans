local T = require "tests/support/test"

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, item in pairs(value) do output[key] = copy(item) end
    return output
end

local GridRegion = {}
function GridRegion.validate(region) return true, nil, region end
function GridRegion.bounds(region)
    local level = region.levels[0]
    local rows = level.rows
    local minX, maxX, minY, maxY
    for y, spans in pairs(rows) do
        minX = minX and math.min(minX, spans[1]) or spans[1]
        maxX = maxX and math.max(maxX, spans[2]) or spans[2]
        minY = minY and math.min(minY, y) or y
        maxY = maxY and math.max(maxY, y) or y
    end
    return { minX = minX, maxX = maxX, minY = minY, maxY = maxY,
        minZ = 0, maxZ = 0 }
end
function GridRegion.containsPoint(_, x, y, z)
    return z == 0 and x >= 0 and x <= 4 and y >= 0 and y <= 4
end
function GridRegion.countTiles(region)
    local total = 0
    for _, level in pairs(region.levels) do
        for _, spans in pairs(level.rows) do
            total = total + spans[2] - spans[1] + 1
        end
    end
    return total
end
package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return GridRegion
end
local CoreZones = { records = {} }
function CoreZones.register(zone)
    CoreZones.records[zone.id] = zone
    return true, zone
end
function CoreZones.remove(id) CoreZones.records[id] = nil; return true end
package.preload["PsychopatzCore/World/PC_ZoneRegistry"] = function()
    return CoreZones
end

local now, serial = 1000, 0
local records = {}
local squares = {}
local outputs = {}
_G.getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            return squares[tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)]
        end,
    }
end

local function newTree(health, logYield)
    local tree = { health = health, hits = 0, logYield = logYield or 1 }
    function tree:getSize() return 3 end
    function tree:getLogYield() return self.logYield end
    function tree:getHealth() return self.health end
    function tree:WeaponHit()
        self.hits = self.hits + 1
        self.health = 0
        squares["4:4:0"] = nil
    end
    return tree
end

local abstractTree = newTree(10, 2)
squares["1:1:0"] = {
    x = 1, y = 1, z = 0,
    getTree = function() return abstractTree end,
    isFree = function() return true end,
}
for x = 0, 4 do
    for y = 0, 4 do
        local key = tostring(x) .. ":" .. tostring(y) .. ":0"
        squares[key] = squares[key] or {
            isFree = function() return true end,
        }
    end
end
squares["1:1:0"].getTree = function() return abstractTree end

PNC = {
    Const = { ORDER_LUMBER = "lumber" },
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
        MarkDirty = function() end,
    },
    Tasking = { Events = { Emit = function() end } },
    Inventory = {
        AddItems = function(_, specs)
            outputs[#outputs + 1] = specs[1]
            return true, "added"
        end,
    },
    OrderSystem = {
        SetOrder = function(record, spec) record.orderSpec = copy(spec) end,
    },
}
local loadGridSquare
Events = {
    OnInitGlobalModData = { Add = function() end },
    OnSave = { Add = function() end },
    LoadGridsquare = { Add = function(fn) loadGridSquare = fn end },
}

local Service = T.load("ProjectHoomans", "server",
    "PNC/Lumber/PNC_LumberService.lua")
local zone, reason = Service.CreateZone({
    id = "lumber:test",
    minX = 0, minY = 0, maxX = 2, maxY = 2, z = 0,
})
T.truthy(zone, reason or "zone creation")
T.equal(CoreZones.records[zone.id].type, "lumber",
    "zone registered with core")
T.equal(Service.ScanZone(zone.id, 32), true, "bounded zone scan")
local tree = Service.GetTree("1:1:0")
T.truthy(tree, "loaded tree discovered")
T.equal(tree.remainingWork, 10, "tree ledger starts from health")

-- Once the square is unavailable, abstract work may advance the ledger but
-- must not touch the physical tree object.
squares["1:1:0"] = nil
records.worker = {
    id = "worker", alive = true, x = 0, y = 0, z = 0,
    presenceState = "abstract", equipment = {
        primaryFullType = "Base.Axe",
    },
}
T.truthy(Service.AssignWorker(zone.id, "worker"))
local job = Service.GetJob("worker")
local lease = { npcId = "worker", leaseId = "lease:abstract",
    executionMode = "ABSTRACT" }
T.truthy(Service.StartJob(lease), "abstract job start")
now = 2500
local ticked, complete = Service.TickJob(lease)
T.truthy(ticked and not complete, "abstract chopping tick")
now = 4000
ticked, complete = Service.TickJob(lease)
T.truthy(ticked and not complete, "abstract output tick")
T.equal(Service.GetTree("1:1:0").status, "DEPLETED",
    "abstract ledger depletion")
T.equal(outputs[1].type, "Base.Log", "abstract output type")
T.equal(outputs[1].stack, 2, "abstract output yield")
Service.RestoreOrder("worker")
T.equal(records.worker.orderSpec, nil,
    "lumber completion restores the default order when none existed")

-- If the completed abstract tree becomes loaded later, remove only the
-- already-accounted-for tree object without dropping a second wood reward.
local reconciled = false
squares["1:1:0"] = {
    x = 1, y = 1, z = 0,
    getTree = function() return abstractTree end,
    transmitRemoveItemFromSquare = function(_, object)
        reconciled = object == abstractTree
        squares["1:1:0"] = nil
        return 1
    end,
}
T.truthy(loadGridSquare, "tree-load reconciliation hook")
loadGridSquare(squares["1:1:0"])
T.truthy(reconciled, "abstract completion reconciles loaded tree")

-- An initially unloaded zone remains discoverable and retries its unresolved
-- tiles when the corresponding chunk becomes available.
local retryZone = Service.CreateZone({
    id = "lumber:retry", minX = 4, minY = 4, maxX = 4, maxY = 4, z = 0,
})
squares["4:4:0"] = nil
Service.ScanZone(retryZone.id, 4)
T.equal(retryZone.scan.complete, false, "unloaded scan remains pending")
local retryTree = newTree(10, 1)
squares["4:4:0"] = {
    getTree = function() return retryTree end,
    isFree = function() return true end,
}
Service.ScanZone(retryZone.id, 1)
T.truthy(Service.GetTree("4:4:0"), "unloaded tile is retried")

-- Live work uses the physical tree's WeaponHit path and does not duplicate
-- the vanilla world output into the abstract inventory.
local liveTree = newTree(10, 1)
local liveKey = "4:4:0"
squares[liveKey] = {
    getTree = function() return liveTree end,
    isFree = function() return true end,
}
local axe = {
    hasTag = function(_, tag) return tag == "chop" end,
    getTreeDamage = function() return 35 end,
    isBroken = function() return false end,
}
local body = {
    getPrimaryHandItem = function() return axe end,
    getX = function() return 4.5 end,
    getY = function() return 4.5 end,
    getZ = function() return 0 end,
    setVariable = function() end,
    faceLocationF = function() end,
}
ItemTag = { CHOP_TREE = "chop" }
records.live = {
    id = "live", alive = true, x = 4.5, y = 4.5, z = 0,
    presenceState = "live", equipment = { primaryFullType = "Base.Axe" },
    runtime = {},
}
PNC.Registry.GetLiveZombie = function(id)
    return tostring(id) == "live" and body or nil
end
local liveZone = Service.CreateZone({
    id = "lumber:live", minX = 3, minY = 3, maxX = 4, maxY = 4, z = 0,
})
Service.ScanZone(liveZone.id, 32)
T.truthy(Service.AssignWorker(liveZone.id, "live"))
local liveLease = { npcId = "live", leaseId = "lease:live",
    executionMode = "LIVE" }
T.truthy(Service.StartJob(liveLease), "live job start")
now = 5000
T.truthy(Service.TickJob(liveLease), "live chopping tick")
T.equal(liveTree.hits, 1, "server live tree hit")
T.equal(Service.GetTree(liveKey).status, "DEPLETED",
    "live tree depletion")
T.equal(#outputs, 1, "live output is owned by vanilla")

T.finish("pnc_lumber_service_smoke")
