-- Live and abstract lumber execution state machines.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.LumberService
local Internal = Service.Internal
local now = Internal.Now
local markDirty = Internal.MarkDirty
local updateRuntime = Internal.UpdateRuntime
local guideToZone = Internal.GuideToZone
local ensureTreeClaim = Internal.EnsureTreeClaim
local selectClaimedTarget = Internal.SelectClaimedTarget
local treeSignature = Internal.TreeSignature
local expireClaims = Internal.ExpireClaims
local resolveAbstractTool = Internal.ResolveAbstractTool
local resolveLiveTool = Internal.ResolveLiveTool
local toolDiagnostic = Internal.ToolDiagnostic
local toolFullType = Internal.ToolFullType
local persistLiveToolCondition = Internal.PersistLiveToolCondition
local skillRate = Internal.SkillRate
local WorldEffects = PNC.WorldEffectService

local function adjacentToTree(body, tree)
    if not body or not tree then return false end
    local x = type(body.getX) == "function" and body:getX() or nil
    local y = type(body.getY) == "function" and body:getY() or nil
    local z = type(body.getZ) == "function" and body:getZ() or nil
    return x and y and z and math.abs(z - tree.z) < 0.6
        and math.abs(x - (tree.x + 0.5)) <= 1.2
        and math.abs(y - (tree.y + 0.5)) <= 1.2
end

local function faceTree(body, tree)
    if body and tree and type(body.faceLocationF) == "function" then
        pcall(body.faceLocationF, body, tree.x + 0.5, tree.y + 0.5)
    end
end

local function beginChopAnimation(record, body)
    if PNC.AnimationScenes and type(PNC.AnimationScenes.Request) == "function"
        and body
    then
        local scene = record.runtime and record.runtime.animationScene
        if not scene or scene.id ~= "lumber.chop" then
            pcall(PNC.AnimationScenes.Request, record, body, "lumber.chop", {
                reason = "lumber_chop", repeatMode = "loop",
            })
        end
    end
    if body and type(body.setVariable) == "function" then
        pcall(body.setVariable, body, "PNCLumbering", true)
    end
end

local function stopChopAnimation(record, body)
    local scene = record and record.runtime and record.runtime.animationScene
    if scene and scene.id == "lumber.chop"
        and PNC.AnimationScenes and PNC.AnimationScenes.Stop
    then pcall(PNC.AnimationScenes.Stop, record, body, "lumber_stopped") end
    if body and type(body.setVariable) == "function" then
        pcall(body.setVariable, body, "PNCLumbering", false)
    end
end

local ensureLumberOutputEffect
local captureOutputItems

local function tickLive(job, record, body, tree, at)
    local actual, square = Service.GetTreeAt(tree.x, tree.y, tree.z)
    if not square then
        -- A missing grid square means the target chunk is unavailable, not
        -- that the tree was removed. Keep the ledger record and claim intact
        -- until the chunk is loaded and the tree can be revalidated.
        job.state, job.phase = "WAITING", "WAITING_FOR_TREE_CHUNK"
        updateRuntime(record, job, tree)
        return true, false, "tree_chunk_loading"
    end
    if not actual then
        tree.status = "INVALID"
        Service.Runtime.claims[tree.key] = nil
        job.targetKey, job.approach = nil, nil
        job.state, job.phase = "READY", "RECONCILING"
        markDirty()
        return true, false, "tree_missing"
    end
    if tree.signature ~= treeSignature(actual) then
        tree.status = "INVALID"
        Service.Runtime.claims[tree.key] = nil
        job.targetKey, job.approach = nil, nil
        job.state, job.phase = "READY", "RECONCILING"
        markDirty()
        return true, false, "tree_replaced"
    end
    local approach = job.approach
    if not approach then
        approach = Service.FindApproach(tree, record)
        job.approach = approach
    end
    if not approach then
        Service.ReleaseTree(tree.key, "no_approach")
        job.targetKey, job.approach = nil, nil
        job.state, job.phase = "READY", "BLOCKED"
        return true, false, "no_approach_point"
    end
    local bx = body and body.getX and body:getX() or record.x
    local by = body and body.getY and body:getY() or record.y
    local bz = body and body.getZ and body:getZ() or record.z
    local distance = math.abs((tonumber(bx) or 0) - approach.x)
        + math.abs((tonumber(by) or 0) - approach.y)
    if distance > 1.0 or math.abs((tonumber(bz) or 0) - approach.z) > 0.6 then
        job.state, job.phase = "TRAVELING", "TRAVEL"
        if PNC.BehaviorCommon and PNC.BehaviorCommon.MoveRecord then
            PNC.BehaviorCommon.MoveRecord(record, body,
                approach.x, approach.y, approach.z, "walk", 0.7, "lumber")
        end
        updateRuntime(record, job, tree)
        return true, false, "traveling"
    end
    if not adjacentToTree(body, tree) then
        job.state, job.phase = "TRAVELING", "TRAVEL"
        if PNC.BehaviorCommon and PNC.BehaviorCommon.MoveRecord then
            PNC.BehaviorCommon.MoveRecord(record, body,
                approach.x, approach.y, approach.z, "walk", 0.7, "lumber")
        end
        updateRuntime(record, job, tree)
        return true, false, "not_adjacent"
    end
    if PNC.BehaviorCommon and PNC.BehaviorCommon.HaltMovement then
        PNC.BehaviorCommon.HaltMovement(record, body, "lumber_chop")
    end
    faceTree(body, tree)
    local tool, toolReason = resolveLiveTool(record, body)
    if not tool then
        job.activityItemFullType = nil
        job.state, job.phase = "WAITING", "WAITING_FOR_TOOL"
        updateRuntime(record, job, tree)
        return true, false, toolReason
    end
    job.activityItemFullType = toolFullType and toolFullType(tool.item) or nil
    if type(body.isEnduranceSufficientForAction) == "function" then
        local ok, enough = pcall(body.isEnduranceSufficientForAction, body)
        if ok and enough == false then
            job.state, job.phase = "WAITING", "WAITING_FOR_ENDURANCE"
            updateRuntime(record, job, tree)
            return true, false, "endurance"
        end
    end
    beginChopAnimation(record, body)
    job.state, job.phase = "WORKING", "CHOPPING"
    local lastHit = tonumber(job.lastHitAt) or 0
    local beforeWorldObjects
    if at - lastHit >= Service.HIT_INTERVAL_MS then
        beforeWorldObjects = captureOutputItems
            and captureOutputItems(square, nil, nil, true) or nil
        local ok, result = pcall(actual.WeaponHit, actual, body, tool.item)
        if not ok then
            stopChopAnimation(record, body)
            job.state, job.phase = "FAILED", "FAILED"
            return false, false, tostring(result)
        end
        persistLiveToolCondition(record, tool.item)
        job.lastHitAt = at
        job.lastProgressAt = at
        if type(actual.getHealth) == "function" then
            local healthOK, health = pcall(actual.getHealth, actual)
            if healthOK and tonumber(health) then
                tree.remainingWork = math.max(0, tonumber(health))
            end
        end
        tree.revision = (tonumber(tree.revision) or 0) + 1
        markDirty()
    end
    local stillThere, stillSquare = Service.GetTreeAt(tree.x, tree.y, tree.z)
    if not stillSquare then
        job.state, job.phase = "WAITING", "WAITING_FOR_TREE_CHUNK"
        updateRuntime(record, job, tree)
        return true, false, "tree_chunk_loading_after_hit"
    end
    if not stillThere or tonumber(tree.remainingWork) <= 0 then
        job.activityItemFullType = nil
        stopChopAnimation(record, body)
        local outputEffect = ensureLumberOutputEffect(tree, "LIVE", nil,
            "ON_GROUND",
            "VANILLA_WORLD_OUTPUT_ON_GROUND", record and record.id)
        if outputEffect and captureOutputItems then
            captureOutputItems(square, beforeWorldObjects, outputEffect)
        end
        job.pendingOutput = {
            mode = "LIVE", treeKey = tree.key,
            outputEffectId = outputEffect and outputEffect.id or nil,
        }
        job.outputTreeKey = tree.key
        Service.CompleteTree(tree.key, "live")
        job.targetKey, job.approach, job.lastHitAt = nil, nil, nil
        job.state, job.phase = "TRAVELING", "OUTPUT_APPROACH"
        updateRuntime(record, job, tree)
        return true, false, "tree_depleted_live_output_pending"
    end
    updateRuntime(record, job, tree)
    return true, false, "chopping"
end

local function updateAbstractToolWear(record, job, tool)
    if not tool.itemID or not tool.condition then return end
    job.toolHitCount = (tonumber(job.toolHitCount) or 0) + 1
    if job.toolHitCount < Service.ABSTRACT_TOOL_HITS_PER_CONDITION then return end
    job.toolHitCount = 0
    if PNC.Inventory and type(PNC.Inventory.ApplyDelta) == "function" then
        local condition = math.max(0, tool.condition - 1)
        pcall(PNC.Inventory.ApplyDelta, record, {
            { op = "update", itemID = tool.itemID, cond = condition },
        }, "lumber_tool_wear")
    end
end

local function outputEffectFor(output)
    if type(output) ~= "table" or not output.treeKey then return nil end
    local tree = Service.GetTree(output.treeKey)
    return tree and tree.outputEffect or nil
end

local function setOutputEffectState(effect, state, reason)
    if type(effect) ~= "table" then return end
    local at = now()
    effect.state = tostring(state or "PENDING")
    effect.updatedAt = at
    effect.lastReason = reason
    effect.waitReason = effect.state == "APPLIED" and nil or reason
    effect.phase = effect.state == "APPLIED" and "DELIVERED"
        or effect.phase or "OUTPUT_PENDING"
    if effect.state == "APPLIED" then effect.pickupState = "DELIVERED" end
    if effect.state == "APPLIED" then effect.appliedAt = at end
    markDirty()
end

ensureLumberOutputEffect = function(tree, mode, items, phase, reason,
    workerID)
    if type(tree) ~= "table" then return nil end
    if type(tree.outputEffect) == "table" then
        return tree.outputEffect
    end
    local createdAt = now()
    local effectID = PNC.Core and PNC.Core.GenerateID
        and PNC.Core.GenerateID("lumber_output")
        or "lumber_output:" .. tostring(tree.key)
    local sourceMode = tostring(mode or "ABSTRACT")
    local storedItems = type(items) == "table" and items or {}
    local itemCount, actualQuantity = 0, 0
    for _, item in ipairs(storedItems) do
        if type(item) == "table" then
            itemCount = itemCount + 1
            actualQuantity = actualQuantity + math.max(1,
                math.floor(tonumber(item.quantity or item.stack) or 1))
        end
    end
    local effect = {
        id = tostring(effectID), kind = "LUMBER_OUTPUT",
        operation = "LUMBER_OUTPUT", state = "PENDING",
        phase = tostring(phase or "OUTPUT_PENDING"),
        treeKey = tree.key, x = tree.x, y = tree.y, z = tree.z,
        sourceX = tree.x, sourceY = tree.y, sourceZ = tree.z,
        sourceMode = sourceMode,
        deliveryMode = sourceMode == "LIVE" and "WORLD_FLOOR"
            or "ABSTRACT_INVENTORY",
        pickupState = sourceMode == "LIVE" and "ON_GROUND"
            or "ABSTRACT_PENDING",
        lootSource = sourceMode == "LIVE" and "vanilla_tree_loot"
            or "abstract_log_yield",
        workerID = workerID,
        quantity = tree.logYield,
        expectedLogYield = tree.logYield,
        items = storedItems, itemCount = itemCount,
        totalQuantity = actualQuantity, actualQuantity = actualQuantity,
        createdAt = createdAt, updatedAt = createdAt,
        waitReason = reason, lastReason = reason,
        identity = {
            treeKey = tree.key, sourceMode = sourceMode,
        },
    }
    tree.outputEffect = effect
    markDirty()
    return effect
end

local function call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

local function listSize(list)
    local size = call(list, "size")
    if size ~= nil then return math.max(0, math.floor(tonumber(size) or 0)) end
    return type(list) == "table" and #list or 0
end

local function listItem(list, index)
    local value = call(list, "get", index)
    if value ~= nil then return value end
    return type(list) == "table" and list[index + 1] or nil
end

local function worldObjectsFor(square)
    return square and call(square, "getWorldObjects") or nil
end

local function itemID(item, worldObject)
    return call(item, "getID") or call(worldObject, "getKeyId")
end

local function itemType(item)
    return call(item, "getFullType") or call(item, "getType")
end

local function tagOutputItem(item, worldObject, effectID)
    local data = call(item, "getModData")
    if type(data) == "table" then
        data.PNC_LumberOutputEffectID = tostring(effectID)
    end
    if type(worldObject and worldObject.transmitModData) == "function" then
        pcall(worldObject.transmitModData, worldObject)
    end
end

captureOutputItems = function(square, before, effect, snapshotOnly)
    local objects = worldObjectsFor(square)
    local seen = {}
    local captured = 0
    for index = 0, listSize(objects) - 1 do
        local worldObject = listItem(objects, index)
        if worldObject then
            seen[worldObject] = true
            if not snapshotOnly and effect then
                local item = call(worldObject, "getItem")
                local data = call(item, "getModData")
                local tagged = type(data) == "table"
                    and tostring(data.PNC_LumberOutputEffectID or "")
                        == tostring(effect.id)
                local isNew = (before and before[worldObject] ~= true)
                    or tagged
                if isNew and item then
                    local fullType = itemType(item)
                    if fullType then
                        local id = itemID(item, worldObject)
                        local descriptor = {
                            id = id and tostring(id) or nil,
                            fullType = tostring(fullType), quantity = 1,
                        }
                        local duplicate = false
                        for _, existing in ipairs(effect.items or {}) do
                            if descriptor.id and existing.id
                                and tostring(existing.id)
                                    == tostring(descriptor.id)
                            then
                                duplicate = true
                                break
                            end
                        end
                        if not duplicate then
                            effect.items = effect.items or {}
                            effect.items[#effect.items + 1] = descriptor
                            captured = captured + 1
                            tagOutputItem(item, worldObject, effect.id)
                        end
                    end
                end
            end
        end
    end
    if snapshotOnly then return seen end
    if effect then
        effect.itemCount = #(effect.items or {})
        local quantity = 0
        for _, item in ipairs(effect.items or {}) do
            quantity = quantity + math.max(1,
                math.floor(tonumber(item.quantity or item.stack) or 1))
        end
        effect.totalQuantity = quantity
        effect.actualQuantity = quantity
        effect.updatedAt = now()
        markDirty()
    end
    return captured
end

local function flushAbstractOutput(job, record)
    local output = job.pendingOutput
    if not output then return true end
    local effect = outputEffectFor(output)
    if effect and tostring(effect.state or "") == "APPLIED" then
        job.pendingOutput = nil
        return true
    end
    if PNC.Inventory and type(PNC.Inventory.AddItems) == "function" then
        local ok = PNC.Inventory.AddItems(record, {
            { type = output.fullType, stack = output.quantity },
        }, "root", "lumber_abstract_output")
        if ok then
            setOutputEffectState(effect, "APPLIED",
                "ABSTRACT_INVENTORY_ACCEPTED")
            job.pendingOutput = nil
            return true
        end
    end
    setOutputEffectState(effect, "PENDING", "ABSTRACT_OUTPUT_UNAVAILABLE")
    return false
end

local function oneShotAnimation(record, body, sceneID, reason)
    local runtime = record and record.runtime or nil
    local scene = runtime and runtime.animationScene or nil
    if scene and tostring(scene.id or "") == tostring(sceneID) then
        return "running"
    end
    local last = runtime and runtime.lastAnimationScene or nil
    if last and tostring(last.id or "") == tostring(sceneID)
        and tostring(last.reason or "") == "completed"
    then
        return "completed"
    end
    if not PNC.AnimationScenes
        or type(PNC.AnimationScenes.Request) ~= "function"
    then
        return "failed", "LUMBER_ANIMATION_UNAVAILABLE"
    end
    local ok, result = pcall(PNC.AnimationScenes.Request, record, body,
        sceneID, { reason = reason, repeatMode = "once" })
    if not ok or result == false then
        return "failed", tostring(result or "LUMBER_ANIMATION_FAILED")
    end
    return "started"
end

local function descriptorMatches(item, descriptor, effectID)
    if not descriptor then return false end
    local descriptorID = descriptor.id and tostring(descriptor.id) or nil
    local id = itemID(item)
    local data = call(item, "getModData")
    local tagged = type(data) == "table"
        and tostring(data.PNC_LumberOutputEffectID or "")
            == tostring(effectID or "")
    if descriptorID and id then
        return descriptorID == tostring(id)
    end
    if tagged and descriptor.fullType then
        return tostring(descriptor.fullType) == tostring(itemType(item) or "")
    end
    return tagged
end

local function floorOutputItems(square, effect)
    local output = {}
    local objects = worldObjectsFor(square)
    for index = 0, listSize(objects) - 1 do
        local worldObject = listItem(objects, index)
        local item = worldObject and call(worldObject, "getItem") or nil
        if item then
            for _, descriptor in ipairs(effect and effect.items or {}) do
                if not descriptor.collected and not descriptor.delivered
                    and descriptorMatches(item, descriptor, effect.id)
                then
                    output[#output + 1] = {
                        object = worldObject, item = item,
                        descriptor = descriptor,
                    }
                    break
                end
            end
        end
    end
    return output
end

local function nativeInventoryItems(body)
    local inventory = call(body, "getInventory")
    local items = call(inventory, "getItems")
    local output = {}
    for index = 0, listSize(items) - 1 do
        local item = listItem(items, index)
        if item then output[#output + 1] = item end
    end
    return output
end

local function bodyHasOutputItem(body, descriptor, effectID)
    for _, item in ipairs(nativeInventoryItems(body)) do
        if descriptorMatches(item, descriptor, effectID) then return true end
    end
    return false
end

local function removeWorldObject(square, worldObject)
    if type(square and square.removeWorldObject) == "function" then
        local ok = pcall(square.removeWorldObject, square, worldObject)
        return ok
    end
    local removed = true
    if type(worldObject and worldObject.removeFromWorld) == "function" then
        removed = pcall(worldObject.removeFromWorld, worldObject)
    end
    if type(worldObject and worldObject.removeFromSquare) == "function" then
        removed = pcall(worldObject.removeFromSquare, worldObject)
    end
    return removed
end

local function restoreWorldObject(square, item)
    if not square or not item
        or type(square.AddWorldInventoryItem) ~= "function"
    then return false end
    local ok, restored = pcall(square.AddWorldInventoryItem, square, item,
        0.0, 0.0, 0.0)
    return ok and restored ~= nil
end

local function pickupWorldItem(square, worldObject, item, body)
    local inventory = call(body, "getInventory")
    if not inventory then return false, "NPC_INVENTORY_UNAVAILABLE" end
    if type(inventory.canAddItem) == "function" then
        local canAdd = call(inventory, "canAddItem", item)
        if canAdd == false then return false, "NPC_INVENTORY_FULL" end
    end
    if not removeWorldObject(square, worldObject) then
        return false, "LUMBER_FLOOR_REMOVE_FAILED"
    end
    local added = call(inventory, "AddItem", item)
    if not added then
        restoreWorldObject(square, item)
        return false, "NPC_INVENTORY_ADD_FAILED"
    end
    return true
end

local function pickupOutputItems(job, record, body, effect, square)
    local descriptors = effect and effect.items or {}
    if #descriptors < 1 then
        effect.waitReason = "LUMBER_OUTPUT_ITEMS_NOT_CAPTURED"
        effect.lastReason = effect.waitReason
        effect.updatedAt = now()
        markDirty()
        return false, effect.waitReason
    end
    local floorItems = floorOutputItems(square, effect)
    local floorByDescriptor = {}
    for _, found in ipairs(floorItems) do
        floorByDescriptor[found.descriptor] = found
    end
    for _, descriptor in ipairs(descriptors) do
        if not descriptor.collected and not descriptor.delivered then
            local found = floorByDescriptor[descriptor]
            local collected = bodyHasOutputItem(body, descriptor, effect.id)
            if collected then
                descriptor.collected = true
            elseif found then
                local ok, reason = pickupWorldItem(square, found.object,
                    found.item, body)
                if not ok then return false, reason end
                descriptor.collected = true
            else
                effect.waitReason = "LUMBER_OUTPUT_ITEM_MISSING"
                effect.lastReason = effect.waitReason
                effect.updatedAt = now()
                markDirty()
                return false, effect.waitReason
            end
        end
    end
    if PNC.Inventory and PNC.Inventory.CaptureLooseInventory then
        local ok, reason = PNC.Inventory.CaptureLooseInventory(record, body)
        if ok == false then return false, reason or "NPC_INVENTORY_CAPTURE_FAILED" end
    end
    effect.phase = "CARRYING"
    effect.pickupState = "NPC_INVENTORY"
    effect.waitReason = nil
    effect.lastReason = "LUMBER_OUTPUT_PICKED_UP"
    effect.updatedAt = now()
    markDirty()
    job.state, job.phase = "TRAVELING", "OUTPUT_DESTINATION_APPROACH"
    return true
end

local function outputBase(record, job)
    local base
    if PNC.HomeDutyService and PNC.HomeDutyService.GetBase then
        base = PNC.HomeDutyService.GetBase(record, job and job.baseId)
    end
    if not base and PNC.BaseService then
        if job and job.baseId and PNC.BaseService.Get then
            base = PNC.BaseService.Get(job.baseId)
        end
        if not base and PNC.BaseService.GetForColony
            and record and record.affiliation
        then
            base = PNC.BaseService.GetForColony(
                record.affiliation.communityID or record.affiliation.communityId)
        end
    end
    return base
end

local function resolveOutputDestination(record, job, effect)
    if type(job.outputDestination) == "table" then
        local destination = job.outputDestination
        effect.destinationX = destination.x
        effect.destinationY = destination.y
        effect.destinationZ = destination.z
        effect.destinationNodeId = destination.nodeId
        effect.destinationStorageId = destination.storageId
        return job.outputDestination
    end
    local base = outputBase(record, job)
    if not base then return nil, "LUMBER_BASE_NOT_FOUND" end
    local nodeService = PNC.StockpileAccessService
    if not nodeService or type(nodeService.FindNearest) ~= "function" then
        return nil, "LUMBER_STOCKPILE_ACCESS_UNAVAILABLE"
    end
    local node = nodeService.FindNearest(base.id, effect.x, effect.y, effect.z,
        { requireLoaded = tostring(effect.sourceMode or "") == "LIVE" })
    if not node then return nil, "LUMBER_STOCKPILE_NOT_FOUND" end
    local storageID = node.storageId
    local storage
    local repository = PNC.ColonyStorageRepository
    if storageID and repository and repository.Get then
        storage = repository.Get(storageID)
    end
    if not storage and repository and repository.GetPrimary then
        storage = repository.GetPrimary(base.factionId, base.settlementId)
        storageID = storage and storage.id or storageID
    end
    if not storage then return nil, "LUMBER_STORAGE_NOT_FOUND" end
    job.baseId = base.id
    job.outputDestination = {
        nodeId = node.id, storageId = storageID,
        x = node.x, y = node.y, z = node.z,
    }
    effect.destinationX = node.x
    effect.destinationY = node.y
    effect.destinationZ = node.z
    effect.destinationNodeId = node.id
    effect.destinationStorageId = storageID
    markDirty()
    return job.outputDestination
end

local function compactItemsForType(record, fullType)
    local inventory = PNC.Inventory and PNC.Inventory.EnsureRecordInventory
        and PNC.Inventory.EnsureRecordInventory(record) or record.inventory
    local output = {}
    for _, item in pairs(inventory and inventory.items or {}) do
        if tostring(item.type or "") == tostring(fullType or "") then
            output[#output + 1] = item
        end
    end
    table.sort(output, function(left, right)
        return tostring(left.id or "") < tostring(right.id or "")
    end)
    return output
end

local function depositOutputItems(record, body, storage, effect)
    local storageInternal = PNC.ColonyStorageService
        and PNC.ColonyStorageService.Internal or nil
    if not storageInternal
        or type(storageInternal.LiveNPCSource) ~= "function"
        or type(storageInternal.TransferIntoStorage) ~= "function"
    then
        return false, "LUMBER_STORAGE_TRANSFER_UNAVAILABLE"
    end
    local pendingByType = {}
    for _, descriptor in ipairs(effect.items or {}) do
        if descriptor.collected and not descriptor.delivered then
            local fullType = tostring(descriptor.fullType or "")
            pendingByType[fullType] = pendingByType[fullType] or {}
            pendingByType[fullType][#pendingByType[fullType] + 1] = descriptor
        end
    end
    for fullType, descriptors in pairs(pendingByType) do
        local remaining = #descriptors
        for _, item in ipairs(compactItemsForType(record, fullType)) do
            if remaining <= 0 then break end
            local available = math.max(0, math.floor(tonumber(item.stack) or 0))
            local quantity = math.min(available, remaining)
            if quantity > 0 then
                local source, sourceReason = storageInternal.LiveNPCSource(
                    record, item, quantity, body)
                if not source then return false, sourceReason end
                local ok, reason = storageInternal.TransferIntoStorage(
                    storage, source, quantity)
                if not ok then return false, reason end
                local delivered = quantity
                for _, descriptor in ipairs(descriptors) do
                    if delivered <= 0 then break end
                    if not descriptor.delivered then
                        descriptor.delivered = true
                        delivered = delivered - 1
                    end
                end
                remaining = remaining - quantity
            end
        end
        if remaining > 0 then return false, "LUMBER_OUTPUT_NOT_IN_INVENTORY" end
    end
    local activity = {}
    for _, descriptor in ipairs(effect.items or {}) do
        activity[#activity + 1] = {
            fullType = descriptor.fullType, quantity = descriptor.quantity or 1,
        }
    end
    if storageInternal.RecordActivity then
        storageInternal.RecordActivity(storage, "STORE",
            tostring(record.name or record.id), activity, "lumber")
    end
    setOutputEffectState(effect, "APPLIED", "LUMBER_OUTPUT_STORED")
    effect.phase, effect.pickupState = "DELIVERED", "STOCKPILE"
    return true
end

local function tickLiveOutput(job, record, body, at)
    local output = job.pendingOutput
    local tree = output and Service.GetTree(output.treeKey) or nil
    local effect = tree and tree.outputEffect or nil
    if not effect then
        job.state, job.phase = "FAILED", "FAILED"
        return false, false, "LUMBER_OUTPUT_EFFECT_MISSING"
    end
    if tostring(effect.state or "") == "APPLIED" then
        job.pendingOutput, job.outputTreeKey = nil, nil
        job.state, job.phase = "READY", "RECONCILING"
        updateRuntime(record, job, nil)
        return true, true, "lumber_output_already_delivered"
    end
    if job.phase == "WAITING_FOR_WORKER" then
        job.state = "TRAVELING"
        job.phase = effect.pickupState == "NPC_INVENTORY"
            and "OUTPUT_DESTINATION_APPROACH" or "OUTPUT_APPROACH"
    end
    if effect.waitReason == "LUMBER_LIVE_WORKER_REQUIRED" then
        effect.waitReason = nil
        effect.lastReason = "LUMBER_OUTPUT_RESUMED"
        effect.updatedAt = at
        markDirty()
    end
    local square = Service.GetSquare(effect.x, effect.y, effect.z)
    if not square then
        job.state, job.phase = "WAITING", "WAITING_FOR_TREE_CHUNK"
        effect.waitReason, effect.lastReason = "TREE_CHUNK_LOADING",
            "TREE_CHUNK_LOADING"
        effect.updatedAt = at
        updateRuntime(record, job, tree)
        markDirty()
        return true, false, "tree_chunk_loading_for_output"
    end
    if job.phase == "OUTPUT_APPROACH" then
        local bx = body and body.getX and body:getX() or record.x
        local by = body and body.getY and body:getY() or record.y
        local distance = math.abs((tonumber(bx) or 0) - (effect.x + 0.5))
            + math.abs((tonumber(by) or 0) - (effect.y + 0.5))
        if distance > 1.5 then
            if PNC.BehaviorCommon and PNC.BehaviorCommon.MoveRecord then
                PNC.BehaviorCommon.MoveRecord(record, body, effect.x + 0.5,
                    effect.y + 0.5, effect.z, "walk", 0.7, "lumber_output")
            end
            updateRuntime(record, job, tree)
            return true, false, "traveling_to_lumber_output"
        end
        if PNC.BehaviorCommon and PNC.BehaviorCommon.HaltMovement then
            PNC.BehaviorCommon.HaltMovement(record, body, "lumber_grab")
        end
        job.state, job.phase = "WORKING", "GRAB_PENDING"
    end
    if job.phase == "GRAB_PENDING" then
        local status, reason = oneShotAnimation(record, body, "lumber.grab",
            "lumber_output_grab")
        if status == "failed" then
            job.state = "WAITING"
            effect.waitReason, effect.lastReason = reason, reason
            effect.updatedAt = at
            updateRuntime(record, job, tree)
            markDirty()
            return true, false, reason
        end
        if status ~= "completed" then
            updateRuntime(record, job, tree)
            return true, false, "grabbing_lumber_output"
        end
        local picked, pickupReason = pickupOutputItems(job, record, body,
            effect, square)
        if not picked then
            effect.phase = "GRAB_PENDING"
            updateRuntime(record, job, tree)
            return true, false, pickupReason
        end
    end
    if job.phase == "WAITING_FOR_STOCKPILE"
        or job.phase == "OUTPUT_DESTINATION_APPROACH"
    then
        local destination, destinationReason = resolveOutputDestination(record,
            job, effect)
        if not destination then
            job.state, job.phase = "WAITING", "WAITING_FOR_STOCKPILE"
            effect.waitReason, effect.lastReason = destinationReason,
                destinationReason
            effect.updatedAt = at
            updateRuntime(record, job, tree)
            markDirty()
            return true, false, destinationReason
        end
        local bx = body and body.getX and body:getX() or record.x
        local by = body and body.getY and body:getY() or record.y
        local distance = math.abs((tonumber(bx) or 0) - destination.x)
            + math.abs((tonumber(by) or 0) - destination.y)
        if distance > 0.8 then
            job.state, job.phase = "TRAVELING",
                "OUTPUT_DESTINATION_APPROACH"
            if PNC.BehaviorCommon and PNC.BehaviorCommon.MoveRecord then
                PNC.BehaviorCommon.MoveRecord(record, body, destination.x,
                    destination.y, destination.z, "walk", 0.7,
                    "lumber_stockpile")
            end
            updateRuntime(record, job, tree)
            return true, false, "traveling_to_lumber_stockpile"
        end
        if PNC.BehaviorCommon and PNC.BehaviorCommon.HaltMovement then
            PNC.BehaviorCommon.HaltMovement(record, body, "lumber_deposit")
        end
        job.state, job.phase = "WORKING", "DEPOSIT_PENDING"
    end
    if job.phase == "DEPOSIT_PENDING" then
        local status, reason = oneShotAnimation(record, body, "lumber.deposit",
            "lumber_output_deposit")
        if status == "failed" then
            job.state = "WAITING"
            effect.waitReason, effect.lastReason = reason, reason
            effect.updatedAt = at
            updateRuntime(record, job, tree)
            markDirty()
            return true, false, reason
        end
        if status ~= "completed" then
            updateRuntime(record, job, tree)
            return true, false, "depositing_lumber_output"
        end
        local destination, destinationReason = resolveOutputDestination(record,
            job, effect)
        if not destination then
            job.state, job.phase = "WAITING", "WAITING_FOR_STOCKPILE"
            updateRuntime(record, job, tree)
            return true, false, destinationReason
        end
        local storage = PNC.ColonyStorageRepository
            and PNC.ColonyStorageRepository.Get
            and PNC.ColonyStorageRepository.Get(destination.storageId) or nil
        if not storage then
            job.outputDestination = nil
            job.state, job.phase = "WAITING", "WAITING_FOR_STOCKPILE"
            updateRuntime(record, job, tree)
            return true, false, "LUMBER_STORAGE_NOT_FOUND"
        end
        local deposited, depositReason = depositOutputItems(record, body,
            storage, effect)
        if not deposited then
            effect.waitReason, effect.lastReason = depositReason,
                depositReason
            effect.updatedAt = at
            updateRuntime(record, job, tree)
            markDirty()
            return true, false, depositReason
        end
        job.pendingOutput, job.outputTreeKey = nil, nil
        job.outputDestination = nil
        job.state, job.phase = "READY", "RECONCILING"
        updateRuntime(record, job, nil)
        return true, true, "lumber_output_deposited"
    end
    updateRuntime(record, job, tree)
    return true, false, "lumber_output_pending"
end

local function ensureDeferredTreeEffect(tree)
    if type(tree) ~= "table" then return nil end
    if type(tree.worldEffect) == "table" then return tree.worldEffect end
    local effectID = PNC.Core and PNC.Core.GenerateID
        and PNC.Core.GenerateID("tree_remove")
        or "tree_remove:" .. tostring(tree.key)
    local effect = {
        id = tostring(effectID), kind = "TREE_REMOVE", state = "PENDING",
        treeKey = tree.key, x = tree.x, y = tree.y, z = tree.z,
        signature = tree.signature,
        identity = { treeKey = tree.key, signature = tree.signature },
        createdAt = now(), updatedAt = now(), nextRetryAt = 0,
    }
    tree.worldEffect = effect
    markDirty()
    if WorldEffects and WorldEffects.MarkPending then
        WorldEffects.MarkPending("LUMBER", tree, effect,
            "TREE_CHUNK_LOADING")
    end
    return effect
end

local function tickAbstract(job, record, tree, at)
    local actual, square = Service.GetTreeAt(tree.x, tree.y, tree.z)
    if square then
        if not actual then
            -- A player or another authoritative system may have removed the
            -- tree while this worker was abstracted. Treat it as consumed by
            -- the world, never generate a second log reward.
            tree.status = "INVALID"
            Service.Runtime.claims[tree.key] = nil
            job.targetKey, job.approach = nil, nil
            job.state, job.phase = "READY", "RECONCILING"
            markDirty()
            updateRuntime(record, job, nil)
            return true, false, "physical_tree_missing"
        end
        -- A loaded physical tree is authoritative. Wait for materialization
        -- instead of silently deleting a tree that a player can observe.
        job.state, job.phase = "WAITING", "WAITING_FOR_MATERIALIZATION"
        updateRuntime(record, job, tree)
        return true, false, "loaded_tree_requires_live_execution"
    end
    local tool, toolReason = resolveAbstractTool(record)
    if not tool then
        job.activityItemFullType = nil
        job.state, job.phase = "WAITING", "WAITING_FOR_TOOL"
        updateRuntime(record, job, tree)
        return true, false, toolReason
    end
    job.activityItemFullType = tool.fullType
    local previous = tonumber(job.lastProgressAt) or at
    local elapsed = math.max(0, math.min(Service.ABSTRACT_MAX_ELAPSED_MS,
        at - previous))
    job.lastProgressAt = at
    local damage = (tool.treeDamage / (Service.HIT_INTERVAL_MS / 1000))
        * (elapsed / 1000) * skillRate(record)
    tree.remainingWork = math.max(0,
        (tonumber(tree.remainingWork) or tree.maxWork) - damage)
    job.state, job.phase = "WORKING", "CHOPPING"
    updateAbstractToolWear(record, job, tool)
    markDirty()
    if tree.remainingWork <= 0 then
        job.activityItemFullType = nil
        ensureDeferredTreeEffect(tree)
        local outputEffect = ensureLumberOutputEffect(tree, "ABSTRACT", {
            { fullType = "Base.Log", quantity = tree.logYield },
        }, "OUTPUT_PENDING", "ABSTRACT_OUTPUT_PENDING", record and record.id)
        Service.CompleteTree(tree.key, "abstract")
        job.pendingOutput = {
            mode = "ABSTRACT",
            fullType = "Base.Log", quantity = tree.logYield,
            treeKey = tree.key,
            outputEffectId = outputEffect and outputEffect.id or nil,
        }
        job.targetKey = nil
        job.approach = nil
        job.lastProgressAt = at
        job.state, job.phase = "WAITING", "OUTPUT_PENDING"
        if flushAbstractOutput(job, record) then
            job.state, job.phase = "READY", "OUTPUT_DELIVERED"
        end
        updateRuntime(record, job, nil)
        return true, false, "tree_depleted_abstract_output"
    end
    return true, false, actual and "physical_tree_appeared" or "abstract_chopping"
end

local function tickJob(lease)
    local npcId = tostring(lease and lease.npcId or "")
    local job = Service.GetJob(npcId)
    local zone = job and Service.GetZone(job.zoneId) or nil
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcId) or nil
    if not job or not zone or not record or job.active ~= true
        or zone.enabled ~= true
    then return false, false, "job_unavailable" end
    local at = now()
    expireClaims(at)
    local body = PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(npcId) or nil
    lease.executionMode = body and "LIVE" or "ABSTRACT"
    job.executionMode = lease.executionMode
    if job.pendingOutput then
        if tostring(job.pendingOutput.mode or "ABSTRACT") == "LIVE" then
            if not body then
                local effect = outputEffectFor(job.pendingOutput)
                job.state, job.phase = "WAITING", "WAITING_FOR_WORKER"
                if effect then
                    effect.waitReason = "LUMBER_LIVE_WORKER_REQUIRED"
                    effect.lastReason = effect.waitReason
                    effect.updatedAt = at
                    markDirty()
                end
                updateRuntime(record, job, nil)
                return true, false, "live_output_requires_worker"
            end
            return tickLiveOutput(job, record, body, at)
        end
        if not flushAbstractOutput(job, record) then
            job.state, job.phase = "WAITING", "OUTPUT_PENDING"
            updateRuntime(record, job, nil)
            return true, false, "output_pending"
        end
    end
    local tree = job.targetKey and Service.GetTree(job.targetKey) or nil
    if not tree or tree.status == "DEPLETED" or tree.status == "INVALID" then
        tree = nil
        job.targetKey, job.approach = nil, nil
    end
    if not tree then
        tree = selectClaimedTarget(npcId, at)
        if tree then
            job.targetKey = tree.key
            job.approach = nil
            job.lastHitAt = nil
            job.lastProgressAt = at
            job.revision = (tonumber(job.revision) or 0) + 1
        end
    end
    if tree and not ensureTreeClaim(tree.key, npcId, at) then
        tree = nil
        job.targetKey, job.approach = nil, nil
        tree = selectClaimedTarget(npcId, at)
        if tree then
            job.targetKey, job.approach = tree.key, nil
            job.lastHitAt, job.lastProgressAt = nil, at
        end
    end
    if not tree then
        local pendingScan = zone.scan.complete ~= true
        if pendingScan then
            guideToZone(job, zone, record, body)
            return true, false, "scanning"
        end
        job.state, job.phase = "COMPLETED", "COMPLETE"
        job.activityItemFullType = nil
        updateRuntime(record, job, nil)
        return true, true, "zone_exhausted"
    end
    if body then return tickLive(job, record, body, tree, at) end
    return tickAbstract(job, record, tree, at)
end

local function waitingFor(phase, reason)
    if phase == "WAITING_FOR_TOOL"
        or string.find(tostring(reason or ""), "lumber_tool", 1, true)
        or reason == "tool_cannot_chop"
    then return "primary_tool" end
    if phase == "WAITING_FOR_ENDURANCE" then return "endurance" end
    if phase == "WAITING_FOR_MATERIALIZATION" then return "live_execution" end
    if phase == "WAITING_FOR_TREE_CHUNK" then return "world" end
    if phase == "WAITING_FOR_STOCKPILE" then return "stockpile" end
    if phase == "OUTPUT_PENDING" then return "output" end
    if phase == "GRAB_PENDING" or phase == "DEPOSIT_PENDING" then
        return "output"
    end
    if phase == "TRAVEL" or reason == "traveling"
        or reason == "not_adjacent"
    then return "travel" end
    if phase == "WAITING_FOR_WORKER" or reason == "waiting_for_worker" then
        return "worker"
    end
    return nil
end

local function publishTickDiagnostic(lease, reason, complete)
    local npcId = tostring(lease and lease.npcId or "")
    local job = Service.GetJob(npcId)
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcId) or nil
    if not job or not record then return end
    record.runtime = record.runtime or {}
    local runtime = record.runtime.lumber
    if not runtime then
        runtime = {}
        record.runtime.lumber = runtime
    end
    local phase = tostring(job.phase or runtime.phase or "")
    runtime.lastReason = reason
    runtime.waitingFor = waitingFor(phase, reason)
    runtime.waitingReason = runtime.waitingFor and reason or nil
    if runtime.waitingFor == "primary_tool" then
        local body = PNC.Registry.GetLiveZombie
            and PNC.Registry.GetLiveZombie(npcId) or nil
        runtime.tool = toolDiagnostic(record, body)
    else
        runtime.tool = nil
    end
    if complete then
        runtime.waitingFor = nil
        runtime.waitingReason = nil
        runtime.tool = nil
    end
end

function Service.TickJob(lease)
    local ok, complete, reason = tickJob(lease)
    publishTickDiagnostic(lease, reason, complete)
    return ok, complete, reason
end

return Service
