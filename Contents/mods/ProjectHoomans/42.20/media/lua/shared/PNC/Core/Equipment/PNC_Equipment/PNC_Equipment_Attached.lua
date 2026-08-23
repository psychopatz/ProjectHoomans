PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Internal = PNC.Equipment.Internal or {}

local Equipment = PNC.Equipment
local Internal = Equipment.Internal
local Core = PNC.Core
local Visuals = PNC.Visuals
local Inventory = PNC.Inventory

function Internal.applyAttachedItems(
    zombie,
    equipment,
    implicitHolsterFullType,
    activeHandFullType
)
    local entries = Equipment.GetOrderedAttachedEntries(equipment)
    local appliedCount = 0
    local failureCount = 0
    local occupiedLocations = {}
    local alreadyAttached = false
    local i
    local entry
    local item
    local createReason
    local ok
    local errorMessage

    Visuals.ClearAttachedItems(zombie)

    if #entries <= 0 and not implicitHolsterFullType then
        return true, "attached:none"
    end

    for i = 1, #entries do
        entry = entries[i]
        -- A weapon can remain in the synchronized attached-slot map while it
        -- is actively held. Do not render the same item on the back and in the
        -- hand at once; the hand presentation owns it until combat ends.
        if not activeHandFullType
            or entry.fullType ~= activeHandFullType
        then
            occupiedLocations[entry.location] = true
            if implicitHolsterFullType
                and entry.fullType == implicitHolsterFullType
            then
                alreadyAttached = true
            end
            item, createReason = Equipment.CreateItem(entry.fullType)
            if item then
                if entry.fullType == equipment.primaryFullType
                    and equipment.primaryVisual
                then
                    Internal.applyItemVisualState(
                        item,
                        equipment.primaryVisual
                    )
                end
                ok, errorMessage = Internal.safeInvoke(
                    zombie,
                    "setAttachedItem",
                    entry.location,
                    item
                )
                if ok then
                    if item.setAttachedToModel then
                        item:setAttachedToModel(entry.location)
                    end
                    if item.setAttachedSlotType and entry.slotType then
                        item:setAttachedSlotType(entry.slotType)
                    end
                    appliedCount = appliedCount + 1
                else
                    failureCount = failureCount + 1
                    Core.LogWarn("PNC equipment failed to attach " .. tostring(entry.fullType) .. " at " .. tostring(entry.location) .. ": " .. tostring(errorMessage))
                end
            else
                failureCount = failureCount + 1
                Core.LogWarn("PNC equipment could not create attached item " .. tostring(entry.fullType) .. ": " .. tostring(createReason))
            end
        end
    end

    if implicitHolsterFullType and not alreadyAttached then
        local holsterLocation
        local holsterSlotType
        item, createReason = Equipment.CreateItem(implicitHolsterFullType)
        if item then
            if equipment.primaryVisual then
                Internal.applyItemVisualState(
                    item,
                    equipment.primaryVisual
                )
            end
            holsterLocation, holsterSlotType = Equipment.ResolveAttachedLocation(
                item,
                nil,
                occupiedLocations
            )
            if holsterLocation then
                ok, errorMessage = Internal.safeInvoke(zombie, "setAttachedItem", holsterLocation, item)
                if ok then
                    if item.setAttachedToModel then
                        item:setAttachedToModel(holsterLocation)
                    end
                    if item.setAttachedSlotType and holsterSlotType then
                        item:setAttachedSlotType(holsterSlotType)
                    end
                    appliedCount = appliedCount + 1
                else
                    failureCount = failureCount + 1
                    Core.LogWarn("PNC equipment failed to holster "
                        .. tostring(implicitHolsterFullType) .. " at "
                        .. tostring(holsterLocation) .. ": " .. tostring(errorMessage))
                end
            end
        end
    end

    if failureCount > 0 then
        return false, "attached:applied=" .. tostring(appliedCount) .. ",failed=" .. tostring(failureCount)
    end
    return true, "attached:" .. tostring(appliedCount)
end
