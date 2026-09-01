if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.ColonyStorageService
local Internal = Service.Internal
local CoreInventory = Internal.CoreInventory
local C = Internal.Constants

local function supplyInventory()
    return PNC.SupplyInventory
end

local function requirementsRegistry()
    if PNC.JobRequirements then return PNC.JobRequirements end
    local ok, registry = pcall(require, "PNC/Core/Jobs/PNC_JobRequirements")
    return ok and registry or nil
end

local function normalizeCreatedItem(item)
    if type(item) == "table" and not item.getFullType then
        return item[1]
    end
    return item
end

local function makeItem(fullType)
    if not PNC.Equipment or type(PNC.Equipment.CreateItem) ~= "function" then
        return nil
    end
    local ok, item = pcall(PNC.Equipment.CreateItem, fullType)
    if not ok then return nil end
    return normalizeCreatedItem(item)
end

local function resolveNpc(player, args)
    local npcId = tostring(args and (args.npcId or args.npcID) or "")
    if npcId == "" then return nil, "npc_required" end
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcId) or nil
    if not record then return nil, "npc_not_found" end
    local ownsNPC = PNC.CompanionCommands
        and PNC.CompanionCommands.IsOwnedByPlayer
        and PNC.CompanionCommands.IsOwnedByPlayer(record, player) == true
    if not ownsNPC and not Internal.DebugAllowed(player) then
        return nil, "npc_not_owned"
    end
    return record
end

local function requirementProducts(definition)
    local products = {}
    for index = 1, #(definition.requirements or {}) do
        local requirement = definition.requirements[index]
        local candidates = requirement and requirement.candidates or {}
        local selected
        for candidateIndex = 1, #candidates do
            local fullType = tostring(candidates[candidateIndex] or "")
            if fullType ~= "" and makeItem(fullType) then
                selected = fullType
                break
            end
        end
        if not selected then
            return nil, "item_type_unknown", {
                role = requirement and requirement.role,
            }
        end
        products[#products + 1] = {
            fullType = selected,
            quantity = math.max(1, math.floor(
                tonumber(requirement.quantity) or 1)),
            candidates = candidates,
            equipSlot = requirement.equipSlot,
            role = requirement.role,
            durable = requirement.durable == true,
            validator = requirement.validator,
        }
    end
    return products
end

local function lumberToolDiagnostic(record, body)
    local lumber = PNC.LumberService
    if not lumber or type(lumber.GetToolDiagnostic) ~= "function" then
        return nil
    end
    local ok, diagnostic = pcall(lumber.GetToolDiagnostic, record, body)
    return ok and diagnostic or nil
end

local function canonicalRequirementSatisfied(record, product)
    if product.durable ~= true then return false end
    local inventory = record and record.inventory
    local items = inventory and inventory.items or nil
    if type(items) ~= "table" then return false end
    for _, item in pairs(items) do
        local itemType = tostring(item and item.type or "")
        for index = 1, #(product.candidates or {}) do
            if itemType == tostring(product.candidates[index])
                and (tonumber(item.stack) or 1) >= product.quantity
            then
                if not product.equipSlot
                    or item.equipSlot == product.equipSlot
                    or inventory.equipped
                        and inventory.equipped[product.equipSlot] == item.id
                then
                    return true
                end
            end
        end
    end
    return false
end

local function alreadySatisfied(record, operation, products)
    local body = PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    if operation == "LUMBER" then
        local diagnostic = lumberToolDiagnostic(record, body)
        if diagnostic and diagnostic.usable == true then
            return true, diagnostic
        end
    end
    local allDurable = true
    local satisfiedDetails = {}
    for index = 1, #products do
        local product = products[index]
        if product.durable ~= true
            or not canonicalRequirementSatisfied(record, product)
        then
            allDurable = false
            break
        end
        satisfiedDetails[#satisfiedDetails + 1] = {
            role = product.role, fullType = product.fullType,
        }
    end
    if allDurable and #products > 0 then
        return true, { source = "canonical_inventory", products = satisfiedDetails }
    end
    return false, nil
end

local function findStorageRecord(storage, typeID)
    local records = storage and storage.inventory
        and storage.inventory.records or {}
    for index = #records, 1, -1 do
        local record = records[index]
        if record[C.TYPE_ID] == typeID
            and (tonumber(record[C.QUANTITY]) or 0) > 0
        then
            return index, record
        end
    end
    return nil, nil
end

local function restoreInventory(storage, backup)
    if not backup or not CoreInventory.Serializer
        or type(CoreInventory.Serializer.deserialize) ~= "function"
    then
        return false
    end
    local ok, inventory = pcall(
        CoreInventory.Serializer.deserialize, backup)
    if not ok or not inventory then return false end
    storage.inventory = inventory
    return true
end

local function clearLumberWaiting(record)
    local runtime = record and record.runtime
    local lumber = runtime and runtime.lumber
    if lumber then
        lumber.waitingReason = nil
        lumber.waitingFor = nil
        lumber.tool = nil
    end
end

local function applyEquipment(record, itemID, body, physicalItem)
    if not itemID or not PNC.Inventory
        or type(PNC.Inventory.EquipPrimary) ~= "function"
    then
        return false, "item_id_missing"
    end
    local equipped, reason = PNC.Inventory.EquipPrimary(
        record, itemID, "debug_job_requirements")
    if not equipped then return false, reason or "equip_failed" end
    if body and physicalItem
        and PNC.Equipment and PNC.Equipment.Internal
        and type(PNC.Equipment.Internal.isNetworkedGame) == "function"
        and PNC.Equipment.Internal.isNetworkedGame() ~= true
        and type(body.setPrimaryHandItem) == "function"
    then
        local ok, handReason = pcall(
            body.setPrimaryHandItem, body, physicalItem)
        if not ok then return false, "live_primary_equip_failed:" .. tostring(handReason) end
        if type(body.getPrimaryHandItem) == "function" then
            local readOK, current = pcall(body.getPrimaryHandItem, body)
            if not readOK or current ~= physicalItem then
                return false, "live_primary_equip_failed"
            end
        end
    elseif body and PNC.Equipment
        and type(PNC.Equipment.EnsureCombatHands) == "function"
    then
        local callOK, applied, applyReason = pcall(
            PNC.Equipment.EnsureCombatHands, body, record)
        if not callOK or applied == false then
            return false, "live_hands_sync_failed:" .. tostring(applyReason)
        end
    elseif body and PNC.Equipment
        and type(PNC.Equipment.ApplyHands) == "function"
    then
        local callOK, applied, applyReason = pcall(
            PNC.Equipment.ApplyHands, body, record)
        if not callOK or applied == false then
            return false, "live_hands_sync_failed:" .. tostring(applyReason)
        end
    end
    return true, reason or "equipped"
end

local function finish(player, args, ok, reason, storage, details)
    Internal.LogTransaction(player, args, "debug_job_requirements", ok, reason,
        storage, details)
    return ok, reason, storage, details
end

function Service.DebugSupplyJobRequirements(player, args)
    args = type(args) == "table" and args or {}
    if not Internal.DebugAllowed(player) then
        return finish(player, args, false, "debug_required")
    end
    if not Internal.RememberRequest(player, args.requestId) then
        return finish(player, args, false, "duplicate_request")
    end
    local storage, reason = Service.ResolveForPlayer(player, args.storageId)
    if not storage then return finish(player, args, false, reason) end

    local operation = string.upper(tostring(
        args.operation or args.job or ""))
    local registry = requirementsRegistry()
    local definition = registry and registry.Get
        and registry.Get(operation) or nil
    if not definition then
        return finish(player, args, false, "job_requirements_unknown", storage, {
            operation = operation,
        })
    end

    local products, productReason, productDetails = requirementProducts(definition)
    if not products then
        return finish(player, args, false, productReason, storage, productDetails)
    end

    local target = string.lower(tostring(args.target or "worker"))
    if target == "storage" then
        local storageRequestId = args.requestId
            and tostring(args.requestId) .. ":storage" or nil
        local addArgs = {
            storageId = args.storageId,
            debugAction = "add_many",
            products = products,
            requestId = storageRequestId,
            transactionLogging = args.transactionLogging,
        }
        local added, addReason, addStorage, details = Service.DebugAction(
            player, addArgs)
        if not added then
            return finish(player, args, false, addReason, addStorage, details)
        end
        return finish(player, args, true, "job_requirements_added",
            addStorage, {
                operation = operation, target = target, products = products,
            })
    end

    local record, npcReason = resolveNpc(player, args)
    if not record then return finish(player, args, false, npcReason, storage) end
    local satisfied, diagnostic = alreadySatisfied(record, operation, products)
    if satisfied then
        return finish(player, args, true, "already_satisfied", storage, {
            operation = operation, target = "worker", npcId = record.id,
            tool = diagnostic,
        })
    end

    local backup = CoreInventory.Serializer
        and CoreInventory.Serializer.serialize
        and CoreInventory.Serializer.serialize(storage.inventory) or nil
    local inventoryBackup = PNC.Core.DeepCopy(
        PNC.Inventory.EnsureRecordInventory(record))
    local body = PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    local destinations = {}
    local granted = {}
    local selected = {}

    local encoded = {}
    for index = 1, #products do
        local product = products[index]
        local item = makeItem(product.fullType)
        local recordValue, encodeReason = CoreInventory.encodeItem(
            item, product.quantity)
        if not recordValue then
            return finish(player, args, false,
                encodeReason or "item_encode_failed", storage, {
                    operation = operation, fullType = product.fullType,
                })
        end
        encoded[#encoded + 1] = recordValue
    end

    local allowed, preflightReason, preflightDetails = Internal.Preflight(
        storage, encoded)
    if not allowed then
        return finish(player, args, false, preflightReason, storage,
            preflightDetails)
    end
    for index = 1, #encoded do
        local deposited, depositReason = CoreInventory.deposit(
            storage.inventory, encoded[index])
        if not deposited then
            restoreInventory(storage, backup)
            return finish(player, args, false,
                depositReason or "storage_add_failed", storage)
        end
    end

    local function rollback()
        for destinationIndex = #destinations, 1, -1 do
            destinations[destinationIndex]:remove()
        end
        PNC.Inventory.EnsureRecordInventory(record)
        record.inventory = inventoryBackup
        if PNC.Inventory.RebuildCaches then
            PNC.Inventory.RebuildCaches(record)
        end
        restoreInventory(storage, backup)
    end

    for index = 1, #products do
        local product = products[index]
        local typeID = encoded[index][C.TYPE_ID]
        local recordIndex, storageRecord = findStorageRecord(storage, typeID)
        if not recordIndex or not storageRecord then
            rollback()
            return finish(player, args, false, "storage_item_missing", storage)
        end
        local source, sourceReason = Internal.StorageSelectionSource(storage, {
            { recordIndex = recordIndex, quantity = product.quantity },
        }, "debug:" .. tostring(args.requestId or record.id))
        if not source then
            rollback()
            return finish(player, args, false, sourceReason, storage)
        end
        local inventoryAdapter = supplyInventory()
        if not inventoryAdapter
            or type(inventoryAdapter.CreateDestination) ~= "function"
        then
            rollback()
            return finish(player, args, false,
                "supply_inventory_unavailable", storage)
        end
        local destination = inventoryAdapter.CreateDestination(record,
            "debug_job_requirements")
        local transferred, transferReason = CoreInventory.transfer(
            source, destination, nil, product.quantity)
        if not transferred then
            source:release()
            rollback()
            return finish(player, args, false,
                transferReason or "npc_transfer_failed", storage)
        end
        if body and destination.physicalProjectionMissing == true then
            rollback()
            return finish(player, args, false,
                "npc_physical_inventory_failed", storage, {
                    operation = operation, target = "worker",
                    npcId = record.id, fullType = product.fullType,
                })
        end
        destinations[#destinations + 1] = destination
        local itemID = destination.itemIDs and destination.itemIDs[1] or nil
        local physicalItem = destination.physicalItems
            and destination.physicalItems[1] or nil
        if product.equipSlot == "primary" then
            local equipped, equipReason = applyEquipment(
                record, itemID, body, physicalItem)
            if not equipped then
                rollback()
                return finish(player, args, false, equipReason, storage)
            end
            selected[#selected + 1] = {
                role = product.role, itemID = itemID,
                fullType = product.fullType,
            }
        end
        granted[#granted + 1] = {
            role = product.role, fullType = product.fullType,
            quantity = product.quantity, itemID = itemID,
        }
    end

    local activity = {}
    for index = 1, #granted do
        local item = granted[index]
        activity[#activity + 1] = {
            fullType = item.fullType, quantity = item.quantity,
        }
    end
    Internal.RecordActivity(storage, "TAKE",
        tostring(record.name or record.id), activity,
        "debug_job_requirements")
    Internal.CommitStorage(storage)
    clearLumberWaiting(record)
    if PNC.Registry and type(PNC.Registry.MarkDirty) == "function" then
        pcall(PNC.Registry.MarkDirty, record, "debug_job_requirements")
    end
    Service.Metrics.withdrawals = Service.Metrics.withdrawals + 1
    return finish(player, args, true, "job_requirements_granted", storage, {
        operation = operation, target = "worker", npcId = record.id,
        products = granted, equipped = selected,
    })
end

return Service
