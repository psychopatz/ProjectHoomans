local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
})

local nowMs = 10000
local serial = 0
local worldPlants = {}
local worldSquares = {
    ["10:20:0"] = {
        getX = function() return 10 end,
        getY = function() return 20 end,
        getZ = function() return 0 end,
        getFloor = function() return { getSpriteName = function() return "blends_natural_01_64" end } end,
    },
}

SFarmingSystem = {
    instance = {
        getLuaObjectAt = function(_, x, y, z)
            return worldPlants[tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)]
        end,
        plow = function(_, sq)
            local key = tostring(sq:getX()) .. ":" .. tostring(sq:getY()) .. ":" .. tostring(sq:getZ())
            local p = {
                state = "plow", waterLvl = 0, nbOfGrow = 0,
                isAlive = function() return true end,
                canHarvest = function(self) return self.mature == true end,
                seed = function(self, cropType)
                    self.state = "seeded"
                    self.typeOfSeed = cropType
                    self.waterLvl = 60
                end,
                water = function(self, _, uses)
                    self.waterLvl = math.min(100, (self.waterLvl or 0) + uses * 100)
                end,
            }
            worldPlants[key] = p
        end,
        harvest = function(_, target)
            target.state = "plow"
            target.mature = false
            -- simulate yield delivered to worker inventory
            PNC._testHarvestGrant("Base.Cabbage", 3)
        end,
    },
}
farming_vegetableconf = {
    props = {
        Cabbages = {
            seedTypes = { "Base.CabbageSeed" },
            vegetableName = "Base.Cabbage",
            timeToGrow = 5,
            harvestLevel = 1,
        },
    },
}
getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            return worldSquares[tostring(math.floor(x)) .. ":" .. tostring(math.floor(y)) .. ":" .. tostring(z)]
        end,
    }
end

local storageStock = {
    ["Base.Trowel"] = 1,
    ["Base.CabbageSeed"] = 5,
    ["Base.WateringCan"] = 1,
}
local deposits = {}
local reservations = {}
local orders = {}

local worker = {
    id = "colonist-1",
    name = "Colonist One",
    alive = true,
    x = 5,
    y = 5,
    z = 0,
    affiliation = { role = "worker", communityID = "col-1" },
    workPolicy = { Farmer = true },
    inventory = { items = {} },
    runtime = {},
}
local liveBody = {
    getX = function() return worker.x end,
    getY = function() return worker.y end,
    getZ = function() return worker.z end,
    getInventory = function() return { getItems = function() return { size = function() return 0 end } end } end,
}

local function grantItem(ft, qty)
    local items = worker.inventory.items
    for _, it in pairs(items) do
        if it.type == ft then it.stack = it.stack + qty return end
    end
    serial = serial + 1
    items["item:" .. tostring(serial)] = { id = "item:" .. tostring(serial), type = ft, stack = qty }
end

PNC = {
    Core = {
        Now = function() return nowMs end,
        GenerateID = function(p) serial = serial + 1 return tostring(p) .. ":" .. tostring(serial) end,
    },
    _testHarvestGrant = grantItem,
    Translation = { GetKey = function(_, fb) return fb end },
    Registry = {
        Get = function(id) return id == worker.id and worker or nil end,
        GetLiveZombie = function(id) return id == worker.id and liveBody or nil end,
    },
    BaseService = {
        Get = function(id) return id == "base:1" and { id = "base:1", colonyId = "col-1", factionId = "fac-1" } or nil end,
        GetForColony = function(cid) return cid == "col-1" and { id = "base:1", colonyId = "col-1", factionId = "fac-1" } or nil end,
    },
    HomeDutyService = {
        IsCamped = function() return false end,
        GetBase = function() return { id = "base:1", colonyId = "col-1", factionId = "fac-1" } end,
    },
    WorkPolicy = {
        IsEnabled = function(r, job) return r.workPolicy and r.workPolicy[job] == true end,
        GetPriority = function() return 5 end,
    },
    Inventory = {
        EnsureRecordInventory = function(r) return r.inventory end,
        CaptureLooseInventory = function() return true end,
        RemoveCoreItemIds = function(r, ids)
            for _, id in ipairs(ids) do
                if r.inventory.items[id] then
                    r.inventory.items[id].stack = math.max(0, r.inventory.items[id].stack - 1)
                end
            end
            return true
        end,
    },
    SupplyInventory = {
        RemoveCoreItemIds = function(r, ids)
            for _, id in ipairs(ids) do
                if r.inventory.items[id] then
                    r.inventory.items[id].stack = math.max(0, r.inventory.items[id].stack - 1)
                end
            end
            return true
        end,
    },
    BehaviorCommon = {
        ClearCombatTarget = function() end,
        MoveRecord = function(r, _, x, y, z) r.movedTo = { x = x, y = y, z = z } end,
        HaltMovement = function() end,
    },
    AnimationScenes = {
        Request = function(r, _, sceneId)
            r.runtime.lastAnimationScene = { id = sceneId, reason = "completed" }
            return true
        end,
    },
    StockpileAccessService = {
        FindNearest = function() return { id = "node-1", storageId = "stor-1", x = 5, y = 5, z = 0 } end,
    },
    ColonyStorageRepository = {
        GetPrimary = function()
            local rows = {}
            for ft, q in pairs(storageStock) do
                if q > 0 then rows[#rows + 1] = { fullType = ft, quantity = q } end
            end
            return {
                id = "stor-1", revision = 1,
                access = { x = 5, y = 5, z = 0 },
                rows = rows,
                inventory = { records = {} },
            }
        end,
        Get = function(id) return id == "stor-1" and PNC.ColonyStorageRepository.GetPrimary() or nil end,
    },
    ColonyStorageService = {
        GetStorageRevision = function() return 1 end,
        HasStorageChanged = function() return false end,
        LiveNPCSource = function(_, item, qty)
            return { item = item, quantity = qty, preview = function() return { { type = item.type, stack = qty, unitWeight = 1 } } end }
        end,
        ReserveOutputCapacity = function() return true end,
        ReleaseOutputCapacity = function() return true end,
        TransferIntoStorage = function(_, source, qty)
            storageStock[source.item.type] = (storageStock[source.item.type] or 0) + qty
            deposits[#deposits + 1] = { type = source.item.type, quantity = qty }
            return true
        end,
        DepositProductionItems = function(_, items)
            for _, p in ipairs(items) do
                storageStock[p.fullType] = (storageStock[p.fullType] or 0) + p.quantity
                deposits[#deposits + 1] = { type = p.fullType, quantity = p.quantity }
            end
            return true
        end,
        ReserveProductionMaterials = function(_, reqs)
            for _, req in ipairs(reqs) do
                for _, ft in ipairs(req.itemTypes or {}) do
                    if (storageStock[ft] or 0) >= req.amount then
                        serial = serial + 1
                        reservations["res:" .. serial] = { fullType = ft, amount = req.amount }
                        return { id = "res:" .. serial, requirements = { { selectedType = ft } } }
                    end
                end
            end
            return nil, "MATERIALS_NOT_AVAILABLE"
        end,
        CollectProductionReservation = function(resId)
            local r = reservations[resId]
            if not r then return false, "res_missing" end
            storageStock[r.fullType] = (storageStock[r.fullType] or 0) - r.amount
            grantItem(r.fullType, r.amount)
            reservations[resId] = nil
            return true, { itemIds = { "collected" }, records = {} }
        end,
        ReleaseProductionReservation = function() return true end,
    },
    WorkItemService = {
        OperationHasRequirements = function(op) return op == "FARMING" end,
        Ensure = function(rec, _, _, _)
            for _, it in pairs(rec.inventory.items) do
                if it.type == "Base.Trowel" and it.stack > 0 then return true end
            end
            return false, "DIGGING_TOOL_MISSING"
        end,
        Release = function() return true end,
    },
    WorkDefinitions = {
        STATUS = { QUEUED = "QUEUED", CANCELLED = "CANCELLED", COMPLETED = "COMPLETED", FAILED = "FAILED", WORKING = "WORKING" },
    },
    WorkService = {
        RegisterOperation = function(op, handlers) PNC._reg = PNC._reg or {} PNC._reg[op] = handlers return true end,
        Commands = {
            Queue = function(spec)
                local id = spec.id or "work:1"
                orders[id] = { id = id, operation = spec.operation, colonyId = "col-1", factionId = "fac-1",
                    baseId = "base:1", requiredWork = 1, priority = spec.priority, precedence = spec.precedence,
                    payload = spec.payload, status = "QUEUED" }
                return orders[id]
            end,
            Cancel = function(id) if orders[id] then orders[id].status = "CANCELLED" end return true end,
            AddProgress = function(id) if orders[id] then orders[id].status = "COMPLETED" end return true end,
        },
        Queries = { Get = function(id) return orders[id] end },
    },
    WorkRepository = { MarkDirty = function() end },
}

T.load("ProjectHoomans", "shared", "PNC/Core/Farming/PNC_PlantingCatalog.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Farming/PNC_Farming.lua")
T.load("ProjectHoomans", "server", "PNC/Production/PNC_WorkInputService.lua")
T.load("ProjectHoomans", "server", "PNC/Production/PNC_WorkOutputService.lua")
T.load("ProjectHoomans", "server", "PNC/Production/WorkService/PNC_WorkToilRunner.lua")
T.load("ProjectHoomans", "server", "PNC/Farming/PNC_PZFarmingAdapter.lua")
T.load("ProjectHoomans", "server", "PNC/Farming/PNC_FarmingService.lua")
T.load("ProjectHoomans", "server", "PNC/Farming/PNC_FarmingWorkAdapter.lua")

-- Simulate WateringCan pickup + Trowel pickup from storage
grantItem("Base.Trowel", 1)

local zone, zErr = PNC.FarmingService.CreateZone({
    id = "farm-z1", ownerId = "col-1", colonyId = "col-1", factionId = "fac-1", baseId = "base:1",
    minX = 10, maxX = 10, minY = 20, maxY = 20, z = 0, desiredCrop = "cabbages",
})
T.truthy(zone ~= nil, "CreateZone succeeds without pre-built furrows: " .. tostring(zErr))

local order = orders["farming-zone:farm-z1"]
T.truthy(order ~= nil, "CreateZone automatically queues NORMAL_WORK FARMING order")
order.workerId = worker.id
local reg = PNC._reg.FARMING
T.truthy(reg ~= nil, "FARMING registered with WorkService")

-- 1. Live approach -> start farm animation -> plow unplowed dirt tile
worker.x, worker.y = 5, 5
T.truthy(reg.ExecutionHandler(order, { npcId = worker.id }) == true)
T.truthy(worker.movedTo ~= nil and worker.movedTo.x == 10.5, "Colonist walks toward farm tile to plow")
worker.x, worker.y = 10.5, 20.5
T.truthy(reg.ExecutionHandler(order, { npcId = worker.id }) == true) -- starts facility.farm.work
T.truthy(reg.ExecutionHandler(order, { npcId = worker.id }) == true) -- completes anim & plows
T.equal(worldPlants["10:20:0"] and worldPlants["10:20:0"].state, "plow", "Colonist plows raw dirt tile")

-- 2. Colonist lacks seeds -> returns to stockpile node to collect Base.CabbageSeed -> walks to tile -> plants
T.truthy(reg.ExecutionHandler(order, { npcId = worker.id }) == true) -- reserves & starts walking to stockpile (5,5)
T.truthy(worker.movedTo ~= nil and worker.movedTo.x == 5, "Colonist walks to stockpile node for seeds")
worker.x, worker.y = 5, 5
T.truthy(reg.ExecutionHandler(order, { npcId = worker.id }) == true) -- starts work.grab at stockpile
T.truthy(reg.ExecutionHandler(order, { npcId = worker.id }) == true) -- finishes work.grab & collects seed
T.truthy(reg.ExecutionHandler(order, { npcId = worker.id }) == true) -- starts walking back to tile (10.5,20.5)
worker.x, worker.y = 10.5, 20.5
T.truthy(reg.ExecutionHandler(order, { npcId = worker.id }) == true) -- starts facility.farm.work
T.truthy(reg.ExecutionHandler(order, { npcId = worker.id }) == true) -- completes anim & plants
T.equal(worldPlants["10:20:0"].state, "seeded", "Colonist physically seeds newly plowed tile")

-- 3. Well-watered GROWING zone has no actionable work -> completes order
worldPlants["10:20:0"].waterLvl = 100
T.falsy(PNC.FarmingService.HasActionableWork(zone), "Well-watered GROWING zone has no actionable work")
T.truthy(reg.ExecutionHandler(order, { npcId = worker.id }) == true)
T.equal(order.status, "COMPLETED", "Growing well-watered zone completes order so colonist is released")

-- 4. Crop matures -> HARVEST -> WorkOutputService delivers harvest to colony storage
worldPlants["10:20:0"].mature = true
local okH, hOrder = PNC.FarmingWorkAdapter.EnsureZoneOrder(zone)
T.truthy(okH and hOrder ~= nil, "Mature crop re-queues FARMING order")
hOrder.workerId = worker.id
worker.x, worker.y = 10.5, 20.5
T.truthy(reg.ExecutionHandler(hOrder, { npcId = worker.id }) == true) -- starts facility.farm.work
T.truthy(reg.ExecutionHandler(hOrder, { npcId = worker.id }) == true) -- harvests crop
T.truthy(hOrder.pendingOutput ~= nil, "Harvest registers output with WorkOutputService")
worker.x, worker.y = 5, 5
T.truthy(reg.ExecutionHandler(hOrder, { npcId = worker.id }) == true) -- starts work.deposit at stockpile
T.truthy(reg.ExecutionHandler(hOrder, { npcId = worker.id }) == true) -- completes deposit
T.truthy((storageStock["Base.Cabbage"] or 0) >= 3, "Harvested crops deposited into ColonyStorageRepository")

-- 5. Abstract progression: unplowed -> plow -> seed -> water -> grow -> harvest to storage
local azone = PNC.FarmingService.CreateZone({
    id = "farm-az", ownerId = "col-1", colonyId = "col-1", factionId = "fac-1", baseId = "base:1",
    minX = 30, maxX = 30, minY = 30, maxY = 30, z = 0, desiredCrop = "cabbages",
})
azone.abstractGrowthStepMs = 100
local aorder = orders["farming-zone:farm-az"]
aorder.workerId = worker.id
T.truthy(reg.AbstractExecutionHandler(aorder, { npcId = worker.id }) == true) -- PLOWED
T.equal(azone.abstractTiles[1].state, "plow", "Abstract plow advances tile to plow")
storageStock["Base.CabbageSeed"] = 5
T.truthy(reg.AbstractExecutionHandler(aorder, { npcId = worker.id }) == true) -- PLANTED
T.equal(azone.abstractTiles[1].state, "seeded", "Abstract plant advances tile to seeded")
azone.abstractTiles[1].waterLvl = 100
nowMs = nowMs + 500
T.truthy(reg.AbstractExecutionHandler(aorder, { npcId = worker.id }) == true) -- GREW + HARVESTED
T.truthy((storageStock["Base.Cabbage"] or 0) >= 5, "Abstract farming deposits harvest into ColonyStorage")

T.finish("pnc_farming_work_adapter_smoke")
