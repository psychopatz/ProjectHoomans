-- Shared native-item capture used by authoritative transfers and the local
-- unique-NPC editor. The result is the same compact item specification used by
-- Inventory.AddItems, so an editor draft cannot invent a second item format.

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Inventory = PNC.Inventory
local Internal = Inventory.Internal
local Portable = require "PsychopatzCore/Inventory/PsychopatzPortableItemState"

local function call(item, method, fallback, ...)
    if not item or type(item[method]) ~= "function" then return fallback end
    local value = item[method](item, ...)
    if value == nil then return fallback end
    return value
end

local function stringValue(value)
    if value == nil or value == "" then return nil end
    return tostring(value)
end

local function nativeState(item)
    local state = {}
    local fields = {
        { "condition", "getCondition" },
        { "usedDelta", "getUsedDelta" },
        { "ammoCount", "getCurrentAmmoCount" },
        { "favorite", "isFavorite" },
        { "customName", "getName" },
    }
    local i
    local field
    local value
    for i = 1, #fields do
        field = fields[i]
        value = call(item, field[2], nil)
        if value ~= nil then state[field[1]] = value end
    end
    if Portable.CaptureFluid then
        local fluid = Portable.CaptureFluid(item)
        if fluid then
            for key, value in pairs(fluid) do state[key] = value end
        end
    end
    if Portable.CaptureFood and call(item, "isFood", false) == true then
        local food = Portable.CaptureFood(item)
        if food then
            for key, value in pairs(food) do state[key] = value end
        end
    end
    -- Clothing visual choices (texture, decal, tint, model index, and custom
    -- colour) are native item state too.  Capture them before sanitizing so a
    -- transfer into an editor preview cannot silently revert a shirt to its
    -- default appearance.
    local equipment = PNC.Equipment
    if equipment and equipment.CaptureItemVisualState
        and equipment.StoreVisualStateInItemState
    then
        local fullType = stringValue(call(item, "getFullType", nil))
        local visual = equipment.CaptureItemVisualState(item, fullType)
        if visual then
            local holder = { type = fullType, itemState = state }
            equipment.StoreVisualStateInItemState(holder, visual)
            state = holder.itemState
        end
    end
    -- Native modData is the item-owned extension point used by clothing and
    -- picture/texture metadata.  sanitizeItemState applies the existing
    -- bounded scalar map policy before it can enter a definition file.
    local modData = call(item, "getModData", nil)
    if type(modData) == "table" then state.modData = modData end
    if Internal.sanitizeItemState then
        return Internal.sanitizeItemState(state)
    end
    return state
end

local function nonEmptyContainer(item)
    local nested = call(item, "getItemContainer", nil)
        or call(item, "getInventory", nil)
    local items = nested and call(nested, "getItems", nil) or nil
    return items and items.size and items:size() > 0 or false
end

function Inventory.CaptureNativeItem(item, options)
    options = type(options) == "table" and options or {}
    if not item then return nil, "item_missing" end
    if nonEmptyContainer(item) then return nil, "container_not_empty" end
    local fullType = stringValue(call(item, "getFullType", nil))
    if not fullType then return nil, "item_type_missing" end
    local state = nativeState(item)
    local nested = call(item, "getItemContainer", nil)
        or call(item, "getInventory", nil)
    local reduction = tonumber(call(item, "getWeightReduction", nil))
    if reduction and reduction > 1 then reduction = reduction / 100 end
    local wearable = stringValue(call(item, "canBeEquipped", nil))
    return {
        type = fullType,
        stack = 1,
        uses = state.usedDelta,
        cond = state.condition,
        ammoCount = state.ammoCount,
        fav = state.favorite == true,
        customName = state.customName,
        maxWeight = nested and tonumber(call(nested, "getCapacity", nil)) or nil,
        weightReduction = reduction,
        wearableSlot = wearable,
        wornSlot = options.wornSlot,
        attachedSlot = options.attachedSlot,
        equipSlot = options.equipSlot,
        preferredContainer = options.preferredContainer,
        itemState = state,
    }
end

Inventory.Internal.CaptureNativeItem = Inventory.CaptureNativeItem

return Inventory.CaptureNativeItem
