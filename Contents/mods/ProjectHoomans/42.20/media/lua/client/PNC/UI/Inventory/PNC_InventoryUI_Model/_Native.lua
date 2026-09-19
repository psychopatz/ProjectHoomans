local Model = PNC.InventoryUIModel
local TooltipModel = require
    "PsychopatzCore/UI/Inventory/PsychopatzInventoryTooltipModel"
local TooltipOptions = require
    "PNC/UI/Inventory/PNC_InventoryUI_CoreTooltipOptions"
local PROBE_CACHE = {}
local ROOT_INVENTORY_TEXTURE = getTexture
    and getTexture("media/ui/Icon_InventoryBasic.png")
    or nil

local function isNPCDepositForbidden(item)
    if type(item) ~= "table" then return false end
    if item.interactionLocked == true then return true end
    if tostring(item.type or "") == "Base.IDcard" then return true end
    return item.templateKey == "tmpl:identity_card:0"
        or item.legacyTemplateKey == "tmpl:identity_card:0"
        or item.identityNPCId ~= nil
        or item.identityNPCName ~= nil
end

local function safeCall(object, method, fallback, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return fallback end
    local value = fn(object, ...)
    if value == nil then return fallback end
    return value
end

local function probe(fullType)
    fullType = tostring(fullType or "")
    if PROBE_CACHE[fullType] then return PROBE_CACHE[fullType] end
    local item = PNC.Equipment and PNC.Equipment.CreateItem
        and PNC.Equipment.CreateItem(fullType)
        or nil
    if type(item) == "table" and not item.getDisplayName and item[1] then
        item = item[1]
    end
    local result = {
        fullType = fullType,
        name = tostring(safeCall(item, "getDisplayName", fullType)),
        category = tostring(
            safeCall(item, "getDisplayCategory", nil)
            or safeCall(item, "getCategory", "Item")
        ),
        texture = safeCall(item, "getTex", nil),
        weight = tonumber(
            safeCall(item, "getActualWeight", nil)
            or safeCall(item, "getWeight", 0)
        ) or 0,
        conditionMax = tonumber(safeCall(item, "getConditionMax", nil)),
    }
    PROBE_CACHE[fullType] = result
    return result
end

Model.Probe = probe

local function listContainsItem(list, item)
    local entry
    local candidate
    if not list or not list.size or not list.get then return false end
    for index = 0, list:size() - 1 do
        entry = list:get(index)
        candidate = entry and entry.getItem and safeCall(entry, "getItem", nil)
            or entry
        if candidate == item then return true end
    end
    return false
end

local function isPlayerItemEquipped(player, item)
    local method = player and player.isEquipped or nil
    local value
    if safeCall(item, "isEquipped", false) == true then return true end
    if type(method) == "function" then
        value = method(player, item)
        if value == true then return true end
    end
    if safeCall(player, "getPrimaryHandItem", nil) == item
        or safeCall(player, "getSecondaryHandItem", nil) == item
    then
        return true
    end
    if listContainsItem(safeCall(player, "getWornItems", nil), item)
        or listContainsItem(safeCall(player, "getAttachedItems", nil), item)
    then
        return true
    end
    return false
end

local function nativeFlag(item, methodName)
    return safeCall(item, methodName, false) == true
end

local function nativeContainerHasItems(item)
    local nested = safeCall(item, "getItemContainer", nil)
        or safeCall(item, "getInventory", nil)
    local items = safeCall(nested, "getItems", nil)
    return items and items.size and items:size() > 0 or false
end

local function nativeInteractionLocked(item)
    local fullType
    local modData
    fullType = tostring(safeCall(item, "getFullType", ""))
    if fullType == "Base.IDcard" then return true end
    if nativeFlag(item, "isInteractionLocked")
        or nativeFlag(item, "getInteractionLocked")
    then
        return true
    end
    modData = safeCall(item, "getModData", nil)
    return type(modData) == "table"
        and (modData.interactionLocked == true
            or modData.PNCInteractionLocked == true
            or modData.identityNPCId ~= nil
            or modData.identityNPCName ~= nil)
end

-- This is the client-side equivalent of the server's native bulk-transfer
-- protection.  Keep it in the row model so click, drag, and bulk transfer all
-- render and enforce the same eligibility decision.  The local editor copies
-- eligible items; it never removes them from the player's inventory.
function Model.GetPlayerItemTransferBlockReason(item, player)
    if not item then return "item_missing" end
    if nativeFlag(item, "isFavorite") then return "favorite" end
    if isPlayerItemEquipped(player, item) then return "equipped" end
    if nativeInteractionLocked(item) then return "item_off_limits" end
    if nativeContainerHasItems(item) then return "container_not_empty" end
    return nil
end

local function playerItemRow(item, containerKey, player, includeGiftScore)
    local fullType = tostring(safeCall(item, "getFullType", ""))
    local metadata = probe(fullType)
    local customName = safeCall(item, "getName", nil, player)
    if customName == nil then
        customName = safeCall(item, "getName", nil)
    end
    local displayName = tostring(customName or metadata.name or fullType)
    local giftScore
    local giftValid
    if includeGiftScore == true then
        giftScore = PNC.Gifts and PNC.Gifts.GetItemScore
            and PNC.Gifts.GetItemScore(fullType, item) or nil
        giftValid = giftScore and PNC.Gifts.IsValidItemType
            and PNC.Gifts.IsValidItemType(fullType, item) == true or false
    end
    local restrictionReason = Model.GetPlayerItemTransferBlockReason(
        item, player)
    local row = {
        source = "player",
        id = tostring(safeCall(item, "getID", "")),
        nativeItem = item,
        fullType = fullType,
        name = displayName,
        category = metadata.category,
        texture = metadata.texture,
        weight = metadata.weight,
        unitWeight = metadata.weight,
        container = containerKey,
        stack = 1,
        conditionMax = metadata.conditionMax,
        equipped = isPlayerItemEquipped(player, item),
        favorite = safeCall(item, "isFavorite", false) == true,
        restricted = restrictionReason ~= nil,
        restrictionReason = restrictionReason,
        giftScore = giftScore,
        giftValid = giftValid,
    }
    -- Grouping must ignore quantity/weight, while the tooltip cache still
    -- tracks them when it evaluates the row directly.
    row.stateKey = TooltipModel.StateSignature(row, player, false,
        TooltipOptions.modelOptions)
    return row
end

return {
    safeCall = safeCall,
    probe = probe,
    playerItemRow = playerItemRow,
    isNPCDepositForbidden = isNPCDepositForbidden,
    rootInventoryTexture = ROOT_INVENTORY_TEXTURE,
    tooltipModel = TooltipModel,
    tooltipOptions = TooltipOptions,
}
