-- NPC inventory output registration and world-floor pickup helpers.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.WorkOutputService
local Internal = Service.Internal
local call = Internal.Call
local nowMs = Internal.Now
local recomputeTotals = Internal.RecomputeTotals
local floorOutputItems = Internal.FloorOutputItems
local bodyHasOutputItem = Internal.BodyHasOutputItem
local clearSquareCache = Internal.ClearSquareCache

local function removeWorldObject(square, worldObject)
    local removed = false
    if type(square and square.removeWorldObject) == "function" then
        square:removeWorldObject(worldObject)
        removed = true
    else
        if type(worldObject and worldObject.removeFromWorld) == "function" then
            worldObject:removeFromWorld()
        end
        if type(worldObject and worldObject.removeFromSquare) == "function" then
            worldObject:removeFromSquare()
        end
        removed = true
    end
    if removed and clearSquareCache then clearSquareCache(square) end
    return removed
end

local function pickupWorldItem(square, worldObject, item, body)
    local inventory = call(body, "getInventory")
    if not inventory then return false, "NPC_INVENTORY_UNAVAILABLE" end
    if type(inventory.canAddItem) == "function"
        and call(inventory, "canAddItem", item) == false
    then
        return false, "NPC_INVENTORY_FULL"
    end
    if not removeWorldObject(square, worldObject) then
        return false, "WORK_FLOOR_REMOVE_FAILED"
    end
    if not call(inventory, "AddItem", item) then
        if square and type(square.AddWorldInventoryItem) == "function" then
            square:AddWorldInventoryItem(item, 0.0, 0.0, 0.0)
        end
        return false, "NPC_INVENTORY_ADD_FAILED"
    end
    return true
end

---Registers outputs placed directly into an NPC's inventory without world drops.
function Service.CaptureInventoryOutput(effect, items, opts)
    if type(effect) ~= "table" then return false, "OUTPUT_EFFECT_MISSING" end
    opts = opts or {}
    local entries = type(items) == "table" and items or {}
    local collected = opts.collected ~= false
    local specs, descriptors = {}, {}
    for _, entry in ipairs(entries) do
        local fullType = type(entry) == "table"
            and tostring(entry.fullType or entry.type or "") or tostring(entry or "")
        if fullType ~= "" then
            local quantity = math.max(1, math.floor(tonumber(
                type(entry) == "table" and (entry.quantity or entry.stack or entry.count)
                or 1) or 1))
            specs[#specs + 1] = { type = fullType, stack = quantity }
            for _ = 1, quantity do
                descriptors[#descriptors + 1] = {
                    id = type(entry) == "table" and entry.id and tostring(entry.id) or nil,
                    fullType = fullType,
                    quantity = 1,
                    collected = collected,
                    delivered = false,
                }
            end
        end
    end
    if #descriptors < 1 then return false, "OUTPUT_ITEMS_EMPTY" end
    if opts.addToInventory == true and opts.record and PNC.Inventory then
        local added, reason
        if type(PNC.Inventory.AddItemsAndSync) == "function" then
            added, reason = PNC.Inventory.AddItemsAndSync(
                opts.record, opts.body, specs, "root", opts.reason or "work_inventory_output"
            )
        elseif type(PNC.Inventory.AddItems) == "function" then
            added, reason = PNC.Inventory.AddItems(
                opts.record, specs, "root", opts.reason or "work_inventory_output"
            )
        end
        if not added then return false, reason or "NPC_INVENTORY_FULL" end
    end
    effect.items = effect.items or {}
    for _, desc in ipairs(descriptors) do
        effect.items[#effect.items + 1] = desc
    end
    recomputeTotals(effect)
    effect.deliveryMode = "NPC_INVENTORY"
    effect.pickupState = collected and "NPC_INVENTORY" or "PENDING"
    effect.phase = opts.phase or "CARRYING"
    if type(opts.markDirty) == "function" then opts.markDirty() end
    return true, effect
end

---Picks up pending ground output descriptors from square into the worker body.
function Internal.PickupGroundOutput(context, record, body, effect, square, opts)
    local descriptors = effect and effect.items or {}
    if #descriptors < 1 then
        local reason = opts and opts.emptyReason or "WORK_OUTPUT_ITEMS_NOT_CAPTURED"
        effect.waitReason, effect.lastReason = reason, reason
        effect.updatedAt = nowMs()
        if opts and type(opts.markDirty) == "function" then opts.markDirty() end
        return false, reason
    end
    local floorByDescriptor = {}
    for _, found in ipairs(floorOutputItems(square, effect, opts)) do
        floorByDescriptor[found.descriptor] = found
    end
    for _, descriptor in ipairs(descriptors) do
        if not descriptor.collected and not descriptor.delivered then
            local found = floorByDescriptor[descriptor]
            if bodyHasOutputItem(body, descriptor, effect.id, opts) then
                descriptor.collected = true
            elseif found then
                local ok, reason = pickupWorldItem(square, found.object,
                    found.item, body)
                if not ok then return false, reason end
                descriptor.collected = true
            else
                local missing = opts and opts.missingReason or "WORK_OUTPUT_ITEM_MISSING"
                effect.waitReason, effect.lastReason = missing, missing
                effect.updatedAt = nowMs()
                if opts and type(opts.markDirty) == "function" then opts.markDirty() end
                return false, missing
            end
        end
    end
    if PNC.Inventory and type(PNC.Inventory.CaptureLooseInventory) == "function" then
        local ok, reason = PNC.Inventory.CaptureLooseInventory(record, body)
        if ok == false then return false, reason or "NPC_INVENTORY_CAPTURE_FAILED" end
    end
    effect.phase = "CARRYING"
    effect.pickupState = "NPC_INVENTORY"
    effect.waitReason = nil
    effect.lastReason = opts and opts.pickedReason or "WORK_OUTPUT_PICKED_UP"
    effect.updatedAt = nowMs()
    if opts and type(opts.markDirty) == "function" then opts.markDirty() end
    if context then
        context.state = "TRAVELING"
        context.phase = "OUTPUT_DESTINATION_APPROACH"
    end
    return true
end

return Service
