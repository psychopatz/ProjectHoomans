PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Internal = PNC.Equipment.Internal or {}

local Equipment = PNC.Equipment
local Internal = Equipment.Internal

local function itemFullType(item)
    local ok
    local fullType
    if not item or type(item.getFullType) ~= "function" then
        return nil
    end
    ok, fullType = pcall(item.getFullType, item)
    fullType = ok and tostring(fullType or "") or ""
    return fullType ~= "" and fullType or nil
end

local function currentHandItem(zombie, secondary)
    local method = secondary and "getSecondaryHandItem"
        or "getPrimaryHandItem"
    local ok
    local item
    if not zombie or type(zombie[method]) ~= "function" then
        return nil, false
    end
    ok, item = pcall(zombie[method], zombie)
    return ok and item or nil, ok
end

local function setHandItem(zombie, secondary, item)
    local method = secondary and "setSecondaryHandItem"
        or "setPrimaryHandItem"
    local ok
    if not zombie or type(zombie[method]) ~= "function" then
        return false, "missing_method:" .. method
    end
    ok = pcall(zombie[method], zombie, item)
    return ok, ok and nil or "set_failed:" .. method
end

local function refreshHands(zombie)
    if zombie and type(zombie.resetEquippedHandsModels) == "function" then
        pcall(zombie.resetEquippedHandsModels, zombie)
    end
end

local function visualSignature(visual)
    if type(Internal.visualStateSignature) == "function" then
        return Internal.visualStateSignature(visual or {})
    end
    return tostring(visual and visual.fullType or "")
end

local function buildSignature(activity)
    return table.concat({
        tostring(activity and activity.activityItemFullType or ""),
        tostring(activity and activity.hand or "primary"),
        visualSignature(activity and activity.activityItemVisual),
        tostring(activity and activity.revision or ""),
    }, "|")
end

local function clearActivityHands(zombie)
    local modData = zombie and zombie.getModData
        and zombie:getModData() or nil
    if not modData or modData.PNCActivityHandsSignature == nil then
        return true, "activity_hands_idle"
    end
    setHandItem(zombie, false, nil)
    setHandItem(zombie, true, nil)
    refreshHands(zombie)
    modData.PNCActivityHandsSignature = nil
    modData.PNCActivityHandsFullType = nil
    modData.PNCActivityHandsMode = nil
    modData.PNCActivityHandsItem = nil
    if zombie.setVariable then
        pcall(zombie.setVariable, zombie, "PNCActivityItem", "")
        pcall(zombie.setVariable, zombie, "PNCActivityHand", "")
    end
    return true, "activity_hands_cleared"
end

local function applyItemState(item, activity)
    local state = activity and activity.activityItemState or nil
    local maximum
    local condition
    if not item or type(state) ~= "table" then return end
    condition = tonumber(state.cond)
    maximum = item.getConditionMax and tonumber(item:getConditionMax()) or 0
    if condition ~= nil and item.setCondition then
        item:setCondition(math.max(0, math.min(
            maximum > 0 and maximum or condition, condition
        )))
    end
    if state.uses ~= nil and item.setUses then
        item:setUses(math.max(0, tonumber(state.uses) or 0))
    end
end

function Equipment.ClearActivityHands(zombie)
    return clearActivityHands(zombie)
end

function Equipment.ApplyActivityHands(zombie, activity)
    local fullType = tostring(activity
        and activity.activityItemFullType or "")
    local hand = tostring(activity and activity.hand or "primary")
    local signature
    local modData
    local existingPrimary
    local existingSecondary
    local item
    local createReason
    local ok
    local reason
    local secondary

    if not zombie then
        return false, "missing_body"
    end
    if fullType == "" then
        return clearActivityHands(zombie)
    end
    if hand ~= "both" then hand = "primary" end

    signature = buildSignature({
        activityItemFullType = fullType,
        hand = hand,
        activityItemVisual = activity and activity.activityItemVisual,
        revision = activity and activity.revision,
    })
    modData = zombie.getModData and zombie:getModData() or nil
    existingPrimary = currentHandItem(zombie, false)
    existingSecondary = currentHandItem(zombie, true)
    if modData
        and modData.PNCActivityHandsSignature == signature
        and itemFullType(existingPrimary) == fullType
        and (hand ~= "both" or itemFullType(existingSecondary) == fullType)
    then
        return true, "activity_hands_current"
    end

    item, createReason = Equipment.CreateItem(fullType)
    if not item then
        clearActivityHands(zombie)
        return false, createReason or "activity_item_create_failed"
    end
    if activity and activity.activityItemVisual
        and Internal.applyItemVisualState
    then
        Internal.applyItemVisualState(item, activity.activityItemVisual)
    end
    applyItemState(item, activity)

    if hand == "both" then
        ok, reason = setHandItem(zombie, false, item)
        if not ok then return false, reason end
        secondary = item
    else
        ok, reason = setHandItem(zombie, false, item)
        if not ok then return false, reason end
        secondary = nil
    end
    ok, reason = setHandItem(zombie, true, secondary)
    if not ok then return false, reason end
    refreshHands(zombie)
    if zombie.setVariable then
        pcall(zombie.setVariable, zombie, "PNCActivityItem", fullType)
        pcall(zombie.setVariable, zombie, "PNCActivityHand", hand)
    end
    if modData then
        modData.PNCActivityHandsSignature = signature
        modData.PNCActivityHandsFullType = fullType
        modData.PNCActivityHandsMode = hand
        modData.PNCActivityHandsItem = item
    end
    return true, "activity_hands_applied"
end

return Equipment
