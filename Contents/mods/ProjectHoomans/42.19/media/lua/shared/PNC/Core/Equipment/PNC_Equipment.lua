PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}

local Equipment = PNC.Equipment
local Core = PNC.Core
local Visuals = PNC.Visuals
local resolvePrimaryType
local resolveModeFromPrimaryType

Equipment.DescriptorCache = Equipment.DescriptorCache or {}

local function copyDescriptor(source, item, createReason)
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

local function buildWeaponDescriptor(fullType, includeItem)
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
        return copyDescriptor(cached, nil, cached.createReason)
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
        return copyDescriptor(cached, item, createReason or cached.createReason)
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

    primaryType = resolvePrimaryType(item)
    cached = {
        fullType = fullType,
        primaryType = primaryType,
        resolvedMode = resolveModeFromPrimaryType(primaryType),
        hasWeapon = item.IsWeapon and item:IsWeapon() or false,
        hasUsableFirearm = primaryType == "rifle" or primaryType == "handgun",
        weaponStatus = primaryType == "barehand" and "barehand" or ("equipped_" .. tostring(primaryType)),
        createReason = createReason or "unknown",
    }
    Equipment.DescriptorCache[fullType] = cached
    return copyDescriptor(cached, includeItem == true and item or nil, createReason)
end

local function safeInvoke(target, methodName, ...)
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

local function setEquipmentVariables(zombie, primaryType, primaryFullType, secondaryFullType)
    if not zombie or not zombie.setVariable then
        return
    end
    zombie:setVariable("PNCPrimary", tostring(primaryFullType or ""))
    zombie:setVariable("PNCSecondary", tostring(secondaryFullType or ""))
    zombie:setVariable("PNCPrimaryType", tostring(primaryType or "barehand"))
end

local function refreshHands(zombie)
    if not zombie then
        return
    end
    if zombie.resetEquippedHandsModels then
        zombie:resetEquippedHandsModels()
    end
end

local function clearHands(zombie)
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
    refreshHands(zombie)
end

local function clearExplicitWornItems(zombie)
    local wornItems
    local itemVisuals
    if not zombie then
        return
    end
    wornItems = zombie.getWornItems and zombie:getWornItems() or nil
    itemVisuals = zombie.getItemVisuals and zombie:getItemVisuals() or nil
    if wornItems and wornItems.clear then
        wornItems:clear()
    end
    if itemVisuals and itemVisuals.clear then
        itemVisuals:clear()
    end
end

local function applyWornItems(zombie, equipment)
    local entries = Equipment.GetOrderedWornEntries(equipment)
    local appliedCount = 0
    local failureCount = 0
    local i
    local entry
    local item
    local createReason
    local ok
    local errorMessage

    if #entries <= 0 then
        clearExplicitWornItems(zombie)
        return true, "worn:none"
    end

    clearExplicitWornItems(zombie)

    for i = 1, #entries do
        entry = entries[i]
        ok, errorMessage = Visuals.AddClothingVisual(zombie, entry.fullType)
        if ok then
            appliedCount = appliedCount + 1
        else
            item, createReason = Equipment.CreateItem(entry.fullType)
            if item then
                ok, errorMessage = safeInvoke(zombie, "setWornItem", entry.bodyLocation, item)
                if not ok then
                    failureCount = failureCount + 1
                    Core.LogWarn("PNC equipment failed to wear " .. tostring(entry.fullType) .. " on " .. tostring(entry.bodyLocation) .. ": " .. tostring(errorMessage))
                else
                    appliedCount = appliedCount + 1
                end
            else
                failureCount = failureCount + 1
                Core.LogWarn("PNC equipment could not create worn item " .. tostring(entry.fullType) .. ": " .. tostring(createReason))
            end
        end
    end

    if failureCount > 0 then
        return false, "worn:applied=" .. tostring(appliedCount) .. ",failed=" .. tostring(failureCount)
    end
    return true, "worn:" .. tostring(appliedCount)
end

local function applyAttachedItems(zombie, equipment)
    local entries = Equipment.GetOrderedAttachedEntries(equipment)
    local appliedCount = 0
    local failureCount = 0
    local i
    local entry
    local item
    local createReason
    local ok
    local errorMessage

    Visuals.ClearAttachedItems(zombie)

    if #entries <= 0 then
        return true, "attached:none"
    end

    for i = 1, #entries do
        entry = entries[i]
        item, createReason = Equipment.CreateItem(entry.fullType)
        if item then
            ok, errorMessage = safeInvoke(zombie, "setAttachedItem", entry.location, item)
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

    if failureCount > 0 then
        return false, "attached:applied=" .. tostring(appliedCount) .. ",failed=" .. tostring(failureCount)
    end
    return true, "attached:" .. tostring(appliedCount)
end

local function isAttackMode(record)
    local runtime = record and record.runtime or nil
    if runtime and runtime.target ~= nil then
        return true
    end
    return runtime and runtime.attackMode == true or false
end

local function buildPresentationEquipment(equipment, attackMode)
    local presentation = Equipment.NormalizeLoadoutSpec(equipment)
    local occupied = {}
    local fullTypes
    local location
    local fullType
    local item
    local createReason
    local i
    local holsteredCount = 0
    local holsterReasons = {}

    if attackMode then
        return presentation, 0, {}
    end

    for location, _ in pairs(presentation.attached) do
        occupied[location] = true
    end

    fullTypes = {}
    if presentation.primaryFullType then
        fullTypes[#fullTypes + 1] = presentation.primaryFullType
    end
    if presentation.secondaryFullType then
        fullTypes[#fullTypes + 1] = presentation.secondaryFullType
    end
    for i = 1, #fullTypes do
        fullType = fullTypes[i]
        if fullType then
            item, createReason = Equipment.CreateItem(fullType)
            if item then
                location = Equipment.ResolveAttachedLocation(item, nil, occupied)
                if location then
                    presentation.attached[location] = fullType
                    occupied[location] = true
                    holsteredCount = holsteredCount + 1
                else
                    holsterReasons[#holsterReasons + 1] = tostring(fullType) .. ":no_attachment_location"
                end
            else
                holsterReasons[#holsterReasons + 1] = tostring(fullType) .. ":" .. tostring(createReason or "invalid_full_type")
            end
        end
    end
    return presentation, holsteredCount, holsterReasons
end

local function applyHands(zombie, equipment, descriptor)
    local item
    local primaryType
    local secondaryItem
    local secondaryReason
    local secondaryFullType
    local ok
    local errorMessage

    clearHands(zombie)

    if not descriptor.fullType then
        setEquipmentVariables(zombie, "barehand", nil, nil)
        return true, descriptor.weaponStatus
    end

    item = descriptor.item
    if not item then
        setEquipmentVariables(zombie, "barehand", nil, nil)
        return false, descriptor.weaponStatus
    end

    primaryType = descriptor.primaryType
    ok, errorMessage = safeInvoke(zombie, "setPrimaryHandItem", item)
    if not ok then
        setEquipmentVariables(zombie, "barehand", nil, nil)
        return false, "primary_equip_failed:" .. tostring(errorMessage)
    end

    if item.isRequiresEquippedBothHands and item:isRequiresEquippedBothHands() then
        ok, errorMessage = safeInvoke(zombie, "setSecondaryHandItem", item)
        if not ok then
            setEquipmentVariables(zombie, primaryType, descriptor.fullType, nil)
            refreshHands(zombie)
            return false, "secondary_both_hands_failed:" .. tostring(errorMessage)
        end
    else
        secondaryFullType = equipment.secondaryFullType
        if secondaryFullType and secondaryFullType ~= descriptor.fullType then
            secondaryItem, secondaryReason = Equipment.CreateItem(secondaryFullType)
            if secondaryItem then
                ok, errorMessage = safeInvoke(zombie, "setSecondaryHandItem", secondaryItem)
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

    setEquipmentVariables(zombie, primaryType, descriptor.fullType, secondaryFullType)
    refreshHands(zombie)
    return true, descriptor.weaponStatus .. ":" .. tostring(descriptor.createReason or "unknown")
end

local function applyCombatPresentation(zombie, record, equipment, descriptor, attackMode)
    local presentation
    local holsteredCount
    local holsterReasons
    local attachedOk
    local attachedReason
    local handsOk
    local handsReason

    presentation, holsteredCount, holsterReasons = buildPresentationEquipment(equipment, attackMode)
    attachedOk, attachedReason = applyAttachedItems(zombie, presentation)

    if attackMode then
        handsOk, handsReason = applyHands(zombie, equipment, descriptor)
    else
        clearHands(zombie)
        setEquipmentVariables(zombie, "barehand", nil, nil)
        handsOk = true
        handsReason = "holstered:" .. tostring(holsteredCount)
        if #holsterReasons > 0 then
            handsOk = false
            handsReason = handsReason .. ",unavailable=" .. table.concat(holsterReasons, ",")
        end
    end

    record.runtime = record.runtime or {}
    record.runtime.equipmentAttackModeApplied = attackMode == true
    return attachedOk and handsOk, attachedReason, handsReason
end

resolvePrimaryType = function(item)
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

resolveModeFromPrimaryType = function(primaryType)
    if primaryType == "rifle" or primaryType == "handgun" then
        return "ranged"
    end
    if primaryType == "twohanded" or primaryType == "onehanded" or primaryType == "spear" then
        return "melee"
    end
    return "melee"
end

function Equipment.Apply(zombie, record)
    local equipment
    local descriptor
    local ok = true
    local laneOk
    local handsReason
    local reasons = {}

    if not zombie or not record then
        return false, "missing_body_or_record"
    end

    equipment = Equipment.EnsureRecordEquipment(record)
    descriptor = buildWeaponDescriptor(equipment.primaryFullType, true)

    laneOk, reasons[#reasons + 1] = applyWornItems(zombie, equipment)
    if not laneOk then
        ok = false
    end

    laneOk, reasons[#reasons + 1], handsReason = applyCombatPresentation(
        zombie,
        record,
        equipment,
        descriptor,
        isAttackMode(record)
    )
    reasons[#reasons + 1] = handsReason
    if not laneOk then
        ok = false
    end

    Visuals.RefreshModel(zombie)
    return ok, table.concat(reasons, "|")
end

function Equipment.ApplyHands(zombie, record)
    local equipment
    local descriptor
    local ok
    local reason

    if not zombie or not record then
        return false, "missing_body_or_record"
    end

    if not isAttackMode(record) then
        return Equipment.ApplyCombatState(zombie, record, false, true)
    end

    equipment = Equipment.EnsureRecordEquipment(record)
    descriptor = buildWeaponDescriptor(equipment.primaryFullType, true)
    ok, reason = applyHands(zombie, equipment, descriptor)
    return ok, reason
end

function Equipment.IsAttackMode(record)
    return isAttackMode(record)
end

function Equipment.ApplyCombatState(zombie, record, attackMode, force)
    local equipment
    local descriptor
    local ok
    local attachedReason
    local handsReason

    if not zombie or not record then
        return false, "missing_body_or_record"
    end
    record.runtime = record.runtime or {}
    attackMode = attackMode == true
    if force ~= true and record.runtime.equipmentAttackModeApplied == attackMode then
        return true, "unchanged"
    end

    equipment = Equipment.EnsureRecordEquipment(record)
    descriptor = buildWeaponDescriptor(equipment.primaryFullType, true)
    ok, attachedReason, handsReason = applyCombatPresentation(zombie, record, equipment, descriptor, attackMode)
    Visuals.RefreshModel(zombie)
    return ok, tostring(attachedReason) .. "|" .. tostring(handsReason)
end

function Equipment.ResolveWeaponMode(fullType)
    return buildWeaponDescriptor(fullType, false).resolvedMode
end

function Equipment.Describe(record)
    local configuredMode
    local fullType
    local descriptor
    local combatModeResolved
    local weaponStatus
    local runtime
    local cacheKey
    local cached
    local result

    configuredMode = tostring(record and record.weaponMode or "melee")
    fullType = record and record.equipment and record.equipment.primaryFullType or nil
    runtime = record and (record.runtime or {}) or nil
    if record then
        record.runtime = runtime
    end
    cacheKey = configuredMode .. "|" .. tostring(fullType or "")
    cached = runtime and runtime.equipmentDescribeCache or nil
    if cached and cached.key == cacheKey and cached.value then
        return cached.value
    end

    descriptor = buildWeaponDescriptor(fullType, false)
    combatModeResolved = configuredMode
    weaponStatus = descriptor.weaponStatus

    if configuredMode == "ranged" then
        if descriptor.hasUsableFirearm then
            combatModeResolved = "ranged"
            weaponStatus = "ranged_ready"
        else
            combatModeResolved = "melee"
            if descriptor.weaponStatus ~= "barehand" and descriptor.hasWeapon ~= true and descriptor.fullType then
                weaponStatus = descriptor.weaponStatus .. "_fallback_melee"
            elseif descriptor.fullType and descriptor.hasWeapon then
                weaponStatus = "ranged_missing_firearm_fallback_melee"
            else
                weaponStatus = "ranged_unarmed_fallback_melee"
            end
        end
    elseif configuredMode == "mixed" then
        if descriptor.hasUsableFirearm then
            combatModeResolved = "mixed"
            weaponStatus = "mixed_ranged_ready"
        elseif descriptor.weaponStatus ~= "barehand" and descriptor.hasWeapon ~= true and descriptor.fullType then
            combatModeResolved = "melee"
            weaponStatus = descriptor.weaponStatus .. "_fallback_melee"
        elseif descriptor.hasWeapon then
            combatModeResolved = "melee"
            weaponStatus = "mixed_melee_only"
        else
            combatModeResolved = "melee"
            weaponStatus = "mixed_unarmed_fallback_melee"
        end
    elseif configuredMode == "melee" then
        combatModeResolved = "melee"
        if descriptor.hasWeapon then
            weaponStatus = "melee_ready"
        else
            weaponStatus = "melee_unarmed"
        end
    end

    result = {
        configuredMode = configuredMode,
        combatModeResolved = combatModeResolved,
        weaponStatus = weaponStatus,
        primaryType = descriptor.primaryType,
        hasWeapon = descriptor.hasWeapon,
        hasUsableFirearm = descriptor.hasUsableFirearm,
        fullType = descriptor.fullType,
    }
    if runtime then
        runtime.equipmentDescribeCache = {
            key = cacheKey,
            value = result,
        }
    end
    return result
end
