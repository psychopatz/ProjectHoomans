PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Internal = PNC.Equipment.Internal or {}

local Equipment = PNC.Equipment
local Internal = Equipment.Internal
local Core = PNC.Core
local Visuals = PNC.Visuals
local Inventory = PNC.Inventory

function Internal.isNetworkedGame()
    return (isClient and isClient() == true)
        or (isServer and isServer() == true)
end

function Internal.isClientOnlyGame()
    return isClient and isClient() == true
        and (not isServer or isServer() ~= true)
end

function Internal.copyDescriptor(source, item, createReason)
    return {
        fullType = source and source.fullType or nil,
        primaryType = source and source.primaryType or "barehand",
        resolvedMode = source and source.resolvedMode or "melee",
        hasWeapon = source and source.hasWeapon == true or false,
        hasUsableFirearm = source and source.hasUsableFirearm == true or false,
        weaponStatus = source and source.weaponStatus or "barehand",
        createReason = createReason or source and source.createReason or "unknown",
        item = item,
    }
end

function Internal.buildWeaponDescriptor(fullType, includeItem)
    local item
    local primaryType
    local createReason
    local cached
    if not fullType or fullType == "" then
        return {
            fullType = nil,
            primaryType = "barehand",
            resolvedMode = "melee",
            hasWeapon = false,
            hasUsableFirearm = false,
            weaponStatus = "barehand",
            item = nil,
        }
    end

    cached = Equipment.DescriptorCache[fullType]
    if cached and includeItem ~= true then
        return Internal.copyDescriptor(cached, nil, cached.createReason)
    end
    if cached and includeItem == true then
        item, createReason = Equipment.CreateItem(fullType)
        if not item then
            return {
                fullType = fullType,
                primaryType = "barehand",
                resolvedMode = "melee",
                hasWeapon = false,
                hasUsableFirearm = false,
                weaponStatus = createReason or "invalid_full_type",
                createReason = createReason or "invalid_full_type",
                item = nil,
            }
        end
        return Internal.copyDescriptor(cached, item, createReason or cached.createReason)
    end

    item, createReason = Equipment.CreateItem(fullType)
    if not item then
        return {
            fullType = fullType,
            primaryType = "barehand",
            resolvedMode = "melee",
            hasWeapon = false,
            hasUsableFirearm = false,
            weaponStatus = createReason or "invalid_full_type",
            createReason = createReason or "invalid_full_type",
            item = nil,
        }
    end

    primaryType = Internal.resolvePrimaryType(item)
    cached = {
        fullType = fullType,
        primaryType = primaryType,
        resolvedMode = Internal.resolveModeFromPrimaryType(primaryType),
        hasWeapon = item.IsWeapon and item:IsWeapon() or false,
        hasUsableFirearm = primaryType == "rifle" or primaryType == "handgun",
        weaponStatus = primaryType == "barehand" and "barehand" or ("equipped_" .. tostring(primaryType)),
        createReason = createReason or "unknown",
    }
    Equipment.DescriptorCache[fullType] = cached
    return Internal.copyDescriptor(cached, includeItem == true and item or nil, createReason)
end

function Internal.safeInvoke(target, methodName, ...)
    local method
    if not target then
        return false, "missing_target"
    end
    method = target[methodName]
    if type(method) ~= "function" then
        return false, "missing_method:" .. tostring(methodName)
    end
    return pcall(method, target, ...)
end

function Internal.setEquipmentVariables(zombie, primaryType, primaryFullType, secondaryFullType)
    if not zombie or not zombie.setVariable then
        return
    end
    zombie:setVariable("PNCPrimary", tostring(primaryFullType or ""))
    zombie:setVariable("PNCSecondary", tostring(secondaryFullType or ""))
    zombie:setVariable("PNCPrimaryType", tostring(primaryType or "barehand"))
end

function Internal.refreshHands(zombie)
    if not zombie then
        return
    end
    if zombie.resetEquippedHandsModels then
        zombie:resetEquippedHandsModels()
    end
end

function Internal.clearHands(zombie)
    if not zombie then
        return
    end
    if zombie.setPrimaryHandItem then
        pcall(function()
            zombie:setPrimaryHandItem(nil)
        end)
    end
    if zombie.setSecondaryHandItem then
        pcall(function()
            zombie:setSecondaryHandItem(nil)
        end)
    end
    Internal.refreshHands(zombie)
end

function Internal.getPrimaryHandItem(zombie)
    local ok
    local item
    if not zombie or type(zombie.getPrimaryHandItem) ~= "function" then
        return nil, false
    end
    ok, item = pcall(zombie.getPrimaryHandItem, zombie)
    if not ok then
        return nil, false
    end
    return item, true
end

function Internal.isPrimaryHandStateCurrent(zombie, descriptor, attackMode)
    local item
    local readable
    local ok
    local fullType
    item, readable = Internal.getPrimaryHandItem(zombie)
    if not readable then
        return nil
    end
    if attackMode ~= true or not descriptor or not descriptor.fullType
        or descriptor.hasWeapon ~= true
    then
        return item == nil
    end
    if not item then
        return false
    end
    if type(item.getFullType) ~= "function" then
        -- A present hand item is the strongest comparison available for
        -- lightweight test doubles and unusual modded InventoryItems.
        return true
    end
    ok, fullType = pcall(item.getFullType, item)
    if not ok or fullType == nil then
        return true
    end
    return tostring(fullType) == tostring(descriptor.fullType)
end
