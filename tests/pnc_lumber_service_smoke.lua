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
local fatigueReads = 0
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
    IndividualNeeds = {
        Get = function(record, needType)
            fatigueReads = fatigueReads + 1
            return needType == "fatigue" and record.fatigue or nil
        end,
    },
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
local abstractOutputEffect = Service.GetTree("1:1:0").outputEffect
T.equal(abstractOutputEffect.kind, "LUMBER_OUTPUT",
    "abstract output creates a durable ledger effect")
T.equal(abstractOutputEffect.state, "APPLIED",
    "abstract output ledger reaches delivered state")
T.equal(abstractOutputEffect.items[1].quantity, 2,
    "abstract output ledger preserves the delivered batch")
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
local liveSquare = {
    worldObjects = {},
    getTree = function() return liveTree end,
    isFree = function() return true end,
}
function liveSquare:getWorldObjects()
    return self.worldObjects
end
function liveSquare:removeWorldObject(worldObject)
    for index, value in ipairs(self.worldObjects) do
        if value == worldObject then
            table.remove(self.worldObjects, index)
            return true
        end
    end
    return false
end
squares[liveKey] = liveSquare
local function newWorldItem(id, fullType)
    local item = { id = id, fullType = fullType, modData = {} }
    function item:getID() return self.id end
    function item:getFullType() return self.fullType end
    function item:getType() return self.fullType end
    function item:getModData() return self.modData end
    return item
end
local function newWorldObject(item)
    local worldObject = { item = item }
    function worldObject:getItem() return self.item end
    function worldObject:getKeyId() return self.item.id end
    return worldObject
end
local inventory = { items = {} }
function inventory:getItems() return self.items end
function inventory:canAddItem() return true end
function inventory:AddItem(item)
    self.items[#self.items + 1] = item
    return item
end
liveTree.WeaponHit = function(self)
    self.hits = self.hits + 1
    self.health = 0
    local log = newWorldItem("wood:1", "Base.Log")
    local splinters = newWorldItem("wood:2", "Base.Splinters")
    liveSquare.worldObjects[#liveSquare.worldObjects + 1] = newWorldObject(log)
    liveSquare.worldObjects[#liveSquare.worldObjects + 1] = newWorldObject(splinters)
end
local axe = {
    fullType = "Base.Axe",
    hasTag = function(_, tag) return tag == "chop" end,
    getTreeDamage = function() return 35 end,
    isBroken = function() return false end,
}
function axe:getFullType() return self.fullType end
function axe:getID() return "axe:1" end
local moveCalls = 0
local liveToolCreated = false
local enduranceChecks = 0
local body = {
    x = 2.5, y = 4.5, z = 0, primary = nil,
    inventory = inventory,
    getPrimaryHandItem = function(self) return self.primary end,
    getInventory = function(self) return self.inventory end,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function(self) return self.z end,
    getMoodles = function() return nil end,
    isEnduranceSufficientForAction = function()
        enduranceChecks = enduranceChecks + 1
        return false
    end,
    setVariable = function() end,
    faceLocationF = function() end,
    setPrimaryHandItem = function(self, item) self.primary = item end,
}
ItemTag = { CHOP_TREE = "chop" }
PNC.BehaviorCommon = {
    MoveRecord = function(_, zombie)
        moveCalls = moveCalls + 1
        zombie.lastMoveReason = "lumber"
    end,
    HaltMovement = function() end,
}
PNC.Equipment = {
    EnsureCombatHands = function() return true, "server_replica" end,
    CreateItem = function(fullType)
        liveToolCreated = fullType == "Base.Axe"
        return axe
    end,
}
records.live = {
    id = "live", alive = true, x = 2.5, y = 4.5, z = 0,
    fatigue = 0,
    presenceState = "live", equipment = { primaryFullType = "Base.Axe" },
    runtime = {},
}
local liveZombieLookup = function(id)
    return tostring(id) == "live" and body or nil
end
PNC.Registry.GetLiveZombie = liveZombieLookup
local liveZone = Service.CreateZone({
    id = "lumber:live", minX = 3, minY = 3, maxX = 4, maxY = 4, z = 0,
})
Service.ScanZone(liveZone.id, 32)
T.truthy(Service.AssignWorker(liveZone.id, "live"))
local liveLease = { npcId = "live", leaseId = "lease:live",
    executionMode = "LIVE" }
T.truthy(Service.StartJob(liveLease), "live job start")
now = 5000
T.truthy(Service.TickJob(liveLease), "live travel tick")
T.equal(moveCalls, 1, "live lumber reissues movement when not adjacent")
squares[liveKey] = nil
now = 6500
local waitingTick, waitingComplete = Service.TickJob(liveLease)
T.truthy(waitingTick and not waitingComplete,
    "live lumber waits for an unloaded target chunk")
T.equal(Service.GetTree(liveKey).status, "IN_PROGRESS",
    "unloaded live target is not invalidated")
T.equal(Service.GetJob("live").phase, "WAITING_FOR_TREE_CHUNK",
    "unloaded live target exposes its wait phase")
T.equal(records.live.runtime.lumber.waitingFor, "world",
    "unloaded live target publishes a world wait diagnostic")
squares[liveKey] = liveSquare
body.x, records.live.x = 3.5, 3.5
now = 8000
T.truthy(Service.TickJob(liveLease), "live chopping tick")
T.truthy(liveToolCreated, "live lumber materialized the configured axe")
T.equal(body.primary, axe, "live lumber equips the axe in the primary hand")
T.equal(#inventory.items, 1, "live lumber owns the axe in the inventory")
T.truthy(fatigueReads > 0,
    "live lumber reads the NPC-owned fatigue system")
T.equal(enduranceChecks, 0,
    "live lumber never probes player endurance or Moodles")
T.equal(liveTree.hits, 1, "server live tree hit")
T.equal(Service.GetTree(liveKey).status, "DEPLETED",
    "live tree depletion")
local liveOutputEffect = Service.GetTree(liveKey).outputEffect
T.equal(liveOutputEffect.state, "PENDING",
    "live output remains pending for floor pickup")
T.equal(liveOutputEffect.deliveryMode, "WORLD_FLOOR",
    "live output records its world-floor delivery mode")
T.equal(liveOutputEffect.lootSource, "vanilla_tree_loot",
    "live output records the vanilla tree loot source")
T.equal(#liveSquare.worldObjects, 2,
    "live tree produced its vanilla floor objects")
T.equal(liveOutputEffect.items[1].fullType, "Base.Log",
    "live output captures the vanilla floor item type")
T.equal(liveOutputEffect.items[1].id, "wood:1",
    "live output captures the vanilla floor item identity")
T.equal(liveOutputEffect.items[2].fullType, "Base.Splinters",
    "live output captures secondary vanilla loot")
T.equal(liveOutputEffect.actualQuantity, 2,
    "live output captures the complete loot quantity")
T.equal(#outputs, 1, "live output is owned by vanilla")

PNC.Registry.GetLiveZombie = function() return nil end
now = 8500
local workerWaitTick, workerWaitComplete = Service.TickJob(liveLease)
T.truthy(workerWaitTick and not workerWaitComplete,
    "live output waits when its NPC body is unavailable")
T.equal(Service.GetJob("live").phase, "WAITING_FOR_WORKER",
    "live output records the missing worker phase")
T.equal(liveOutputEffect.waitReason, "LUMBER_LIVE_WORKER_REQUIRED",
    "live output exposes the missing worker in the ledger")
PNC.Registry.GetLiveZombie = liveZombieLookup

-- Live output is a durable delivery pipeline: the worker performs a one-shot
-- grab animation, removes the exact tagged floor item, carries it to the
-- selected stockpile, performs a deposit animation, then transfers it into
-- storage. These mocks model only the engine boundaries needed by that flow.
local stockpile = { id = "storage:1" }
local transferCalls, activityCalls = 0, 0
PNC.AnimationScenes = {
    Request = function(record, _, sceneID)
        record.runtime.lastAnimationScene = {
            id = sceneID, reason = "completed",
        }
        return true
    end,
    Stop = function() end,
}
PNC.Inventory.CaptureLooseInventory = function(record, actor)
    record.inventory = { items = {} }
    for _, item in ipairs(actor.inventory.items) do
        record.inventory.items[#record.inventory.items + 1] = {
            id = item:getID(), type = item:getFullType(), stack = 1,
        }
    end
    return true
end
PNC.HomeDutyService = {
    GetBase = function()
        return { id = "base:1", factionId = "faction:1",
            settlementId = "settlement:1" }
    end,
}
PNC.StockpileAccessService = {
    FindNearest = function()
        return { id = "node:1", storageId = "storage:1",
            x = 6.0, y = 6.0, z = 0 }
    end,
}
PNC.ColonyStorageRepository = {
    Get = function(id) return id == stockpile.id and stockpile or nil end,
}
PNC.ColonyStorageService = {
    Internal = {
        LiveNPCSource = function(record, item, quantity, actor)
            return { record = record, item = item, quantity = quantity,
                actor = actor }
        end,
        TransferIntoStorage = function(_, source, quantity)
            transferCalls = transferCalls + quantity
            source.item.stack = source.item.stack - quantity
            return true
        end,
        RecordActivity = function() activityCalls = activityCalls + 1 end,
    },
}
body.x, body.y, records.live.x, records.live.y = 4.5, 4.5, 4.5, 4.5
now = 9500
local outputTick = Service.TickJob(liveLease)
T.truthy(outputTick, "live output approaches its floor loot")
now = 10000
outputTick = Service.TickJob(liveLease)
T.truthy(outputTick, "live output completes its grab animation")
T.equal(liveOutputEffect.pickupState, "NPC_INVENTORY",
    "live output records the worker pickup")
T.equal(#liveSquare.worldObjects, 0,
    "live pickup removes the tagged floor item")
T.equal(#inventory.items, 3,
    "live pickup adds floor loot alongside the equipped axe")
T.equal(Service.GetJob("live").phase, "OUTPUT_DESTINATION_APPROACH",
    "live pickup advances to stockpile travel")
T.equal(liveOutputEffect.destinationNodeId, "node:1",
    "live output persists the selected stockpile node")
T.equal(liveOutputEffect.destinationStorageId, "storage:1",
    "live output persists the selected storage")
body.x, body.y, records.live.x, records.live.y = 6.0, 6.0, 6.0, 6.0
now = 11500
outputTick = Service.TickJob(liveLease)
T.truthy(outputTick, "live output approaches the stockpile")
now = 12000
outputTick = Service.TickJob(liveLease)
T.truthy(outputTick, "live output starts its deposit animation")
now = 12500
local outputWorked, outputComplete = Service.TickJob(liveLease)
T.truthy(outputWorked and outputComplete,
    "live output deposits and completes the lumber job")
T.equal(transferCalls, 2, "live output transfers all loot to storage")
T.equal(activityCalls, 1, "live output records stockpile activity")
T.equal(liveOutputEffect.state, "APPLIED",
    "live output ledger reaches applied state")
T.equal(liveOutputEffect.pickupState, "STOCKPILE",
    "live output records final delivery")
T.falsy(Service.GetJob("live").pendingOutput,
    "live output clears the durable pending batch")

local missingTool = {
    id = "missing-tool", alive = true, equipment = {}, inventory = {},
}
local missingDiagnostic = Service.GetToolDiagnostic(missingTool, nil)
T.falsy(missingDiagnostic.usable, "missing lumber tool is not usable")
T.equal(missingDiagnostic.reason, "lumber_tool_missing",
    "lumber diagnostic identifies the missing tool")
local abstractDiagnostic = Service.GetToolDiagnostic(records.worker, nil)
T.truthy(abstractDiagnostic.usable,
    "abstract lumber diagnostic accepts the canonical equipped axe")
T.equal(abstractDiagnostic.source, "canonical_inventory",
    "abstract lumber diagnostic identifies its source")

-- Management snapshots expose the WorkService bridge without replacing the
-- LumberService tree ledger as the source of execution state.
local liveJob = Service.GetJob("live")
liveJob.workOrderId = "work:live"
PNC.WorkRepository = {
    Get = function(id)
        return id == "work:live" and {
            status = "WORKING", progress = 0, requiredWork = 1,
        } or nil
    end,
}
local liveSnapshot = Service.GetSnapshot(liveZone.id)
T.equal(liveSnapshot.workers[1].executionMode, "LIVE",
    "lumber snapshot reports live execution")
T.equal(liveSnapshot.workers[1].workOrderId, "work:live",
    "lumber snapshot reports durable work order")
T.equal(liveSnapshot.workers[1].workOrderStatus, "WORKING",
    "lumber snapshot reports work order status")

T.finish("pnc_lumber_service_smoke")
