PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Internal = PNC.Equipment.Internal or {}

local Equipment = PNC.Equipment
local Internal = Equipment.Internal
local Core = PNC.Core
local Visuals = PNC.Visuals
local Inventory = PNC.Inventory

function Internal.isAttackMode(record)
    local runtime = record and record.runtime or nil
    if runtime and runtime.target ~= nil then
        return true
    end
    return runtime and runtime.attackMode == true or false
end

function Internal.applyHands(zombie, record, equipment, descriptor, attackMode)
    local item
    local primaryType
    local secondaryItem
    local secondaryReason
    local secondaryFullType
    local ok
    local errorMessage

    Internal.clearHands(zombie)

    if not descriptor.fullType then
        Internal.setEquipmentVariables(zombie, "barehand", nil, nil)
        return true, descriptor.weaponStatus
    end

    item = descriptor.item
    if not item then
        Internal.setEquipmentVariables(zombie, "barehand", nil, nil)
        return false, descriptor.weaponStatus
    end

    Internal.applyPrimaryInventoryState(item, record)

    if attackMode ~= true then
        Internal.setEquipmentVariables(
            zombie,
            descriptor.primaryType,
            descriptor.fullType,
            equipment.secondaryFullType
        )
        return true, descriptor.weaponStatus .. ":holstered"
    end

    primaryType = descriptor.primaryType
    ok, errorMessage = Internal.safeInvoke(zombie, "setPrimaryHandItem", item)
    if not ok then
        Internal.setEquipmentVariables(zombie, "barehand", nil, nil)
        return false, "primary_equip_failed:" .. tostring(errorMessage)
    end

    if item.isRequiresEquippedBothHands and item:isRequiresEquippedBothHands() then
        ok, errorMessage = Internal.safeInvoke(zombie, "setSecondaryHandItem", item)
        if not ok then
            Internal.setEquipmentVariables(zombie, primaryType, descriptor.fullType, nil)
            Internal.refreshHands(zombie)
            return false, "secondary_both_hands_failed:" .. tostring(errorMessage)
        end
    else
        secondaryFullType = equipment.secondaryFullType
        if secondaryFullType and secondaryFullType ~= descriptor.fullType then
            secondaryItem, secondaryReason = Equipment.CreateItem(secondaryFullType)
            if secondaryItem then
                ok, errorMessage = Internal.safeInvoke(zombie, "setSecondaryHandItem", secondaryItem)
                if not ok then
                    secondaryFullType = nil
                    Core.LogWarn("PNC equipment failed to equip secondary " .. tostring(equipment.secondaryFullType) .. ": " .. tostring(errorMessage))
                end
            else
                secondaryFullType = nil
                Core.LogWarn("PNC equipment could not create secondary " .. tostring(equipment.secondaryFullType) .. ": " .. tostring(secondaryReason))
            end
        end
    end

    Internal.setEquipmentVariables(zombie, primaryType, descriptor.fullType, secondaryFullType)
    Internal.refreshHands(zombie)
    return true, descriptor.weaponStatus .. ":" .. tostring(descriptor.createReason or "unknown")
end

function Internal.applyCombatPresentation(zombie, record, equipment, descriptor, attackMode)
    local attachedOk
    local attachedReason
    local handsOk
    local handsReason
    local holsterFullType

    if attackMode ~= true then
        holsterFullType = descriptor.fullType
    end
    if descriptor.item then
        -- Establish the inventory-owned variant before a separate holster
        -- presentation item is constructed below.
        Internal.applyPrimaryInventoryState(descriptor.item, record)
    end
    attachedOk, attachedReason = Internal.applyAttachedItems(
        zombie,
        equipment,
        holsterFullType,
        attackMode == true and descriptor.fullType or nil
    )
    handsOk, handsReason = Internal.applyHands(zombie, record, equipment, descriptor, attackMode)

    record.runtime = record.runtime or {}
    record.runtime.equipmentAttackModeApplied = attackMode == true
    record.runtime.equipmentPresentationRevision = Equipment.PRESENTATION_REVISION
    return attachedOk and handsOk, attachedReason, handsReason
end

function Internal.resolvePrimaryType(item)
    local weaponType
    if not item or not item.IsWeapon or not item:IsWeapon() or not WeaponType or not WeaponType.getWeaponType then
        return "barehand"
    end
    weaponType = WeaponType.getWeaponType(item)
    if weaponType == WeaponType.FIREARM then
        return "rifle"
    end
    if weaponType == WeaponType.HANDGUN then
        return "handgun"
    end
    if weaponType == WeaponType.SPEAR then
        return "spear"
    end
    if weaponType == WeaponType.HEAVY or weaponType == WeaponType.TWO_HANDED then
        return "twohanded"
    end
    if weaponType == WeaponType.ONE_HANDED then
        return "onehanded"
    end
    return "barehand"
end

function Internal.resolveModeFromPrimaryType(primaryType)
    if primaryType == "rifle" or primaryType == "handgun" then
        return "ranged"
    end
    if primaryType == "twohanded" or primaryType == "onehanded" or primaryType == "spear" then
        return "melee"
    end
    return "melee"
end
