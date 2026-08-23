PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Internal = PNC.Equipment.Internal or {}

local Equipment = PNC.Equipment
local Internal = Equipment.Internal

function Equipment.BuildPrimaryVisualSummary(record)
    local registry = PNC.Registry
    local equipment = record
        and Equipment.EnsureRecordEquipment(record) or nil
    local inventory = record and record.inventory or nil
    local itemID = inventory and inventory.equipped
        and inventory.equipped.primary or nil
    local inventoryItem = itemID and inventory.items
        and inventory.items[itemID] or nil
    local state = inventoryItem
        and Equipment.VisualStateFromItemState(
            inventoryItem.itemState,
            inventoryItem.type
        ) or equipment and equipment.primaryVisual or nil
    local item
    local body
    local attachedItems
    local entry
    local attachedItem
    local i
    if state then
        if equipment then equipment.primaryVisual = state end
        return state
    end
    if not equipment or not equipment.primaryFullType then return nil end
    body = registry and registry.GetLiveZombie
        and registry.GetLiveZombie(record and record.id) or nil
    item = body and body.getPrimaryHandItem
        and body:getPrimaryHandItem() or nil
    if item and item.getFullType
        and tostring(item:getFullType() or "")
            ~= tostring(equipment.primaryFullType)
    then
        item = nil
    end
    if not item and body and body.getAttachedItems then
        attachedItems = body:getAttachedItems()
        if attachedItems and attachedItems.size
            and attachedItems.get
        then
            for i = 0, attachedItems:size() - 1 do
                entry = attachedItems:get(i)
                attachedItem = entry and entry.getItem
                    and entry:getItem() or nil
                if attachedItem
                    and attachedItem.getFullType
                    and tostring(attachedItem:getFullType() or "")
                        == tostring(equipment.primaryFullType)
                then
                    item = attachedItem
                    break
                end
            end
        end
    end
    if not item then
        item = Equipment.CreateItem(equipment.primaryFullType)
    end
    state = Equipment.CaptureItemVisualState(
        item,
        equipment.primaryFullType
    )
    if not state then return nil end
    equipment.primaryVisual = state
    if inventoryItem then
        Equipment.StoreVisualStateInItemState(
            inventoryItem,
            state
        )
    end
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "equipment_visuals")
    end
    return state
end

-- Capture the concrete visual choices of the server's real worn inventory.
-- Item type alone is insufficient: many PZ clothes and bags randomly select
-- a base texture, texture choice, or tint when an ItemVisual is constructed.
function Equipment.BuildWornVisualSummary(record)
    local registry = PNC.Registry
    local body = registry and registry.GetLiveZombie
        and registry.GetLiveZombie(record and record.id) or nil
    local wornItems = body and body.getWornItems
        and body:getWornItems() or nil
    local output = {}
    local i
    local entry
    local item
    local location
    local captured
    local changed = false
    local inventory = record and record.inventory or nil
    local inventoryItem
    local itemID
    local equipment = record
        and Equipment.EnsureRecordEquipment(record) or nil
    if equipment and PNC.Core and PNC.Core.DeepCopy then
        output = PNC.Core.DeepCopy(
            equipment.wornVisuals or {}
        )
    end
    if not wornItems or not wornItems.size then
        return output
    end
    for i = 0, wornItems:size() - 1 do
        entry = wornItems:get(i)
        item = entry and entry.getItem and entry:getItem() or nil
        location = entry and entry.getLocation
            and entry:getLocation() or nil
        if item and location then
            captured = Equipment.CaptureItemVisualState(item)
            if captured then
                output[tostring(location)] = captured
                itemID = inventory and inventory.worn
                    and inventory.worn[tostring(location)] or nil
                inventoryItem = itemID and inventory.items
                    and inventory.items[itemID] or nil
                if inventoryItem
                    and Internal.VisualStateSignature(
                        Equipment.VisualStateFromItemState(
                            inventoryItem.itemState,
                            inventoryItem.type
                        )
                    ) ~= Internal.VisualStateSignature(captured)
                then
                    Equipment.StoreVisualStateInItemState(
                        inventoryItem,
                        captured
                    )
                    changed = true
                end
                if equipment
                    and Internal.VisualStateSignature(
                        equipment.wornVisuals[location]
                    ) ~= Internal.VisualStateSignature(captured)
                then
                    equipment.wornVisuals[location] = captured
                    changed = true
                end
            end
        end
    end
    if changed
        and PNC.Registry
        and PNC.Registry.MarkDirty
    then
        PNC.Registry.MarkDirty(
            record,
            "equipment_visuals"
        )
    end
    return output
end
PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Internal = PNC.Equipment.Internal or {}

local Equipment = PNC.Equipment
local Internal = Equipment.Internal

