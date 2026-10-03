-- Durable lumber output-effect creation and world-item capture.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.LumberService
local Internal = Service.Internal
local now = Internal.Now
local markDirty = Internal.MarkDirty
local LUMBER_OUTPUT_MARKER_VERSION = Internal.LumberOutputMarkerVersion

Internal.OutputEffectFor = function(output)
    if type(output) ~= "table" or not output.treeKey then return nil end
    local tree = Service.GetTree(output.treeKey)
    return tree and tree.outputEffect or nil
end

Internal.SetOutputEffectState = function(effect, state, reason)
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

Internal.EnsureLumberOutputEffect = function(tree, mode, items, phase, reason,
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
        data.PNC_LumberOutputEffectVersion =
            LUMBER_OUTPUT_MARKER_VERSION
    end
    if type(worldObject and worldObject.transmitModData) == "function" then
        worldObject:transmitModData()
    end
end

local function hasCurrentOutputMarker(data, effectID)
    if type(data) ~= "table"
        or tostring(data.PNC_LumberOutputEffectID or "")
            ~= tostring(effectID or "")
    then
        return false
    end
    if tonumber(data.PNC_LumberOutputEffectVersion)
        ~= LUMBER_OUTPUT_MARKER_VERSION
    then
        -- Old item provenance is not migrated. Drop it when the item is
        -- observed so a current effect can establish a fresh marker.
        data.PNC_LumberOutputEffectID = nil
        data.PNC_LumberOutputEffectVersion = nil
        return false
    end
    return true
end

Internal.CaptureOutputItems = function(square, before, effect, snapshotOnly)
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
                local tagged = hasCurrentOutputMarker(data, effect.id)
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

-- Delivery providers reuse these narrow world-object helpers.
Internal.Call = call
Internal.ListSize = listSize
Internal.ListItem = listItem
Internal.WorldObjectsFor = worldObjectsFor
Internal.ItemID = itemID
Internal.ItemType = itemType
Internal.HasCurrentOutputMarker = hasCurrentOutputMarker

return Service
