-- Bounded candidate scanning and item classification for semantic queries.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Service = PNC.Semantics.InventoryQueryService
local Internal = Service.Internal
local Selector = Internal.Selector

local function text(value, maximum)
    value = tostring(value or "")
    maximum = tonumber(maximum) or 128
    if #value > maximum then return string.sub(value, 1, maximum) end
    return value
end

local function lower(value)
    return string.lower(text(value, 128))
end

local function normalized(value)
    return string.lower(text(value, 64))
end

local function copyValue(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 6 then return nil end
    local output = {}
    local key
    local item
    for key, item in pairs(value) do
        if type(key) ~= "function" and type(item) ~= "function" then
            output[key] = copyValue(item, depth + 1)
        end
    end
    return output
end

local function sortedItemIDs(items)
    local ids = {}
    for id in pairs(items or {}) do ids[#ids + 1] = tostring(id) end
    table.sort(ids)
    return ids
end

local function inventoryFor(record)
    if record and type(record.inventory) == "table" then
        return record.inventory
    end
    if PNC.Inventory
        and type(PNC.Inventory.EnsureRecordInventory) == "function"
    then
        return PNC.Inventory.EnsureRecordInventory(record, {
            reconcileWaterContainer = false,
        })
    end
    return nil
end

local function itemType(item)
    local internal = Selector and Selector.Internal
    if internal and type(internal.ItemType) == "function" then
        return tostring(internal.ItemType(item) or "")
    end
    return tostring(item and (item.type or item.fullType) or "")
end

local function queryTags(query)
    query = type(query) == "table" and query or {}
    if query.concept and Selector
        and type(Selector.TagsForConcept) == "function"
    then
        local mapped = Selector.TagsForConcept(query.concept)
        if mapped then return mapped end
    end
    local concept = string.upper(tostring(query.concept
        or query.category or ""))
    if type(query.tags) == "table" and #query.tags > 0 then
        local output = {}
        for index = 1, math.min(#query.tags, 8) do
            output[#output + 1] = normalized(query.tags[index])
        end
        return output
    end
    return {}
end

local function queryCapabilities(query)
    query = type(query) == "table" and query or {}
    local concept = query.concept or query.category
    if concept and Selector
        and type(Selector.CapabilitiesForConcept) == "function"
    then
        local mapped = Selector.CapabilitiesForConcept(concept)
        if mapped then return mapped end
    end
    local values = type(query.capabilities) == "table"
        and query.capabilities or {}
    local output = {}
    for index = 1, math.min(#values, 8) do
        output[#output + 1] = normalized(values[index])
    end
    return output
end

local function queryTagAlternatives(query)
    query = type(query) == "table" and query or {}
    local concept = query.concept or query.category
    if concept and Selector
        and type(Selector.TagAlternativesForConcept) == "function"
    then
        return Selector.TagAlternativesForConcept(concept) or {}
    end
    return {}
end

local function isAllItemsQuery(query)
    query = type(query) == "table" and query or {}
    return query.listAll == true
        or string.upper(tostring(query.concept or query.category or ""))
            == "ANY_ITEM"
end

local function itemLabel(item, fullType)
    local label = item and (item.customName or item.displayName)
    if not label and item and type(item.itemState) == "table" then
        label = item.itemState.customName or item.itemState.displayName
    end
    label = text(label, 96)
    if label == "" then label = fullType end
    return label
end

local function textMatches(item, queryText, fullType)
    queryText = lower(queryText)
    if queryText == "" then return false end
    local label = lower(itemLabel(item, fullType))
    local typeText = lower(fullType)
    return string.find(label, queryText, 1, true) ~= nil
        or string.find(typeText, queryText, 1, true) ~= nil
end

local function compactMap(value, maximum)
    local output = {}
    if type(value) ~= "table" then return output end
    maximum = tonumber(maximum) or 24
    local count = 0
    local key
    local item
    for key, item in pairs(value) do
        if type(key) == "string"
            and (item == true or item == false
                or type(item) == "string" or type(item) == "number")
        then
            output[text(key, 64)] = item
            count = count + 1
            if count >= maximum then break end
        end
    end
    return output
end

local function compactClassification(details)
    if type(details) ~= "table" then return nil end
    local output = {
        primary = text(details.primary, 64),
        category = text(details.category, 64),
        tags = {},
        capabilities = compactMap(details.capabilities),
        semanticCapabilities = compactMap(details.semanticCapabilities),
        capabilityEvidence = copyValue(details.capabilityEvidence),
        marketRole = text(details.marketRole, 64),
        marketSenseTags = {},
    }
    for tag in pairs(details.tags or {}) do
        if #output.tags >= 16 then break end
        output.tags[#output.tags + 1] = text(tag, 64)
    end
    table.sort(output.tags)
    for index = 1, math.min(#(details.marketSenseTags or {}), 32) do
        output.marketSenseTags[index] = text(
            details.marketSenseTags[index], 64)
    end
    table.sort(output.marketSenseTags)
    return output
end


Internal.CopyValue = copyValue
Internal.Text = text

function Internal.FindCandidates(record, query, options)
    options = type(options) == "table" and options or {}
    query = type(query) == "table" and query or {}
    local inventory = inventoryFor(record)
    local items = inventory and inventory.items or nil
    if type(items) ~= "table" then
        return nil, nil, "inventory_unavailable"
    end

    local tags = queryTags(query)
    local capabilities = queryCapabilities(query)
    local tagAlternatives = queryTagAlternatives(query)
    local listAll = isAllItemsQuery(query)
    local queryText = query.text
    local ids = sortedItemIDs(items)
    local limit = math.max(1, math.min(Service.MAX_ITEMS, math.floor(
        tonumber(options.maxItems) or Service.MAX_ITEMS)))
    local candidates = {}
    local classificationReason
    local index
    for index = 1, math.min(#ids, limit) do
        local item = items[ids[index]]
        if item and item.interactionLocked ~= true then
            local fullType = itemType(item)
            local matched = false
            local details
            local reason
            local score = 0
            if listAll then
                matched, reason = true, "all_items"
            elseif #tags > 0 or #capabilities > 0
                or #tagAlternatives > 0
            then
                local requirements = {
                    tags = tags,
                    capabilities = capabilities,
                    tagAlternatives = tagAlternatives,
                }
                matched, reason, details = Selector.Matches(item,
                    requirements)
                if matched then
                    score = (Selector.Internal.Score
                        and Selector.Internal.Score(item, requirements,
                            details)
                        or ((#tags + #capabilities
                            + (tagAlternatives[1]
                                and #tagAlternatives[1] or 0)) * 20))
                elseif reason == "classification_unavailable"
                    or reason == "classification_failed"
                then
                    classificationReason = reason
                end
            elseif queryText then
                matched = Selector.Internal
                    and Selector.Internal.TextMatches
                    and Selector.Internal.TextMatches(item, queryText,
                        fullType)
                    or textMatches(item, queryText, fullType)
                reason = matched and "text_matched" or "item_text_mismatch"
            end
            if matched then
                if not details and Selector.Internal
                    and type(Selector.Internal.Classification) == "function"
                then
                    details = Selector.Internal.Classification(fullType, {})
                end
                candidates[#candidates + 1] = {
                    itemID = tostring(item.id or ids[index]),
                    fullType = fullType,
                    displayName = itemLabel(item, fullType),
                    quantity = math.max(1, math.floor(
                        tonumber(item.stack) or 1)),
                    score = score,
                    classification = compactClassification(details),
                }
            end
        end
    end

    return candidates, inventory, nil, classificationReason
end

return Service
