local Model = PNC.InventoryUIModel
local TooltipModel = require
    "PsychopatzCore/UI/Inventory/PsychopatzInventoryTooltipModel"
local TooltipOptions = require
    "PNC/UI/Inventory/PNC_InventoryUI_CoreTooltipOptions"
local Currency = PsychopatzCore and PsychopatzCore.Currency
local PROBE_CACHE = {}
local FAST_AGGREGATE_TYPES = {
    ["Base.Money"] = true,
    ["Base.MoneyBundle"] = true,
}
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

-- These item types are immutable value tokens for the purposes of the
-- player-side viewer. Do not build a full tooltip/protection row for every
-- physical unit when the engine is carrying thousands of them. Authority
-- still revalidates every transfer; this is only a display/index shortcut.
local function canFastAggregate(item, fullType)
    fullType = tostring(fullType or safeCall(item, "getFullType", ""))
    if not FAST_AGGREGATE_TYPES[fullType] then return false end
    if nativeFlag(item, "isFavorite")
        or nativeFlag(item, "isEquipped")
        or safeCall(item, "isCustomName", false) == true
    then
        return false
    end
    if nativeInteractionLocked(item) or nativeContainerHasItems(item) then
        return false
    end
    return true
end

local function isFastAggregateType(fullType)
    return FAST_AGGREGATE_TYPES[tostring(fullType or "")] == true
end

local function nativeQuantity(item)
    local count = safeCall(item, "getCount", 1)
    count = tonumber(count)
    if not count or count < 1 then return 1 end
    return math.max(1, math.floor(count))
end

local function currencyName()
    local key = "UI_PNC_Inventory_Currency"
    if type(getText) == "function" then
        local translated = getText(key)
        if translated and translated ~= key then return translated end
    end
    return "Currency"
end

local function newCurrencyRow(containerKey, source)
    local moneyType = Currency and Currency.MONEY_TYPE or "Base.Money"
    local metadata = probe(moneyType)
    return {
        source = source or "player",
        id = "currency:" .. tostring(source or "player") .. ":"
            .. tostring(containerKey or "root"),
        currency = true,
        currencyComponent = false,
        currencySection = currencyName(),
        aggregate = true,
        -- Keep the base Money metadata for the icon/tooltip, but make the
        -- row a value token. The physical type is deliberately not sent by
        -- the transfer selector; Core normalizes both currency types.
        fullType = moneyType,
        name = metadata.name or "Money",
        category = currencyName(),
        baseCategory = metadata.category,
        texture = metadata.texture,
        weight = 0,
        unitWeight = 0,
        container = containerKey,
        currencyUnitValue = 1,
        stack = 0,
        currencyQuantity = 0,
        currencyPhysicalQuantity = 0,
        currencyUnits = 0,
        currencyLoose = 0,
        currencyBundles = 0,
        currencyUnitEntries = 0,
        currencyStackEntries = {},
        currencyComponents = {},
        favorite = false,
        equipped = false,
        restricted = false,
        itemIDs = nil,
    }
end

local function addCurrencyValue(row, fullType, quantity, physicalQuantity)
    quantity = math.max(0, math.floor(tonumber(quantity) or 0))
    if not row or quantity < 1 then return end
    physicalQuantity = math.max(1, math.floor(
        tonumber(physicalQuantity) or quantity))
    local value = Currency and Currency.ValueFor
        and Currency.ValueFor(fullType, quantity)
        or fullType == "Base.MoneyBundle" and quantity * 100 or quantity
    row.currencyUnits = row.currencyUnits + value
    row.currencyQuantity = row.currencyQuantity + quantity
    row.currencyPhysicalQuantity = row.currencyPhysicalQuantity
        + physicalQuantity
    row.currencyComponents[#row.currencyComponents + 1] = {
        fullType = tostring(fullType or ""),
        quantity = quantity,
        physicalQuantity = physicalQuantity,
    }
    -- The special row is selected in currency units, not physical entries.
    -- This makes 1 MoneyBundle and 100 Money interchangeable in the viewer.
    row.stack = row.currencyUnits
    if fullType == (Currency and Currency.BUNDLE_TYPE or "Base.MoneyBundle") then
        row.currencyBundles = row.currencyBundles + quantity
    else
        row.currencyLoose = row.currencyLoose + quantity
    end
    row.stateKey = table.concat({
        "currency", tostring(row.container or "root"),
        tostring(row.stack), tostring(row.currencyUnits),
        tostring(row.currencyLoose),
        tostring(row.currencyBundles),
    }, ":")
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

local function playerItemRow(
    item, containerKey, player, includeGiftOnly, giftPreferences
)
    local fullType = tostring(safeCall(item, "getFullType", ""))
    local metadata = probe(fullType)
    local customName = safeCall(item, "getName", nil, player)
    if customName == nil then
        customName = safeCall(item, "getName", nil)
    end
    local displayName = tostring(customName or metadata.name or fullType)
    local giftValid
    if includeGiftOnly == true then
        giftValid = PNC.Gifts and PNC.Gifts.IsValidItemType
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
        giftPreference = giftPreferences and giftPreferences[fullType] or nil,
        restricted = restrictionReason ~= nil,
        restrictionReason = restrictionReason,
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
    canFastAggregate = canFastAggregate,
    isFastAggregateType = isFastAggregateType,
    nativeQuantity = nativeQuantity,
    currency = Currency,
    newCurrencyRow = newCurrencyRow,
    addCurrencyValue = addCurrencyValue,
    playerItemRow = playerItemRow,
    isNPCDepositForbidden = isNPCDepositForbidden,
    rootInventoryTexture = ROOT_INVENTORY_TEXTURE,
    tooltipModel = TooltipModel,
    tooltipOptions = TooltipOptions,
}
