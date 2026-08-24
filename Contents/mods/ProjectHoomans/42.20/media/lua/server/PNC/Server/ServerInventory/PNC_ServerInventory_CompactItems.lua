if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ServerInventory = PNC.ServerInventory or {}
PNC.ServerInventory.Internal = PNC.ServerInventory.Internal or {}

local Service = PNC.ServerInventory
local Internal = Service.Internal
local ItemTransfer = Internal.ItemTransfer
local isNonEmptyContainer = Internal.isNonEmptyContainer

local function compactSpec(item)
    local description, reason = ItemTransfer.DescribeItem(item)
    if not description then return nil, reason end
    if isNonEmptyContainer(item) then return nil, "container_not_empty" end
    local nested = item.getItemContainer and item:getItemContainer()
        or item.getInventory and item:getInventory()
        or nil
    local state = description.state or {}
    local reduction = item.getWeightReduction
        and tonumber(item:getWeightReduction())
        or nil
    if reduction and reduction > 1 then reduction = reduction / 100 end
    local wearableSlot = item.canBeEquipped
        and tostring(item:canBeEquipped() or "")
        or nil
    if wearableSlot == "" then wearableSlot = nil end
    return {
        type = description.fullType,
        stack = 1,
        uses = state.usedDelta,
        cond = state.condition,
        ammoCount = state.ammoCount,
        fav = state.favorite == true,
        customName = state.customName,
        maxWeight = nested and nested.getCapacity and tonumber(nested:getCapacity()) or nil,
        weightReduction = reduction,
        wearableSlot = wearableSlot,
        itemState = state,
    }
end

local function rollbackNativeItems(items)
    for _, item in ipairs(items or {}) do
        ItemTransfer.RemoveItem(item)
    end
end

local function compactContainerHasItems(inv, item)
    local container = item and item.bagContainer
        and inv and inv.containers and inv.containers[item.bagContainer]
        or nil
    return container and type(container.items) == "table" and #container.items > 0 or false
end

local function portableCompactItemState(record, item)
    local state = {}
    local visual = item and item.wornSlot
        and record and record.equipment
        and record.equipment.wornVisuals
        and record.equipment.wornVisuals[item.wornSlot] or nil
    for key, value in pairs(item and item.itemState or {}) do
        state[key] = value
    end
    if visual then
        state.visualFullType = tostring(visual.fullType or item.type)
        state.visualBaseTexture = tonumber(visual.baseTexture)
        state.visualTextureChoice = tonumber(visual.textureChoice)
        state.visualDecal = visual.decal
            and tostring(visual.decal) or nil
        state.visualTintR = visual.tint and tonumber(visual.tint.r) or nil
        state.visualTintG = visual.tint and tonumber(visual.tint.g) or nil
        state.visualTintB = visual.tint and tonumber(visual.tint.b) or nil
    end
    state.condition = item and (item.cond or state.condition) or state.condition
    state.usedDelta = item and (item.uses or state.usedDelta) or state.usedDelta
    state.ammoCount = item and (item.ammoCount or state.ammoCount) or state.ammoCount
    state.favorite = item and item.fav == true or false
    state.customName = item and (item.customName or state.customName) or state.customName
    return state
end

Internal.compactSpec = compactSpec
Internal.rollbackNativeItems = rollbackNativeItems
Internal.compactContainerHasItems = compactContainerHasItems
Internal.portableCompactItemState = portableCompactItemState
