PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}

local Equipment = PNC.Equipment
local Core = PNC.Core
local Visuals = PNC.Visuals
local Inventory = PNC.Inventory
local resolvePrimaryType
local resolveModeFromPrimaryType

Equipment.DescriptorCache = Equipment.DescriptorCache or {}
Equipment.PRESENTATION_REVISION = 3

local function isNetworkedGame()
    return (isClient and isClient() == true)
        or (isServer and isServer() == true)
end

local function isClientOnlyGame()
    return isClient and isClient() == true
        and (not isServer or isServer() ~= true)
end

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

local function getPrimaryHandItem(zombie)
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

local function isPrimaryHandStateCurrent(zombie, descriptor, attackMode)
    local item
    local readable
    local ok
    local fullType
    item, readable = getPrimaryHandItem(zombie)
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

local function hasClothingVisual(zombie, fullType)
    local visuals = zombie and zombie.getItemVisuals
        and zombie:getItemVisuals() or nil
    local visual
    local visualType
    local i
    if not visuals or not visuals.size or not visuals.get then return false end
    for i = 0, visuals:size() - 1 do
        visual = visuals:get(i)
        visualType = visual and visual.getItemType
            and visual:getItemType() or nil
        if (visualType == nil or visualType == "")
            and visual and visual.getClothingItemName
        then
            visualType = visual:getClothingItemName()
        end
        if tostring(visualType or "") == tostring(fullType or "") then
            return true
        end
    end
    return false
end

local function getWornInventoryItem(record, bodyLocation)
    local inventory = record and record.inventory or nil
    local itemID = inventory and inventory.worn
        and inventory.worn[bodyLocation] or nil
    return itemID and inventory.items and inventory.items[itemID] or nil
end

local function applyInventoryState(item, record, bodyLocation)
    local inventory = record and record.inventory or nil
    local itemID = inventory and inventory.worn and inventory.worn[bodyLocation] or nil
    local state = itemID and inventory.items and inventory.items[itemID] or nil
    local maximum
    if not item or not state then return item end
    maximum = item.getConditionMax and tonumber(item:getConditionMax()) or 0
    if state.cond ~= nil and item.setCondition then
        item:setCondition(math.max(0, math.min(maximum > 0 and maximum or tonumber(state.cond), tonumber(state.cond) or 0)))
    end
    if state.uses ~= nil and item.setUses then
        item:setUses(math.max(0, tonumber(state.uses) or 0))
    end
    return item
end

local function applyItemVisualState(item, visualState)
    local visual
    local applied = false
    if not item or type(visualState) ~= "table" then
        return false
    end
    if visualState.modelIndex ~= nil
        and item.setModelIndex
    then
        item:setModelIndex(
            math.floor(tonumber(visualState.modelIndex) or -1)
        )
        applied = true
    end
    if visualState.color then
        if item.setColorRed then
            item:setColorRed(tonumber(visualState.color.r) or 1)
            applied = true
        end
        if item.setColorGreen then
            item:setColorGreen(tonumber(visualState.color.g) or 1)
            applied = true
        end
        if item.setColorBlue then
            item:setColorBlue(tonumber(visualState.color.b) or 1)
            applied = true
        end
        if item.setCustomColor then
            item:setCustomColor(visualState.customColor == true)
        end
    end
    visual = item.getVisual and item:getVisual() or nil
    if not visual then return applied end
    if visualState.baseTexture ~= nil
        and visual.setBaseTexture
    then
        visual:setBaseTexture(
            tonumber(visualState.baseTexture) or -1
        )
    end
    if visualState.textureChoice ~= nil
        and visual.setTextureChoice
    then
        visual:setTextureChoice(
            tonumber(visualState.textureChoice) or -1
        )
    end
    if visualState.decal ~= nil and visual.setDecal then
        visual:setDecal(tostring(visualState.decal))
    end
    if visualState.tint
        and ImmutableColor
        and visual.setTint
    then
        visual:setTint(ImmutableColor.new(
            tonumber(visualState.tint.r) or 1,
            tonumber(visualState.tint.g) or 1,
            tonumber(visualState.tint.b) or 1,
            1
        ))
    end
    return true
end

local function visualStateSignature(state)
    local tint = state and state.tint or {}
    local color = state and state.color or {}
    return table.concat({
        tostring(state and state.fullType or ""),
        tostring(state and state.baseTexture or ""),
        tostring(state and state.textureChoice or ""),
        tostring(state and state.decal or ""),
        tostring(tint.r or ""),
        tostring(tint.g or ""),
        tostring(tint.b or ""),
        tostring(state and state.modelIndex or ""),
        tostring(state and state.customColor == true),
        tostring(color.r or ""),
        tostring(color.g or ""),
        tostring(color.b or ""),
    }, ":")
end

local function applyPrimaryInventoryState(item, record)
    local inventory = record and record.inventory or nil
    local itemID = inventory and inventory.equipped and inventory.equipped.primary or nil
    local state = itemID and inventory.items and inventory.items[itemID] or nil
    local equipment = record
        and Equipment.EnsureRecordEquipment(record) or nil
    local storedVisual = state
        and Equipment.VisualStateFromItemState
        and Equipment.VisualStateFromItemState(
            state.itemState,
            state.type
        ) or equipment and equipment.primaryVisual or nil
    local capturedVisual
    local visualChanged = false
    local maximum
    if not item then return item end
    if storedVisual then
        applyItemVisualState(item, storedVisual)
    end
    capturedVisual = Equipment.CaptureItemVisualState
        and Equipment.CaptureItemVisualState(
            item,
            equipment and equipment.primaryFullType or nil
        ) or nil
    if capturedVisual and state
        and Equipment.StoreVisualStateInItemState
        and visualStateSignature(storedVisual)
            ~= visualStateSignature(capturedVisual)
    then
        Equipment.StoreVisualStateInItemState(
            state,
            capturedVisual
        )
        visualChanged = true
    end
    if capturedVisual and equipment
        and visualStateSignature(equipment.primaryVisual)
            ~= visualStateSignature(capturedVisual)
    then
        equipment.primaryVisual = capturedVisual
        visualChanged = true
    end
    if visualChanged
        and PNC.Registry
        and PNC.Registry.MarkDirty
    then
        PNC.Registry.MarkDirty(record, "equipment_visuals")
    end
    if not state then return item end
    maximum = item.getConditionMax and tonumber(item:getConditionMax()) or 0
    if state.cond ~= nil and item.setCondition then
        item:setCondition(math.max(0, math.min(
            maximum > 0 and maximum or tonumber(state.cond),
            tonumber(state.cond) or 0
        )))
    end
    if state.ammoCount ~= nil and item.setCurrentAmmoCount then
        pcall(item.setCurrentAmmoCount, item, math.max(0, math.floor(tonumber(state.ammoCount) or 0)))
    end
    return item
end

local function applyWornItems(zombie, equipment, record)
    local entries = Equipment.GetOrderedWornEntries(equipment)
    local appliedCount = 0
    local failureCount = 0
    local i
    local entry
    local item
    local createReason
    local typedBodyLocation
    local visualOk
    local visualReason
    local wornOk
    local wornReason
    local storedVisual
    local capturedVisual
    local inventoryItem
    local visualStateChanged = false

    if #entries <= 0 then
        clearExplicitWornItems(zombie)
        return true, "worn:none"
    end

    clearExplicitWornItems(zombie)

    for i = 1, #entries do
        entry = entries[i]
        storedVisual = nil
        capturedVisual = nil
        inventoryItem = nil
        item, createReason = Equipment.CreateItem(entry.fullType)
        if item then
            applyInventoryState(item, record, entry.bodyLocation)
            inventoryItem = getWornInventoryItem(
                record,
                entry.bodyLocation
            )
            storedVisual = inventoryItem
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
            applyItemVisualState(item, storedVisual)
            typedBodyLocation = item.getBodyLocation and item:getBodyLocation() or nil
            if (not typedBodyLocation or tostring(typedBodyLocation) == "")
                and item.canBeEquipped
            then
                typedBodyLocation = item:canBeEquipped()
            end
            if not typedBodyLocation or tostring(typedBodyLocation) == "" then
                typedBodyLocation = entry.bodyLocation
            end
            if typedBodyLocation then
                wornOk, wornReason = safeInvoke(zombie, "setWornItem", typedBodyLocation, item)
            else
                wornOk, wornReason = false, "missing_typed_body_location"
            end
            if wornOk then
                appliedCount = appliedCount + 1
                capturedVisual = Equipment.CaptureItemVisualState
                    and Equipment.CaptureItemVisualState(
                        item,
                        entry.fullType
                    ) or nil
                if capturedVisual and inventoryItem
                    and Equipment.StoreVisualStateInItemState
                    and visualStateSignature(
                        Equipment.VisualStateFromItemState(
                            inventoryItem.itemState,
                            inventoryItem.type
                        )
                    ) ~= visualStateSignature(capturedVisual)
                then
                    Equipment.StoreVisualStateInItemState(
                        inventoryItem,
                        capturedVisual
                    )
                    visualStateChanged = true
                end
                if capturedVisual
                    and visualStateSignature(storedVisual)
                        ~= visualStateSignature(capturedVisual)
                then
                    equipment.wornVisuals[entry.bodyLocation] =
                        capturedVisual
                    visualStateChanged = true
                end
                if not isNetworkedGame()
                    and not hasClothingVisual(
                        zombie,
                        entry.fullType
                    )
                then
                    visualOk, visualReason = Visuals.AddClothingVisual(
                        zombie,
                        entry.fullType,
                        capturedVisual or storedVisual
                    )
                    if not visualOk then
                        failureCount = failureCount + 1
                        Core.LogWarn("PNC equipment mechanically wore but could not display " .. tostring(entry.fullType) .. ": " .. tostring(visualReason))
                    end
                end
            else
                visualOk, visualReason = false, "network_authority_no_visual_fallback"
                if not isNetworkedGame() then
                    visualOk, visualReason = Visuals.AddClothingVisual(
                        zombie,
                        entry.fullType,
                        storedVisual
                    )
                end
                if visualOk then
                    appliedCount = appliedCount + 1
                    Core.LogWarn("PNC equipment displayed but could not mechanically wear " .. tostring(entry.fullType) .. ": " .. tostring(wornReason))
                else
                    failureCount = failureCount + 1
                    Core.LogWarn("PNC equipment failed to wear " .. tostring(entry.fullType) .. " on " .. tostring(entry.bodyLocation) .. ": visual=" .. tostring(visualReason) .. ", worn=" .. tostring(wornReason))
                end
            end
        else
            visualOk, visualReason = false, "network_authority_no_visual_fallback"
            if not isNetworkedGame() then
                visualOk, visualReason = Visuals.AddClothingVisual(
                    zombie,
                    entry.fullType,
                    storedVisual
                )
            end
            if visualOk then
                appliedCount = appliedCount + 1
                Core.LogWarn("PNC equipment displayed visual-only worn item " .. tostring(entry.fullType) .. ": " .. tostring(createReason))
            else
                failureCount = failureCount + 1
                Core.LogWarn("PNC equipment could not create or display worn item " .. tostring(entry.fullType) .. ": create=" .. tostring(createReason) .. ", visual=" .. tostring(visualReason))
            end
        end
    end

    if visualStateChanged
        and PNC.Registry
        and PNC.Registry.MarkDirty
    then
        PNC.Registry.MarkDirty(record, "equipment_visuals")
    end

    if failureCount > 0 then
        return false, "worn:applied=" .. tostring(appliedCount) .. ",failed=" .. tostring(failureCount)
    end
    return true, "worn:" .. tostring(appliedCount)
end

local function applyAttachedItems(
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
                    applyItemVisualState(
                        item,
                        equipment.primaryVisual
                    )
                end
                ok, errorMessage = safeInvoke(
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
                applyItemVisualState(
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
                ok, errorMessage = safeInvoke(zombie, "setAttachedItem", holsterLocation, item)
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

local function isAttackMode(record)
    local runtime = record and record.runtime or nil
    if runtime and runtime.target ~= nil then
        return true
    end
    return runtime and runtime.attackMode == true or false
end

local function applyHands(zombie, record, equipment, descriptor, attackMode)
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

    applyPrimaryInventoryState(item, record)

    if attackMode ~= true then
        setEquipmentVariables(
            zombie,
            descriptor.primaryType,
            descriptor.fullType,
            equipment.secondaryFullType
        )
        return true, descriptor.weaponStatus .. ":holstered"
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
        applyPrimaryInventoryState(descriptor.item, record)
    end
    attachedOk, attachedReason = applyAttachedItems(
        zombie,
        equipment,
        holsterFullType,
        attackMode == true and descriptor.fullType or nil
    )
    handsOk, handsReason = applyHands(zombie, record, equipment, descriptor, attackMode)

    record.runtime = record.runtime or {}
    record.runtime.equipmentAttackModeApplied = attackMode == true
    record.runtime.equipmentPresentationRevision = Equipment.PRESENTATION_REVISION
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
    if isClientOnlyGame() then
        return Equipment.ApplyReplicaVisuals(zombie, record)
    end

    equipment = Equipment.EnsureRecordEquipment(record)
    if isServer and isServer() == true then
        laneOk, reasons[#reasons + 1] =
            applyWornItems(zombie, equipment, record)
        if not laneOk then ok = false end
        laneOk, reasons[#reasons + 1] =
            Equipment.ApplyReplicaHands(zombie, record)
        if not laneOk then ok = false end
        Visuals.RefreshModel(zombie)
        return ok, table.concat(reasons, "|")
    end
    descriptor = buildWeaponDescriptor(equipment.primaryFullType, true)

    laneOk, reasons[#reasons + 1] = applyWornItems(zombie, equipment, record)
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
    if isNetworkedGame() then
        return Equipment.ApplyReplicaHands(zombie, record)
    end

    equipment = Equipment.EnsureRecordEquipment(record)
    descriptor = buildWeaponDescriptor(equipment.primaryFullType, true)
    ok, _, reason = applyCombatPresentation(
        zombie,
        record,
        equipment,
        descriptor,
        isAttackMode(record)
    )
    Visuals.RefreshModel(zombie)
    return ok, reason
end

-- Remote multiplayer bodies are presentation replicas. Their real worn items
-- remain server-owned. ItemVisuals are repaired only when the synchronized
-- worn set is genuinely absent, mirroring Bandits' appearance latch.
local function getItemVisualType(visual)
    local value
    if not visual then return nil end
    if visual.getItemType then
        value = visual:getItemType()
    end
    if (value == nil or value == "")
        and visual.getClothingItemName
    then
        value = visual:getClothingItemName()
    end
    return value ~= nil and tostring(value) or nil
end

local function replicaPresentationSignature(equipment)
    local entries = Equipment.GetOrderedWornEntries(equipment)
    local wornVisuals = equipment.wornVisuals or {}
    local parts = {}
    local i
    for i = 1, #entries do
        parts[#parts + 1] = table.concat({
            tostring(entries[i].bodyLocation),
            visualStateSignature(
                wornVisuals[entries[i].bodyLocation]
                    or { fullType = entries[i].fullType }
            ),
        }, "=")
    end
    return table.concat(parts, "|")
end

function Equipment.ReplicaVisualsMatch(zombie, record)
    local equipment
    local entries
    local expected = {}
    local visuals
    local i
    local fullType
    if not zombie or not record then return false end
    equipment = Equipment.EnsureRecordEquipment(record)
    entries = Equipment.GetOrderedWornEntries(equipment)
    visuals = zombie.getItemVisuals
        and zombie:getItemVisuals() or nil
    if not visuals or not visuals.size or not visuals.get then
        return false
    end
    if visuals:size() ~= #entries then return false end
    for i = 1, #entries do
        fullType = tostring(entries[i].fullType)
        expected[fullType] = (expected[fullType] or 0) + 1
    end
    for i = 0, visuals:size() - 1 do
        fullType = getItemVisualType(visuals:get(i))
        if fullType and expected[fullType]
            and expected[fullType] > 0
        then
            expected[fullType] = expected[fullType] - 1
        end
    end
    for _, count in pairs(expected) do
        if count > 0 then return false end
    end
    return true
end

function Equipment.ApplyReplicaVisuals(zombie, record)
    local equipment
    local entries
    local wornVisuals
    local visuals
    local applied = 0
    local failed = 0
    local i
    local handsOk
    local handsReason
    local modData
    local desiredSignature
    local signatureCurrent
    if not zombie or not record then
        return false, "missing_body_or_record"
    end
    handsOk, handsReason =
        Equipment.ApplyReplicaHands(zombie, record)
    equipment = Equipment.EnsureRecordEquipment(record)
    desiredSignature = replicaPresentationSignature(equipment)
    modData = zombie.getModData and zombie:getModData() or nil
    signatureCurrent = not modData
        or modData.PNCReplicaVisualSignature == desiredSignature
    if signatureCurrent
        and Equipment.ReplicaVisualsMatch(zombie, record)
    then
        return handsOk,
            handsOk and "replica_current" or handsReason
    end
    entries = Equipment.GetOrderedWornEntries(equipment)
    wornVisuals = equipment.wornVisuals or {}
    visuals = zombie.getItemVisuals
        and zombie:getItemVisuals() or nil
    if not visuals or not visuals.clear then
        return false, "missing_item_visuals"
    end
    visuals:clear()
    for i = 1, #entries do
        if Visuals.AddClothingVisual(
            zombie,
            entries[i].fullType,
            wornVisuals[entries[i].bodyLocation]
        ) then
            applied = applied + 1
        else
            failed = failed + 1
        end
    end
    Visuals.RefreshModel(zombie)
    if failed == 0 and modData then
        modData.PNCReplicaVisualSignature = desiredSignature
    end
    return failed == 0 and handsOk,
        "replica_repaired:applied=" .. tostring(applied)
            .. ",failed=" .. tostring(failed)
end

Equipment.EnsureReplicaVisuals =
    Equipment.ApplyReplicaVisuals

function Equipment.ApplyReplicaHands(zombie, record)
    local equipment
    local descriptor
    local attackMode
    local handStateCurrent
    local attachedEntries
    local signatureParts
    local signature
    local modData
    local ok
    local attachedReason
    local handsReason
    local i
    if not zombie or not record then
        return false, "missing_body_or_record"
    end
    equipment = Equipment.EnsureRecordEquipment(record)
    attackMode = isAttackMode(record)
    descriptor = buildWeaponDescriptor(
        equipment.primaryFullType,
        false
    )
    setEquipmentVariables(
        zombie,
        descriptor.primaryType,
        descriptor.fullType,
        equipment.secondaryFullType
    )

    -- The server remains the authority for inventory and equipped slots. It
    -- publishes only the animation variables here; materializing InventoryItem
    -- instances on the server would compete with normal item packets.
    if isServer and isServer() == true then
        return true, "replica_variables_server"
    end

    if not equipment.primaryVisual
        and equipment.primaryFullType
        and Equipment.BuildPrimaryVisualSummary
    then
        Equipment.BuildPrimaryVisualSummary(record)
        equipment = Equipment.EnsureRecordEquipment(record)
    end

    -- Remote IsoZombie bodies do not receive a usable primary-hand item from
    -- our virtual inventory snapshots. Like Bandits, create that item locally
    -- for presentation. Latch the synchronized state so the update loop does
    -- not clear/recreate hand and attachment models every frame.
    signatureParts = {
        tostring(equipment.primaryFullType or ""),
        visualStateSignature(equipment.primaryVisual),
        tostring(equipment.secondaryFullType or ""),
        attackMode and "attack" or "idle",
    }
    attachedEntries = Equipment.GetOrderedAttachedEntries(equipment)
    for i = 1, #attachedEntries do
        signatureParts[#signatureParts + 1] = table.concat({
            tostring(attachedEntries[i].location or ""),
            tostring(attachedEntries[i].fullType or ""),
            tostring(attachedEntries[i].slotType or ""),
        }, "=")
    end
    signature = table.concat(signatureParts, "|")
    modData = zombie.getModData and zombie:getModData() or nil
    handStateCurrent = isPrimaryHandStateCurrent(
        zombie,
        descriptor,
        attackMode
    )
    if modData
        and modData.PNCReplicaHandsSignature == signature
        and handStateCurrent == true
    then
        return true, "replica_hands_current"
    end

    descriptor = buildWeaponDescriptor(
        equipment.primaryFullType,
        true
    )
    ok, attachedReason, handsReason = applyCombatPresentation(
        zombie,
        record,
        equipment,
        descriptor,
        attackMode
    )
    Visuals.RefreshModel(zombie)
    if ok and modData then
        modData.PNCReplicaHandsSignature = signature
    end
    return ok,
        tostring(attachedReason) .. "|" .. tostring(handsReason)
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
    local handStateCurrent

    if not zombie or not record then
        return false, "missing_body_or_record"
    end
    if isNetworkedGame() then
        return Equipment.ApplyReplicaHands(zombie, record)
    end
    record.runtime = record.runtime or {}
    attackMode = attackMode == true
    equipment = Equipment.EnsureRecordEquipment(record)
    descriptor = buildWeaponDescriptor(equipment.primaryFullType, false)
    handStateCurrent = isPrimaryHandStateCurrent(
        zombie,
        descriptor,
        attackMode
    )
    if force ~= true
        and record.runtime.equipmentAttackModeApplied == attackMode
        and record.runtime.equipmentPresentationRevision == Equipment.PRESENTATION_REVISION
        and handStateCurrent ~= false
    then
        return true, "unchanged"
    end

    descriptor = buildWeaponDescriptor(equipment.primaryFullType, true)
    ok, attachedReason, handsReason = applyCombatPresentation(zombie, record, equipment, descriptor, attackMode)
    Visuals.RefreshModel(zombie)
    return ok, tostring(attachedReason) .. "|" .. tostring(handsReason)
end

function Equipment.EnsureCombatHands(zombie, record)
    local equipment
    local descriptor
    local current
    local ok
    local reason
    if not zombie or not record then
        return false, "missing_body_or_record"
    end
    if isNetworkedGame() then
        return Equipment.ApplyReplicaHands(zombie, record)
    end
    equipment = Equipment.EnsureRecordEquipment(record)
    descriptor = buildWeaponDescriptor(equipment.primaryFullType, false)
    current = isPrimaryHandStateCurrent(zombie, descriptor, true)
    if current == true then
        return true, "unchanged"
    end
    descriptor = buildWeaponDescriptor(equipment.primaryFullType, true)
    ok, reason = applyHands(
        zombie,
        record,
        equipment,
        descriptor,
        true
    )
    record.runtime = record.runtime or {}
    record.runtime.equipmentAttackModeApplied = true
    record.runtime.equipmentPresentationRevision =
        Equipment.PRESENTATION_REVISION
    Visuals.RefreshModel(zombie)
    return ok, reason
end

function Equipment.ResolveWeaponMode(fullType)
    return buildWeaponDescriptor(fullType, false).resolvedMode
end

function Equipment.ActivateMeleeFallback(record, zombie)
    local inv = Inventory and Inventory.EnsureRecordInventory
        and Inventory.EnsureRecordInventory(record)
        or nil
    local currentID = inv and inv.equipped and inv.equipped.primary or nil
    local currentType = currentID and inv.items and inv.items[currentID]
        and inv.items[currentID].type
        or nil
    local candidates = {}
    local itemID
    local state
    local descriptor
    local selectedID
    local ok
    local reason
    if not record or not inv or not Inventory.EquipPrimary then
        return false, "inventory_fallback_unavailable"
    end
    for itemID, state in pairs(inv.items or {}) do
        if itemID ~= currentID and state
            and (state.cond == nil or tonumber(state.cond) == nil or tonumber(state.cond) > 0)
        then
            descriptor = buildWeaponDescriptor(state.type, false)
            if descriptor.hasWeapon == true and descriptor.resolvedMode == "melee" then
                candidates[#candidates + 1] = {
                    id = itemID,
                    reserve = state.templateKey == "tmpl:weapon:reserve" and 0 or 1,
                }
            end
        end
    end
    table.sort(candidates, function(left, right)
        if left.reserve ~= right.reserve then return left.reserve < right.reserve end
        return tostring(left.id) < tostring(right.id)
    end)
    selectedID = candidates[1] and candidates[1].id or nil
    ok, reason = Inventory.EquipPrimary(
        record,
        selectedID,
        selectedID and "combat_melee_fallback" or "combat_shove_fallback"
    )
    if not ok then return false, reason end
    record.weaponMode = "melee"
    record.runtime = record.runtime or {}
    record.runtime.weaponFallbackFrom = currentType
    record.runtime.weaponFallbackReason = "out_of_ammo"
    record.runtime.forceSyncEvent = selectedID
        and "weapon_fallback_melee"
        or "weapon_fallback_shove"
    record.runtime.equipmentDescribeCache = nil
    if zombie then
        Equipment.ApplyCombatState(zombie, record, true, true)
    end
    return true, selectedID and "switched_to_melee" or "switched_to_shove"
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
