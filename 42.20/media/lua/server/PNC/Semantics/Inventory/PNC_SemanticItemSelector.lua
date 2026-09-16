-- Read-only semantic item selection over PNC's compact NPC inventory model.
-- MarketSense is optional: exact fullType selection remains available when it
-- is absent, while tag/capability selection reports that classification is
-- unavailable instead of pretending that no matching item exists.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.ItemSelector = PNC.Semantics.ItemSelector or {}

local Selector = PNC.Semantics.ItemSelector
Selector.Cache = Selector.Cache or {}
Selector.MAX_ITEMS = Selector.MAX_ITEMS or 256
Selector.MAX_TAGS = Selector.MAX_TAGS or 96

local function normalized(value)
    local text = string.lower(tostring(value or ""))
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text
end

local function addValue(set, value, state)
    if type(value) == "string" or type(value) == "number" then
        local key = normalized(value)
        if key ~= "" and not set[key] and state.count < Selector.MAX_TAGS then
            set[key] = true
            state.count = state.count + 1
        end
        return
    end
    if type(value) ~= "table" then return end
    for key, child in pairs(value) do
        if type(key) == "number" then
            addValue(set, child, state)
        elseif child == true then
            addValue(set, key, state)
        end
        if state.count >= Selector.MAX_TAGS then return end
    end
end

local function addCapability(set, key, value, state)
    if value == true then addValue(set, key, state) end
    if type(value) == "string" or type(value) == "number" then
        addValue(set, key .. "." .. tostring(value), state)
    end
end

local function marketSense()
    return rawget(_G, "MarketSense")
end

local function classification(fullType)
    fullType = tostring(fullType or "")
    if fullType == "" then return nil, "item_type_missing" end
    local cached = Selector.Cache[fullType]
    if cached then return cached end
    local api = marketSense()
    if type(api) ~= "table" or type(api.GetTags) ~= "function"
        or type(api.GetItemCapabilities) ~= "function"
    then
        return nil, "classification_unavailable"
    end
    local tagsOK, tags = pcall(api.GetTags, fullType)
    local capabilitiesOK, capabilities = pcall(api.GetItemCapabilities,
        fullType)
    if not tagsOK or type(tags) ~= "table"
        or not capabilitiesOK or type(capabilities) ~= "table"
    then
        return nil, "classification_failed"
    end
    local tagSet = {}
    local capabilitySet = {}
    local tagState = { count = 0 }
    local capabilityState = { count = 0 }
    addValue(tagSet, tags.primary, tagState)
    addValue(tagSet, tags.category, tagState)
    addValue(tagSet, tags.tags, tagState)
    addValue(tagSet, tags.expandedTags, tagState)
    addValue(tagSet, tags.themes, tagState)
    for key, value in pairs(capabilities.capabilities or {}) do
        addCapability(capabilitySet, tostring(key), value, capabilityState)
    end
    local result = {
        fullType = fullType,
        primary = normalized(tags.primary),
        category = normalized(tags.category),
        tags = tagSet,
        capabilities = capabilitySet,
        available = true,
    }
    Selector.Cache[fullType] = result
    return result
end

local function itemType(item)
    return tostring(item and (item.type or item.fullType) or "")
end

local function requestedValues(value)
    if type(value) == "string" or type(value) == "number" then
        return { normalized(value) }
    end
    local values = {}
    if type(value) == "table" then
        for index = 1, #value do
            local entry = normalized(value[index])
            if entry ~= "" then values[#values + 1] = entry end
        end
    end
    return values
end

local function containsAll(set, values)
    if #values < 1 then return true end
    for index = 1, #values do
        if not set[values[index]] then return false end
    end
    return true
end

function Selector.ClearCache(fullType)
    if fullType ~= nil then
        Selector.Cache[tostring(fullType)] = nil
    else
        Selector.Cache = {}
    end
end

function Selector.Matches(item, request)
    request = type(request) == "table" and request or {}
    if type(item) ~= "table" then return false, "item_invalid" end
    local fullType = itemType(item)
    if fullType == "" then return false, "item_type_missing" end
    if request.itemID and tostring(request.itemID) ~= tostring(item.id) then
        return false, "item_id_mismatch"
    end
    if request.fullType and tostring(request.fullType) ~= fullType then
        return false, "item_type_mismatch"
    end
    local tags = requestedValues(request.tags or request.tag or request.concept)
    local capabilities = requestedValues(request.capabilities
        or request.capability)
    local needsClassification = #tags > 0 or #capabilities > 0
        or request.category ~= nil or request.primary ~= nil
    local details
    local classificationReason
    if needsClassification then
        details, classificationReason = classification(fullType)
        if not details then return false, classificationReason end
    end
    if #tags > 0 and not containsAll(details.tags, tags) then
        return false, "item_tags_mismatch"
    end
    if #capabilities > 0
        and not containsAll(details.capabilities, capabilities)
    then
        return false, "item_capabilities_mismatch"
    end
    if request.category and details.category ~= normalized(request.category)
    then
        return false, "item_category_mismatch"
    end
    if request.primary and details.primary ~= normalized(request.primary)
    then
        return false, "item_primary_mismatch"
    end
    if request.minStack and (tonumber(item.stack) or 1)
        < tonumber(request.minStack)
    then
        return false, "item_quantity_insufficient"
    end
    return true, "matched", details
end

local function score(item, request, details)
    local value = 0
    if request.itemID and tostring(request.itemID) == tostring(item.id) then
        value = value + 1000
    end
    if request.fullType and tostring(request.fullType) == itemType(item) then
        value = value + 500
    end
    if details then
        if request.category and details.category == normalized(request.category)
        then value = value + 50 end
        if request.primary and details.primary == normalized(request.primary)
        then value = value + 50 end
        value = value + #(requestedValues(request.tags
            or request.tag or request.concept)) * 20
    end
    return value
end

local function sortedItemIDs(items)
    local ids = {}
    for id in pairs(items or {}) do ids[#ids + 1] = tostring(id) end
    table.sort(ids)
    return ids
end

function Selector.Find(record, request, options)
    options = type(options) == "table" and options or {}
    local inventory = options.inventory
    if not inventory and record and record.inventory then
        inventory = record.inventory
    end
    if not inventory and PNC.Inventory
        and type(PNC.Inventory.EnsureRecordInventory) == "function"
    then
        inventory = PNC.Inventory.EnsureRecordInventory(record, {
            reconcileWaterContainer = false,
        })
    end
    local items = inventory and inventory.items or nil
    if type(items) ~= "table" then return nil, "inventory_unavailable" end
    local ids = sortedItemIDs(items)
    local limit = math.max(1, math.floor(tonumber(options.maxItems)
        or Selector.MAX_ITEMS))
    local candidates = {}
    local classificationReason
    for index = 1, math.min(#ids, limit) do
        local item = items[ids[index]]
        if item and (options.includeLocked == true
            or item.interactionLocked ~= true)
        then
            local matched, reason, details = Selector.Matches(item, request)
            if matched then
                candidates[#candidates + 1] = {
                    item = item,
                    details = details,
                    score = score(item, request, details),
                }
            elseif reason == "classification_unavailable"
                or reason == "classification_failed"
            then
                classificationReason = reason
            end
        end
    end
    if #candidates < 1 then
        return nil, classificationReason or "item_not_found"
    end
    table.sort(candidates, function(left, right)
        if left.score ~= right.score then return left.score > right.score end
        local leftType, rightType = itemType(left.item), itemType(right.item)
        if leftType ~= rightType then return leftType < rightType end
        return tostring(left.item.id) < tostring(right.item.id)
    end)
    local selected = candidates[1].item
    local available = math.max(1, math.floor(tonumber(selected.stack) or 1))
    local quantity = math.max(1, math.floor(tonumber(
        request.quantity or options.quantity) or 1))
    return {
        itemID = tostring(selected.id),
        fullType = itemType(selected),
        available = available,
        quantity = math.min(quantity, available),
        score = candidates[1].score,
        classification = candidates[1].details,
    }, "matched"
end

return Selector
