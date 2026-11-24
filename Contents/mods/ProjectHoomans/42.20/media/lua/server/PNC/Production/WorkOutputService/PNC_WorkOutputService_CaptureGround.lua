-- Shared ground work-output world-object inspection and capture helpers.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorkOutputService = PNC.WorkOutputService or {}
PNC.WorkOutputService.Internal = PNC.WorkOutputService.Internal or {}

local Service = PNC.WorkOutputService
local Internal = Service.Internal
local OUTPUT_MARKER_VERSION = 1

local function call(object, method, ...)
    local kind = type(object)
    local fn = (kind == "table" or kind == "userdata") and object[method] or nil
    if type(fn) ~= "function" then return nil end
    return fn(object, ...)
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

local function squareCoords(square)
    local sx = call(square, "getX")
    local sy = call(square, "getY")
    local sz = call(square, "getZ")
    if sx == nil or sy == nil then return nil end
    return sx, sy, sz or 0
end

local function clearSquareCache(square)
    local worldCtx = PNC and PNC.WorldItemContext
    if not (worldCtx and worldCtx.ClearSquare and square) then return end
    local cell = type(getCell) == "function" and getCell() or nil
    if not cell then return end
    local sx, sy, sz = squareCoords(square)
    if sx ~= nil then worldCtx.ClearSquare(cell, sx, sy, sz) end
end

local function readWorldObjects(square, invalidateFirst)
    if not square then return nil end
    if invalidateFirst then clearSquareCache(square) end
    local worldCtx = PNC and PNC.WorldItemContext
    local cell = type(getCell) == "function" and getCell() or nil
    if worldCtx and worldCtx.GetSquareSnapshot and cell then
        local sx, sy, sz = squareCoords(square)
        if sx ~= nil then
            local snap = worldCtx.GetSquareSnapshot(cell, sx, sy, sz)
            if snap and snap.square == square and snap.worldObjects then
                return snap.worldObjects
            end
        end
    end
    return call(square, "getWorldObjects")
end

local function itemID(item, worldObject)
    return call(item, "getID") or call(worldObject, "getKeyId")
end

local function itemType(item)
    return call(item, "getFullType") or call(item, "getType")
end

local function nowMs()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

local function recomputeTotals(effect)
    local items = type(effect.items) == "table" and effect.items or {}
    local quantity = 0
    for _, entry in ipairs(items) do
        if type(entry) == "table" then
            quantity = quantity + math.max(1,
                math.floor(tonumber(entry.quantity or entry.stack) or 1))
        end
    end
    effect.itemCount = #items
    effect.totalQuantity = quantity
    effect.actualQuantity = quantity
    effect.updatedAt = nowMs()
end

local function markerKeys(opts)
    local idKey = opts and opts.markerKey or "PNC_WorkOutputEffectID"
    local verKey = opts and opts.markerVersionKey or "PNC_WorkOutputEffectVersion"
    local verVal = tonumber(opts and opts.markerVersion) or OUTPUT_MARKER_VERSION
    return idKey, verKey, verVal
end

local function tagOutputItem(item, worldObject, effectID, opts)
    local data = call(item, "getModData")
    if type(data) == "table" then
        local idKey, verKey, verVal = markerKeys(opts)
        data[idKey], data[verKey] = tostring(effectID), verVal
        if idKey ~= "PNC_WorkOutputEffectID" then
            data.PNC_WorkOutputEffectID = tostring(effectID)
            data.PNC_WorkOutputEffectVersion = OUTPUT_MARKER_VERSION
        end
    end
    local kind = type(worldObject)
    if (kind == "table" or kind == "userdata")
        and type(worldObject.transmitModData) == "function"
    then
        worldObject:transmitModData()
    end
end

local function hasCurrentOutputMarker(data, effectID, opts)
    if type(data) ~= "table" then return false end
    local idKey, verKey, verVal = markerKeys(opts)
    local targetId = tostring(effectID or "")
    if tostring(data.PNC_WorkOutputEffectID or "") == targetId
        and tonumber(data.PNC_WorkOutputEffectVersion) == OUTPUT_MARKER_VERSION
    then
        return true
    end
    if tostring(data[idKey] or "") ~= targetId then return false end
    if tonumber(data[verKey]) ~= verVal then
        data[idKey], data[verKey] = nil, nil
        return false
    end
    return true
end

local function descriptorMatches(item, descriptor, effectID, opts)
    if not descriptor then return false end
    local descriptorID = descriptor.id and tostring(descriptor.id) or nil
    local id = itemID(item)
    if descriptorID and id then return descriptorID == tostring(id) end
    local tagged = hasCurrentOutputMarker(call(item, "getModData"), effectID, opts)
    if tagged and descriptor.fullType then
        return tostring(descriptor.fullType) == tostring(itemType(item) or "")
    end
    return tagged
end

local function floorOutputItems(square, effect, opts)
    local output = {}
    local objects = readWorldObjects(square, false)
    for index = 0, listSize(objects) - 1 do
        local worldObject = listItem(objects, index)
        local item = worldObject and call(worldObject, "getItem") or nil
        if item then
            for _, descriptor in ipairs(effect and effect.items or {}) do
                if not descriptor.collected and not descriptor.delivered
                    and descriptorMatches(item, descriptor, effect.id, opts)
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

local function bodyHasOutputItem(body, descriptor, effectID, opts)
    local inventory = call(body, "getInventory")
    local items = call(inventory, "getItems")
    for index = 0, listSize(items) - 1 do
        local item = listItem(items, index)
        if item and descriptorMatches(item, descriptor, effectID, opts) then
            return true
        end
    end
    return false
end

local function captureObject(worldObject, before, effect, opts)
    local item = call(worldObject, "getItem")
    local tagged = hasCurrentOutputMarker(call(item, "getModData"), effect.id, opts)
    if not (((before and before[worldObject] ~= true) or tagged) and item) then
        return 0
    end
    local fullType = itemType(item)
    if not fullType then return 0 end
    local id = itemID(item, worldObject)
    for _, existing in ipairs(effect.items or {}) do
        if id and existing.id and tostring(existing.id) == tostring(id) then
            return 0
        end
    end
    effect.items = effect.items or {}
    effect.items[#effect.items + 1] = {
        id = id and tostring(id) or nil,
        fullType = tostring(fullType),
        quantity = 1,
    }
    tagOutputItem(item, worldObject, effect.id, opts)
    return 1
end

---Snapshots or captures newly spawned ground items into a durable output effect.
function Service.CaptureGroundOutput(square, beforeSnapshot, effect, opts)
    opts = opts or {}
    local objects = readWorldObjects(square, opts.snapshotOnly ~= true)
    local seen, captured = {}, 0
    for index = 0, listSize(objects) - 1 do
        local worldObject = listItem(objects, index)
        if worldObject then
            seen[worldObject] = true
            if opts.snapshotOnly ~= true and effect then
                captured = captured + captureObject(worldObject, beforeSnapshot, effect, opts)
            end
        end
    end
    if opts.snapshotOnly == true then return seen end
    if captured > 0 then clearSquareCache(square) end
    if effect then
        recomputeTotals(effect)
        if type(opts.markDirty) == "function" then opts.markDirty() end
    end
    return captured
end

Internal.Call = call
Internal.Now = nowMs
Internal.RecomputeTotals = recomputeTotals
Internal.FloorOutputItems = floorOutputItems
Internal.BodyHasOutputItem = bodyHasOutputItem
Internal.ClearSquareCache = clearSquareCache

return Service
