-- Preserve loose inventory payloads while rebuilding equipment state.

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}
PNC.Inventory.Internal = PNC.Inventory.Internal or {}

local Internal = PNC.Inventory.Internal

function Internal.collectEquipmentImportPayloads(previousInv)
    local preserved = {}
    local waterPayload
    local invalidPayloadCount = 0
    local items = previousInv and previousInv.items or nil
    local equipped = previousInv and type(previousInv.equipped) == "table"
        and previousInv.equipped or nil
    local waterID = equipped and equipped.waterContainer or nil
    if type(items) ~= "table" then
        return preserved, waterPayload, invalidPayloadCount
    end
    for itemID, item in pairs(items) do
        if type(item) == "table"
            and itemID ~= waterID
            and not item.wornSlot
            and not item.attachedSlot
            and not item.equipSlot
        then
            local payload = Internal.itemToPayload(item)
            if payload then
                preserved[#preserved + 1] = payload
            else
                invalidPayloadCount = invalidPayloadCount + 1
            end
        end
    end
    local waterItem = waterID and items[waterID] or nil
    if type(waterItem) == "table" then
        waterPayload = Internal.itemToPayload(waterItem)
        if waterPayload then
            waterPayload.equipSlot = "waterContainer"
        else
            invalidPayloadCount = invalidPayloadCount + 1
        end
    end
    return preserved, waterPayload, invalidPayloadCount
end

local function findEquippedBag(inv)
    for _, wornID in pairs(inv.worn or {}) do
        local wornItem = inv.items[wornID]
        if wornItem and wornItem.bagContainer then
            return wornItem
        end
    end
    return nil
end

function Internal.restoreEquipmentImportPayloads(
    record, inv, preserved, waterPayload
)
    local bagLookupComplete = false
    local equippedBag
    local restoredCount = 0
    local invalidPayloadCount = 0
    local containerFallbackCount = 0
    local function resolvePayloadContainer(payload)
        if payload.container ~= "root"
            and not inv.containers[payload.container]
        then
            if payload.preferredContainer == "bag" then
                if not bagLookupComplete then
                    equippedBag = findEquippedBag(inv)
                    bagLookupComplete = true
                end
                payload.container = equippedBag
                    and equippedBag.bagContainer or "root"
            else
                payload.container = "root"
            end
            containerFallbackCount = containerFallbackCount + 1
        end
    end
    local restored
    if waterPayload then
        resolvePayloadContainer(waterPayload)
        restored = Internal.createItem(record, inv, waterPayload)
        if restored then
            restoredCount = restoredCount + 1
        else
            invalidPayloadCount = invalidPayloadCount + 1
        end
    end
    for index = 1, #preserved do
        local payload = preserved[index]
        resolvePayloadContainer(payload)
        restored = Internal.createItem(record, inv, payload)
        if restored then
            restoredCount = restoredCount + 1
        else
            invalidPayloadCount = invalidPayloadCount + 1
        end
    end
    return restoredCount, invalidPayloadCount, containerFallbackCount
end
