PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Internal = PNC.Equipment.Internal or {}

local Equipment = PNC.Equipment
local Internal = Equipment.Internal
local Core = PNC.Core
local Visuals = PNC.Visuals

local function resolveBodyLocation(item, fallback)
    local bodyLocation = item.getBodyLocation
        and item:getBodyLocation() or nil
    if (not bodyLocation or tostring(bodyLocation) == "")
        and item.canBeEquipped
    then
        bodyLocation = item:canBeEquipped()
    end
    if not bodyLocation or tostring(bodyLocation) == "" then
        return fallback
    end
    return bodyLocation
end

local function loadStoredVisual(item, record, equipment, entry)
    Internal.applyInventoryState(item, record, entry.bodyLocation)
    local inventoryItem = Internal.getWornInventoryItem(
        record,
        entry.bodyLocation
    )
    local storedVisual = inventoryItem
        and Equipment.VisualStateFromItemState
        and Equipment.VisualStateFromItemState(
            inventoryItem.itemState,
            inventoryItem.type
        ) or nil
    if not storedVisual then
        storedVisual = equipment.wornVisuals
            and equipment.wornVisuals[entry.bodyLocation]
            or nil
    end
    Internal.applyItemVisualState(item, storedVisual)
    return inventoryItem, storedVisual
end

local function storeCapturedVisual(
    equipment,
    entry,
    inventoryItem,
    storedVisual,
    capturedVisual
)
    local changed = false
    if capturedVisual and inventoryItem
        and Equipment.StoreVisualStateInItemState
        and Internal.visualStateSignature(
            Equipment.VisualStateFromItemState(
                inventoryItem.itemState,
                inventoryItem.type
            )
        ) ~= Internal.visualStateSignature(capturedVisual)
    then
        Equipment.StoreVisualStateInItemState(inventoryItem, capturedVisual)
        changed = true
    end
    if capturedVisual
        and Internal.visualStateSignature(storedVisual)
            ~= Internal.visualStateSignature(capturedVisual)
    then
        equipment.wornVisuals[entry.bodyLocation] = capturedVisual
        changed = true
    end
    return changed
end

local function addVisualFallback(zombie, entry, visual)
    if Internal.isNetworkedGame() then
        return false, "network_authority_no_visual_fallback"
    end
    return Visuals.AddClothingVisual(zombie, entry.fullType, visual)
end

local function applyCreatedWornItem(zombie, equipment, record, entry, item)
    local inventoryItem, storedVisual = loadStoredVisual(
        item,
        record,
        equipment,
        entry
    )
    local bodyLocation = resolveBodyLocation(item, entry.bodyLocation)
    local wornOk
    local wornReason
    if bodyLocation then
        if Core and Core.ProtectClothingFromFall then
            Core.ProtectClothingFromFall(item)
        end
        wornOk, wornReason = Internal.safeInvoke(
            zombie,
            "setWornItem",
            bodyLocation,
            item
        )
    else
        wornOk, wornReason = false, "missing_typed_body_location"
    end
    if not wornOk then
        local visualOk, visualReason = addVisualFallback(
            zombie,
            entry,
            storedVisual
        )
        if visualOk then
            Core.LogWarn("PNC equipment displayed but could not mechanically wear "
                .. tostring(entry.fullType) .. ": " .. tostring(wornReason))
            return 1, 0, false
        end
        Core.LogWarn("PNC equipment failed to wear "
            .. tostring(entry.fullType) .. " on "
            .. tostring(entry.bodyLocation) .. ": visual="
            .. tostring(visualReason) .. ", worn=" .. tostring(wornReason))
        return 0, 1, false
    end

    local capturedVisual = Equipment.CaptureItemVisualState
        and Equipment.CaptureItemVisualState(item, entry.fullType)
        or nil
    local visualChanged = storeCapturedVisual(
        equipment,
        entry,
        inventoryItem,
        storedVisual,
        capturedVisual
    )
    if not Internal.isNetworkedGame()
        and not Internal.hasClothingVisual(zombie, entry.fullType)
    then
        local visualOk, visualReason = Visuals.AddClothingVisual(
            zombie,
            entry.fullType,
            capturedVisual or storedVisual
        )
        if not visualOk then
            Core.LogWarn("PNC equipment mechanically wore but could not display "
                .. tostring(entry.fullType) .. ": " .. tostring(visualReason))
            return 1, 1, visualChanged
        end
    end
    return 1, 0, visualChanged
end

local function applyWornEntry(zombie, equipment, record, entry)
    local item, createReason = Equipment.CreateItem(entry.fullType)
    if item then
        return applyCreatedWornItem(zombie, equipment, record, entry, item)
    end
    local visualOk, visualReason = addVisualFallback(zombie, entry, nil)
    if visualOk then
        Core.LogWarn("PNC equipment displayed visual-only worn item "
            .. tostring(entry.fullType) .. ": " .. tostring(createReason))
        return 1, 0, false
    end
    Core.LogWarn("PNC equipment could not create or display worn item "
        .. tostring(entry.fullType) .. ": create="
        .. tostring(createReason) .. ", visual=" .. tostring(visualReason))
    return 0, 1, false
end

function Internal.applyWornItems(zombie, equipment, record)
    local entries = Equipment.GetOrderedWornEntries(equipment)
    local appliedCount = 0
    local failureCount = 0
    local visualStateChanged = false
    if #entries <= 0 then
        Internal.clearExplicitWornItems(zombie)
        return true, "worn:none"
    end

    Internal.clearExplicitWornItems(zombie)
    for i = 1, #entries do
        local applied, failed, changed = applyWornEntry(
            zombie,
            equipment,
            record,
            entries[i]
        )
        appliedCount = appliedCount + applied
        failureCount = failureCount + failed
        visualStateChanged = visualStateChanged or changed
    end
    if visualStateChanged
        and PNC.Registry
        and PNC.Registry.MarkDirty
    then
        PNC.Registry.MarkDirty(record, "equipment_visuals")
    end
    if failureCount > 0 then
        return false, "worn:applied=" .. tostring(appliedCount)
            .. ",failed=" .. tostring(failureCount)
    end
    return true, "worn:" .. tostring(appliedCount)
end
