local T = require "tests/support/test"

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, child in pairs(value) do output[key] = copy(child) end
    return output
end

local storage = {
    id = "storage:debug", tier = 1, revision = 4,
    inventory = { records = {}, revision = 2 },
}
local worker = {
    id = "worker:debug", name = "Debug Worker", alive = true,
    inventory = { items = {}, equipped = {}, revision = 1 },
    equipment = {}, runtime = {},
}
local transferCount = 0
local commitCount = 0
local activityCount = 0
local dirtyCount = 0
local equippedHands = 0
local requestIDs = {}
local livePrimary
local livePhysicalItem = {
    type = "Base.Axe",
    getFullType = function(item) return item.type end,
}
local liveBody = {
    id = worker.id,
    setPrimaryHandItem = function(_, item) livePrimary = item end,
    getPrimaryHandItem = function() return livePrimary end,
}

local function inventoryCopy(value)
    return copy(value)
end

local CoreInventory = {
    Serializer = {
        serialize = function(value) return inventoryCopy(value) end,
        deserialize = function(value) return inventoryCopy(value) end,
    },
    encodeItem = function(_, quantity)
        return { typeId = 44, quantity = quantity or 1 }
    end,
    deposit = function(inventory, value)
        inventory.records[#inventory.records + 1] = copy(value)
        return true, "deposited"
    end,
    transfer = function(source, destination, _, quantity)
        transferCount = transferCount + 1
        local ok, removed = source:remove(nil, quantity)
        if not ok then return false, removed end
        for index = 1, #removed do
            local added, reason = destination:add(removed[index])
            if not added then
                source:restoreRemoved(removed)
                return false, reason
            end
        end
        return true, removed
    end,
}

local Service = {
    Internal = {
        Constants = { TYPE_ID = "typeId", QUANTITY = "quantity" },
        CoreInventory = CoreInventory,
        DebugAllowed = function() return true end,
        RememberRequest = function(_, requestID)
            requestID = tostring(requestID or "")
            if requestID == "" or requestIDs[requestID] then return false end
            requestIDs[requestID] = true
            return true
        end,
        Preflight = function() return true end,
        StorageSelectionSource = function(currentStorage, selections)
            local selection = selections[1]
            local selected = currentStorage.inventory.records[
                selection.recordIndex]
            local source = { quantity = selection.quantity }
            function source:remove(_, quantity)
                if quantity ~= self.quantity then return false, "quantity_mismatch" end
                for index = #currentStorage.inventory.records, 1, -1 do
                    if currentStorage.inventory.records[index] == selected then
                        table.remove(currentStorage.inventory.records, index)
                        break
                    end
                end
                return true, { selected }
            end
            function source:restoreRemoved(records)
                for index = 1, #records do
                    currentStorage.inventory.records[#currentStorage.inventory.records + 1] = records[index]
                end
                return true
            end
            function source:release() end
            return source
        end,
        RecordActivity = function() activityCount = activityCount + 1 end,
        CommitStorage = function() commitCount = commitCount + 1 end,
        LogTransaction = function() end,
    },
    Metrics = { withdrawals = 0 },
    ResolveForPlayer = function() return storage end,
    DebugAction = function(_, args)
        return true, "added", storage, { products = args.products }
    end,
}
PNC = {
    ColonyStorageService = Service,
    JobRequirements = {
        Get = function(operation)
            return operation == "LUMBER" and {
                requirements = {
                    { role = "primary_tool", candidates = { "Base.Axe" },
                        quantity = 1, durable = true, equipSlot = "primary",
                        validator = "lumber_tool" },
                },
            } or nil
        end,
    },
    Equipment = {
        CreateItem = function(fullType)
            return {
                type = fullType,
                getFullType = function(item) return item.type end,
            }
        end,
        ApplyHands = function() equippedHands = equippedHands + 1 end,
        Internal = {
            isNetworkedGame = function() return false end,
        },
    },
    SupplyInventory = {
        CreateDestination = function(record)
            local destination = {
                itemIDs = {}, physicalItems = { livePhysicalItem },
            }
            function destination:add()
                local itemID = "worker-item:1"
                record.inventory.items[itemID] = {
                    id = itemID, type = "Base.Axe", stack = 1,
                }
                self.itemIDs[#self.itemIDs + 1] = itemID
                return true, { itemIDs = { itemID } }
            end
            function destination:remove() return true end
            return destination
        end,
    },
    Inventory = {
        EnsureRecordInventory = function(record) return record.inventory end,
        EquipPrimary = function(record, itemID)
            record.inventory.equipped.primary = itemID
            record.equipment.primaryFullType = "Base.Axe"
            return true, "equipped_primary"
        end,
        RebuildCaches = function() end,
    },
    Registry = {
        Get = function(id) return tostring(id) == worker.id and worker or nil end,
        GetLiveZombie = function(id)
            return tostring(id) == worker.id and liveBody or nil
        end,
        MarkDirty = function() dirtyCount = dirtyCount + 1 end,
    },
    LumberService = {
        GetToolDiagnostic = function() return {
            usable = false, reason = "lumber_tool_missing",
        } end,
    },
    Core = { DeepCopy = copy },
}

local Loaded = T.load("ProjectHoomans", "server",
    "PNC/Colony/Storage/ColonyStorageService/PNC_ColonyStorageService_JobRequirements.lua")
T.truthy(Loaded.DebugSupplyJobRequirements,
    "job requirement debug API is registered")

local ok, reason, resultStorage, details =
    Loaded.DebugSupplyJobRequirements({ id = "admin" }, {
        storageId = storage.id, operation = "LUMBER", target = "worker",
        npcId = worker.id, requestId = "job-debug-1",
    })
T.truthy(ok, reason or "lumber requirement grant")
T.equal(reason, "job_requirements_granted", "grant outcome")
T.equal(resultStorage, storage, "grant returns the changed storage")
T.equal(details.products[1].fullType, "Base.Axe", "granted axe type")
T.equal(worker.equipment.primaryFullType, "Base.Axe",
    "granted axe is equipped in the canonical record")
T.equal(livePrimary, livePhysicalItem,
    "granted axe is the physical item placed in the live worker inventory")
T.equal(transferCount, 1, "grant uses one storage transfer")
T.equal(commitCount, 1, "grant commits storage once")
T.equal(activityCount, 1, "grant records storage activity")
T.equal(dirtyCount, 1, "grant marks the NPC dirty")
T.equal(equippedHands, 0,
    "physical live grant does not create a duplicate hand item")

local stored, storedReason, _, storedDetails =
    Loaded.DebugSupplyJobRequirements({ id = "admin" }, {
        storageId = storage.id, operation = "LUMBER", target = "storage",
        requestId = "job-debug-storage-1",
    })
T.truthy(stored, storedReason or "storage-only requirement grant")
T.equal(storedReason, "job_requirements_added",
    "storage-only requirement outcome")
T.equal(storedDetails.target, "storage",
    "storage-only requirement target is preserved")

local duplicate, duplicateReason = Loaded.DebugSupplyJobRequirements(
    { id = "admin" }, {
        storageId = storage.id, operation = "LUMBER", target = "worker",
        npcId = worker.id, requestId = "job-debug-1",
    })
T.falsy(duplicate, "duplicate requirement request rejected")
T.equal(duplicateReason, "duplicate_request",
    "duplicate requirement request reason")

T.finish("pnc_storage_job_requirements_smoke")
