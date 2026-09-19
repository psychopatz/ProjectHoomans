-- PNC inventory reconstruction from the legacy equipment representation.

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

require "PNC/Core/Inventory/PNC_Inventory/Equipment/PNC_Inventory_EquipmentImportAudit"

local Inventory = PNC.Inventory
local Internal = Inventory.Internal
local Audit = Internal.EquipmentImportAudit

local function assignEquipmentItem(record, inv, slotType, slotValue, fullType)
    local item
    if not fullType then return nil end
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

local function projectEquipmentSlots(record, inv, equipment, wornSlots, attachedSlots)
    local promotedBackItem
    local primaryItemID
    local backType = attachedSlots.Back
    if type(backType) == "string"
        and Internal.getItemCapacity(backType) > 0
    then
        promotedBackItem = assignEquipmentItem(
            record,
            inv,
            "equip",
            "bag",
            backType
        )
    end
    if equipment.primaryFullType then
        primaryItemID = assignEquipmentItem(
            record,
            inv,
            "equip",
            "primary",
            equipment.primaryFullType
        )
        if primaryItemID
            and type(equipment.primaryVisual) == "table"
            and inv.items[primaryItemID]
            and PNC.Equipment
            and type(PNC.Equipment.StoreVisualStateInItemState) == "function"
        then
            PNC.Equipment.StoreVisualStateInItemState(
                inv.items[primaryItemID],
                equipment.primaryVisual
            )
        end
    end
    if equipment.secondaryFullType then
        assignEquipmentItem(
            record,
            inv,
            "equip",
            "secondary",
            equipment.secondaryFullType
        )
    end
    for slot, fullType in pairs(wornSlots) do
        assignEquipmentItem(record, inv, "worn", slot, fullType)
    end
    for slot, fullType in pairs(attachedSlots) do
        if not (slot == "Back" and promotedBackItem) then
            assignEquipmentItem(record, inv, "attached", slot, fullType)
        end
    end
end

function Inventory.SyncFromEquipment(record, reason)
    local previousInv
    local hadInventory
    local previousRevision
    local equipment
    local wornSlots
    local attachedSlots
    local inv
    local preserved
    local waterPayload
    local invalidPayloadCount
    local restoredCount
    local restoreInvalidCount
    local containerFallbackCount
    local itemCountBefore
    local auditEnabled
    local dirtyMarked = false
    local cacheRebuilt = false
    if not record then return nil end
    auditEnabled = Audit.InventoryAuditEnabled()
    hadInventory = type(record.inventory) == "table"
        and record.inventory.revision ~= nil
    previousInv = hadInventory and record.inventory or nil
    previousRevision = hadInventory
        and math.max(0, math.floor(tonumber(previousInv.revision) or 0)) or nil
    itemCountBefore = auditEnabled and previousInv
        and type(previousInv.items) == "table"
        and Internal.countMapEntries(previousInv.items) or 0
    equipment = PNC.Equipment
        and type(PNC.Equipment.EnsureRecordEquipment) == "function"
        and PNC.Equipment.EnsureRecordEquipment(record)
        or record.equipment
    if type(equipment) ~= "table" then
        local npcID = Audit.Token(record.id, "unknown", 64)
        if PNC.Core and type(PNC.Core.LogWarn) == "function" then
            PNC.Core.LogWarn(
                "[PNC][INVENTORY] equipment sync failed npc=" .. npcID
                    .. " reason=equipment_unavailable"
            )
        end
        Audit.LogEquipmentSync(
            record,
            reason,
            "equipment_unavailable",
            nil,
            itemCountBefore,
            itemCountBefore,
            0,
            0,
            0,
            previousRevision,
            previousRevision,
            false,
            false,
            auditEnabled
        )
        return nil, "equipment_unavailable"
    end
    wornSlots = type(equipment.worn) == "table" and equipment.worn or {}
    attachedSlots = type(equipment.attached) == "table"
        and equipment.attached or {}
    preserved, waterPayload, invalidPayloadCount =
        Internal.collectEquipmentImportPayloads(previousInv)
    inv = Internal.createBaseInventory(record)
    projectEquipmentSlots(record, inv, equipment, wornSlots, attachedSlots)
    restoredCount, restoreInvalidCount, containerFallbackCount =
        Internal.restoreEquipmentImportPayloads(
            record, inv, preserved, waterPayload
        )
    if hadInventory then
        inv.revision = math.max(1, previousRevision + 1)
    end
    Internal.refreshNextItemSerial(record, inv)
    record.inventory = inv
    Inventory.RebuildCaches(record)
    cacheRebuilt = true
    if PNC.Registry and type(PNC.Registry.MarkDirty) == "function" then
        PNC.Registry.MarkDirty(record, "inventory")
        dirtyMarked = true
    end
    Audit.LogEquipmentSync(
        record,
        reason,
        "complete",
        equipment,
        itemCountBefore,
        auditEnabled and Internal.countMapEntries(inv.items) or nil,
        restoredCount,
        invalidPayloadCount + restoreInvalidCount,
        containerFallbackCount,
        previousRevision,
        hadInventory and inv.revision or nil,
        cacheRebuilt,
        dirtyMarked,
        auditEnabled
    )
    return record.inventory
end
