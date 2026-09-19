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
