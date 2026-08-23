PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Internal = PNC.Equipment.Internal or {}

local Equipment = PNC.Equipment
local Internal = Equipment.Internal
local Core = PNC.Core
local Visuals = PNC.Visuals
local Inventory = PNC.Inventory

function Internal.clearExplicitWornItems(zombie)
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

function Internal.hasClothingVisual(zombie, fullType)
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

function Internal.getWornInventoryItem(record, bodyLocation)
    local inventory = record and record.inventory or nil
    local itemID = inventory and inventory.worn
        and inventory.worn[bodyLocation] or nil
    return itemID and inventory.items and inventory.items[itemID] or nil
end

function Internal.applyInventoryState(item, record, bodyLocation)
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

function Internal.applyItemVisualState(item, visualState)
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

function Internal.visualStateSignature(state)
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

function Internal.applyPrimaryInventoryState(item, record)
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
        Internal.applyItemVisualState(item, storedVisual)
    end
    capturedVisual = Equipment.CaptureItemVisualState
        and Equipment.CaptureItemVisualState(
            item,
            equipment and equipment.primaryFullType or nil
        ) or nil
    if capturedVisual and state
        and Equipment.StoreVisualStateInItemState
        and Internal.visualStateSignature(storedVisual)
            ~= Internal.visualStateSignature(capturedVisual)
    then
        Equipment.StoreVisualStateInItemState(
            state,
            capturedVisual
        )
        visualChanged = true
    end
    if capturedVisual and equipment
        and Internal.visualStateSignature(equipment.primaryVisual)
            ~= Internal.visualStateSignature(capturedVisual)
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
