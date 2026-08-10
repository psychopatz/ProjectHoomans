-- PNC inventory synchronization with the legacy equipment representation.

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Inventory = PNC.Inventory
local Internal = Inventory.Internal

function Inventory.SyncEquipmentFromInventory(record)
    local inv
    local previousWornVisuals
    local previousPrimaryVisual
    local item
    local itemVisual
    local itemID
    local function fullTypeFor(itemID)
        local item = inv and inv.items and inv.items[itemID] or nil
        return item and item.type or nil
    end
    local slot
    if not record then return nil end
    inv = record.inventory
    if not inv then return nil end
    Internal.normalizeLegacyBagSlot(inv)
    record.equipment = PNC.Equipment
        and PNC.Equipment.NormalizeLoadoutSpec
        and PNC.Equipment.NormalizeLoadoutSpec(record.equipment)
        or (record.equipment or {
            primaryFullType = nil,
            secondaryFullType = nil,
            worn = {},
            attached = {},
        })
    previousWornVisuals = record.equipment.wornVisuals or {}
    previousPrimaryVisual = record.equipment.primaryVisual
    record.equipment.primaryFullType = fullTypeFor(inv.equipped.primary)
    item = inv.equipped.primary
        and inv.items
        and inv.items[inv.equipped.primary] or nil
    itemVisual = item
        and PNC.Equipment
        and PNC.Equipment.VisualStateFromItemState
        and PNC.Equipment.VisualStateFromItemState(
            item.itemState,
            item.type
        ) or nil
    if itemVisual then
        record.equipment.primaryVisual = itemVisual
    elseif previousPrimaryVisual
        and tostring(previousPrimaryVisual.fullType or "")
            == tostring(record.equipment.primaryFullType or "")
    then
        record.equipment.primaryVisual = previousPrimaryVisual
        if item and PNC.Equipment.StoreVisualStateInItemState then
            PNC.Equipment.StoreVisualStateInItemState(
                item,
                previousPrimaryVisual
            )
        end
    else
        record.equipment.primaryVisual = nil
    end
    record.equipment.secondaryFullType = fullTypeFor(inv.equipped.secondary)
    record.equipment.worn = {}
    record.equipment.wornVisuals = {}
    record.equipment.attached = {}
    for slot, _ in pairs(inv.worn or {}) do
        itemID = inv.worn[slot]
        item = inv.items and inv.items[itemID] or nil
        record.equipment.worn[slot] = fullTypeFor(itemID)
        itemVisual = item
            and PNC.Equipment
            and PNC.Equipment.VisualStateFromItemState
            and PNC.Equipment.VisualStateFromItemState(
                item.itemState,
                item.type
            ) or nil
        if itemVisual then
            record.equipment.wornVisuals[slot] = itemVisual
        elseif previousWornVisuals[slot]
            and tostring(
                previousWornVisuals[slot].fullType or ""
            ) == tostring(record.equipment.worn[slot] or "")
        then
            record.equipment.wornVisuals[slot] =
                previousWornVisuals[slot]
            if item and PNC.Equipment.StoreVisualStateInItemState then
                PNC.Equipment.StoreVisualStateInItemState(
                    item,
                    previousWornVisuals[slot]
                )
            end
        end
    end
    for slot, _ in pairs(inv.attached or {}) do
        record.equipment.attached[slot] = fullTypeFor(inv.attached[slot])
    end
    return record.equipment
end

function Inventory.SyncFromEquipment(record, reason)
    local inv
    local equipment
    local hadInventory
    local preserved = {}
    local previousInv
    local promotedBackItem
    local primaryItemID
    local function assignItem(slotType, slotValue, fullType)
        local item
        if not fullType then return end
        if slotType == "equip" and slotValue == "bag" then
            local profile = Internal.getContainerProfile(fullType)
            item = Internal.createItem(record, inv, {
                type = fullType,
                container = "root",
                wornSlot = profile.wearableSlot,
                wearableSlot = profile.wearableSlot,
                weightReduction = profile.weightReduction,
                maxWeight = profile.capacity,
            })
            return item and item.id or nil
        end
        item = Internal.createItem(record, inv, {
            type = fullType,
            container = "root",
            wornSlot = slotType == "worn" and slotValue or nil,
            attachedSlot = slotType == "attached" and slotValue or nil,
            equipSlot = slotType == "equip" and slotValue or nil,
        })
        return item and item.id or nil
    end
    local key
    if not record then return nil end

    hadInventory = type(record.inventory) == "table" and record.inventory.revision ~= nil
    previousInv = hadInventory and record.inventory or nil
    if previousInv and type(previousInv.items) == "table" then
        local item
        for _, item in pairs(previousInv.items) do
            if type(item) == "table" and not item.wornSlot and not item.attachedSlot and not item.equipSlot then
                preserved[#preserved + 1] = Internal.itemToPayload(item)
            end
        end
    end

    inv = Internal.createBaseInventory(record)
    record.inventory = inv
    equipment = PNC.Equipment
        and PNC.Equipment.EnsureRecordEquipment
        and PNC.Equipment.EnsureRecordEquipment(record)
        or record.equipment
    if equipment.attached
        and equipment.attached.Back
        and Internal.getItemCapacity(equipment.attached.Back) > 0
    then
        promotedBackItem = assignItem("equip", "bag", equipment.attached.Back)
    end
    if equipment.primaryFullType then
        primaryItemID = assignItem(
            "equip",
            "primary",
            equipment.primaryFullType
        )
        if primaryItemID
            and equipment.primaryVisual
            and inv.items[primaryItemID]
            and PNC.Equipment
            and PNC.Equipment.StoreVisualStateInItemState
        then
            PNC.Equipment.StoreVisualStateInItemState(
                inv.items[primaryItemID],
                equipment.primaryVisual
            )
        end
    end
    if equipment.secondaryFullType then assignItem("equip", "secondary", equipment.secondaryFullType) end
    for key, _ in pairs(equipment.worn or {}) do
        assignItem("worn", key, equipment.worn[key])
    end
    for key, _ in pairs(equipment.attached or {}) do
        if not (key == "Back" and promotedBackItem) then
            assignItem("attached", key, equipment.attached[key])
        end
    end
    for key = 1, #preserved do
        local item = preserved[key]
        if item then
            if item.container ~= "root" and not inv.containers[item.container] then
                local equippedBag
                for wornSlot, wornID in pairs(inv.worn or {}) do
                    local wornItem = inv.items[wornID]
                    if wornItem and wornItem.bagContainer then
                        equippedBag = wornItem
                        break
                    end
                end
                if item.preferredContainer == "bag" and equippedBag then
                    item.container = equippedBag.bagContainer or "root"
                else
                    item.container = "root"
                end
            end
            Internal.createItem(record, inv, item)
        end
    end
    inv.deltaMode = "template_plus_delta"
    if hadInventory then inv.revision = math.max(1, tonumber(inv.revision) or 0) end
    Internal.refreshNextItemSerial(record, inv)
    Inventory.RebuildCaches(record)
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "inventory")
    end
    return record.inventory
end
