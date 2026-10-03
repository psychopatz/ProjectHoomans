if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.LumberService
local Internal = Service.Internal
local now = Internal.Now
local markDirty = Internal.MarkDirty
local updateRuntime = Internal.UpdateRuntime
local outputEffectFor = Internal.OutputEffectFor
local setOutputEffectState = Internal.SetOutputEffectState
local call = Internal.Call
local listSize = Internal.ListSize
local listItem = Internal.ListItem
local worldObjectsFor = Internal.WorldObjectsFor
local itemID = Internal.ItemID
local itemType = Internal.ItemType
local hasCurrentOutputMarker = Internal.HasCurrentOutputMarker

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
    local result = PNC.AnimationScenes.Request(record, body, sceneID, {
        reason = reason, repeatMode = "once",
    })
    if result == false then
        return "failed", "LUMBER_ANIMATION_FAILED"
    end
    return "started"
end

local function descriptorMatches(item, descriptor, effectID)
    if not descriptor then return false end
    local descriptorID = descriptor.id and tostring(descriptor.id) or nil
    local id = itemID(item)
    local data = call(item, "getModData")
    local tagged = hasCurrentOutputMarker(data, effectID)
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
        square:removeWorldObject(worldObject)
        return true
    end
    local removed = true
    if type(worldObject and worldObject.removeFromWorld) == "function" then
        worldObject:removeFromWorld()
    end
    if type(worldObject and worldObject.removeFromSquare) == "function" then
        worldObject:removeFromSquare()
    end
    return removed
end

local function restoreWorldObject(square, item)
    if not square or not item
        or type(square.AddWorldInventoryItem) ~= "function"
    then return false end
    local restored = square:AddWorldInventoryItem(item, 0.0, 0.0, 0.0)
    return restored ~= nil
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
Internal.OutputDelivery = Internal.OutputDelivery or {}
Internal.OutputDelivery.OneShotAnimation = oneShotAnimation
Internal.OutputDelivery.PickupOutputItems = pickupOutputItems
Internal.FlushAbstractOutput = flushAbstractOutput
