--[[
    PNC Inventory Item Actions
    Data-driven item command registry shared by the UI and server authority.
    New commands can be registered without changing the inventory window.
]]

PNC = PNC or {}
PNC.InventoryActions = PNC.InventoryActions or {}

local Actions = PNC.InventoryActions
local Inventory = PNC.Inventory

Actions.Definitions = Actions.Definitions or {}
Actions.Order = Actions.Order or {}

local function appendUnique(value)
    for index = 1, #Actions.Order do
        if Actions.Order[index] == value then return end
    end
    Actions.Order[#Actions.Order + 1] = value
end

function Actions.Register(definition)
    if type(definition) ~= "table" or not definition.id
        or type(definition.execute) ~= "function"
    then
        return false
    end
    local actionID = tostring(definition.id)
    if actionID == "" then return false end
    definition.id = actionID
    Actions.Definitions[actionID] = definition
    appendUnique(actionID)
    return true
end

function Actions.Get(actionID)
    return Actions.Definitions[tostring(actionID or "")]
end

function Actions.List()
    local output = {}
    for index = 1, #Actions.Order do
        local definition = Actions.Definitions[Actions.Order[index]]
        if definition then output[#output + 1] = definition end
    end
    return output
end

function Actions.IsAvailable(definition, record, item)
    if not definition or not item then return false end
    if type(definition.isAvailable) ~= "function" then return true end
    local ok, available = pcall(definition.isAvailable, record, item)
    return ok and available == true
end

function Actions.Execute(actionID, player, record, itemID, context)
    local definition = Actions.Get(actionID)
    local inv = Inventory and Inventory.EnsureRecordInventory
        and Inventory.EnsureRecordInventory(record)
        or nil
    local item = inv and inv.items and inv.items[tostring(itemID or "")] or nil
    if not definition then return false, "action_not_found" end
    if not item then return false, "item_not_found" end
    if not Actions.IsAvailable(definition, record, item) then
        return false, "action_unavailable"
    end
    return definition.execute(player, record, item, context or {})
end

local function resolveWornSlot(item)
    local stored = item and item.wearableSlot
    if stored and tostring(stored) ~= "" then return tostring(stored) end
    local profile = Inventory and Inventory.GetContainerProfile
        and Inventory.GetContainerProfile(item and item.type)
        or nil
    if profile and profile.wearableSlot then
        return tostring(profile.wearableSlot)
    end
    local probe = PNC.Equipment and PNC.Equipment.CreateItem
        and PNC.Equipment.CreateItem(item and item.type)
        or nil
    if type(probe) == "table" and not probe.getBodyLocation and probe[1] then
        probe = probe[1]
    end
    local slot = probe and probe.canBeEquipped and probe:canBeEquipped() or nil
    if not slot or tostring(slot) == "" then
        slot = probe and probe.getBodyLocation and probe:getBodyLocation() or nil
    end
    slot = slot and tostring(slot) or nil
    return slot ~= "" and slot or nil
end

local function isWearableContainer(item)
    return item and item.bagContainer ~= nil and resolveWornSlot(item) ~= nil
end

Actions.Register({
    id = "favorite",
    labelKey = "UI_PNC_Inventory_Favorite",
    label = "Favorite",
    iconTexture = "media/ui/FavoriteStarChecked.png",
    refreshEquipment = false,
    isAvailable = function(_, item)
        return item.fav ~= true
    end,
    execute = function(_, record, item)
        return Inventory.SetFavorite(
            record,
            item.id,
            true,
            "inventory_action_favorite"
        )
    end,
})

Actions.Register({
    id = "unfavorite",
    labelKey = "UI_PNC_Inventory_Unfavorite",
    label = "Unfavorite",
    iconTexture = "media/ui/FavoriteStarUnchecked.png",
    refreshEquipment = false,
    isAvailable = function(_, item)
        return item.fav == true
    end,
    execute = function(_, record, item)
        return Inventory.SetFavorite(
            record,
            item.id,
            false,
            "inventory_action_unfavorite"
        )
    end,
})

Actions.Register({
    id = "equip_container",
    labelKey = "UI_PNC_Inventory_EquipContainer",
    label = "Equip Bag",
    isAvailable = function(_, item)
        return item.wornSlot == nil and isWearableContainer(item)
    end,
    execute = function(_, record, item)
        local slot = resolveWornSlot(item)
        if not slot then return false, "not_equippable_container" end
        return Inventory.SetWorn(
            record,
            item.id,
            slot,
            "inventory_action_equip_container"
        )
    end,
})

Actions.Register({
    id = "unequip_container",
    labelKey = "UI_PNC_Inventory_UnequipContainer",
    label = "Unequip Bag",
    isAvailable = function(_, item)
        return item.wornSlot ~= nil and item.bagContainer ~= nil
    end,
    execute = function(_, record, item)
        return Inventory.ClearWorn(
            record,
            item.id,
            "inventory_action_unequip_container"
        )
    end,
})

Actions.Register({
    id = "equip_primary",
    labelKey = "UI_PNC_Inventory_Equip",
    label = "Equip Primary",
    isAvailable = function(_, item)
        return item.equipSlot ~= "primary"
            and item.wornSlot == nil
            and item.bagContainer == nil
    end,
    execute = function(_, record, item)
        return Inventory.SetEquipped(record, "primary", item.id, "inventory_action_equip")
    end,
})

Actions.Register({
    id = "unequip",
    labelKey = "UI_PNC_Inventory_Unequip",
    label = "Unequip",
    isAvailable = function(_, item)
        return item.equipSlot ~= nil
    end,
    execute = function(_, record, item)
        return Inventory.SetEquipped(
            record,
            item.equipSlot,
            nil,
            "inventory_action_unequip"
        )
    end,
})

Actions.Register({
    id = "wear",
    labelKey = "UI_PNC_Inventory_Wear",
    label = "Wear",
    isAvailable = function(_, item)
        return item.wornSlot == nil
            and item.bagContainer == nil
            and resolveWornSlot(item) ~= nil
    end,
    execute = function(_, record, item)
        local slot = resolveWornSlot(item)
        if not slot then return false, "not_wearable" end
        if item.equipSlot then
            Inventory.SetEquipped(
                record,
                item.equipSlot,
                nil,
                "inventory_action_wear_clear_hand"
            )
        end
        return Inventory.SetWorn(record, item.id, slot, "inventory_action_wear")
    end,
})

Actions.Register({
    id = "remove_worn",
    labelKey = "UI_PNC_Inventory_Remove",
    label = "Remove",
    isAvailable = function(_, item)
        return item.wornSlot ~= nil and item.bagContainer == nil
    end,
    execute = function(_, record, item)
        return Inventory.ClearWorn(record, item.id, "inventory_action_remove_worn")
    end,
})

-- Drop is executed by the server transaction service because it must
-- materialize a native world item before removing the compact source item.
Actions.Register({
    id = "drop",
    labelKey = "UI_PNC_Inventory_Drop",
    label = "Drop",
    isAvailable = function()
        return true
    end,
    execute = function()
        return false, "server_transaction_required"
    end,
})

return Actions
