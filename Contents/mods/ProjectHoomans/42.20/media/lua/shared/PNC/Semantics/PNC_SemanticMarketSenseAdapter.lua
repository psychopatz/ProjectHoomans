-- Narrow integration boundary between MarketSense and semantic capabilities.
--
-- MarketSense owns the item taxonomy and pricing heuristics.  Hoomans only
-- derives the small set of action capabilities that the semantic layer needs
-- for safe contextual resolution.  This module never selects, removes, or
-- mutates an item.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Adapter = PNC.Semantics.MarketSenseAdapter or {}
PNC.Semantics.MarketSenseAdapter = Adapter

Adapter.VERSION = 1
Adapter.MAX_TAGS = 64

-- These tables are the policy boundary, not item-name rules.  New MarketSense
-- tags can be supported here without changing the parser or dialogue state.
Adapter.EDIBLE_ROLES = Adapter.EDIBLE_ROLES or {
    edible = true,
    opened_food = true,
    candy = true,
}

Adapter.NON_EDIBLE_ROLES = Adapter.NON_EDIBLE_ROLES or {
    ingredient = true,
    seed = true,
    pet_food = true,
    insect = true,
    spice = true,
    sealed_food = true,
    sealed_food_reserve = true,
}

Adapter.DRINKABLE_TAGS = Adapter.DRINKABLE_TAGS or {
    "beverage",
    "liquidbeverage",
    "liquidwater",
    "liquidtaintedwater",
    "liquidcarbonatedwater",
    "liquidsoda",
    "liquidjuice",
    "liquidmilk",
    "liquidcoffee",
    "liquidtea",
    "liquidbeer",
    "liquidwine",
    "liquidalcohol",
}

Adapter.NON_DRINKABLE_TAGS = Adapter.NON_DRINKABLE_TAGS or {
    "containerliquid",
    "liquidfuel",
    "liquiddye",
    "liquidhairdye",
    "liquidmedical",
    "liquidchemical",
    "liquidindustrial",
    "liquidblood",
    "liquidanimalblood",
    "liquidanimalgrease",
}

Adapter.REFILLABLE_TAGS = Adapter.REFILLABLE_TAGS or {
    "containerliquid",
}

Adapter.NON_EDIBLE_TAGS = Adapter.NON_EDIBLE_TAGS or {
    "foodseed",
    "foodpetfood",
    "foodinsect",
    "foodlivestock",
    "foodspice",
    "foodorfirstaid",
}

local function normalized(value)
    value = string.lower(tostring(value or ""))
    return string.gsub(value, "[^%w]", "")
end

local function normalizedRole(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "[^%w_]+", "_")
    return string.gsub(value, "^_*(.-)_*$", "%1")
end

local function boundedText(value, maximum)
    value = tostring(value or "")
    maximum = tonumber(maximum) or 96
    if #value > maximum then return string.sub(value, 1, maximum) end
    return value
end

local function addTag(set, value, state)
    local tag = normalized(value)
    if tag == "" or set[tag] or state.count >= Adapter.MAX_TAGS then
        return
    end
    set[tag] = true
    state.count = state.count + 1
end

local function collectTags(set, value, state, depth)
    if type(value) == "string" or type(value) == "number" then
        addTag(set, value, state)
        return
    end
    if type(value) ~= "table" or (tonumber(depth) or 0) > 3 then
        return
    end
    local index
    local key
    local child
    for index = 1, #value do
        collectTags(set, value[index], state, (depth or 0) + 1)
        if state.count >= Adapter.MAX_TAGS then return end
    end
    for key, child in pairs(value) do
        if type(key) ~= "number" and child == true then
            addTag(set, key, state)
        end
        if state.count >= Adapter.MAX_TAGS then return end
    end
end

local function copyMap(source)
    local output = {}
    if type(source) ~= "table" then return output end
    local key
    local value
    for key, value in pairs(source) do
        if type(key) == "string" then
            if value == true or value == false then
                output[normalized(key)] = value
            elseif type(value) == "string" or type(value) == "number" then
                output[normalized(key) .. "." .. normalized(value)] = true
            end
        end
    end
    return output
end

local function hasExact(set, values)
    if type(values) ~= "table" then return false end
    local index
    local value
    if #values > 0 then
        for index = 1, #values do
            if set[values[index]] then return true end
        end
        return false
    end
    for value in pairs(values) do
        if set[value] then return true end
    end
    return false
end

local function hasPrefix(set, values)
    local tag
    local index
    local prefix
    for tag in pairs(set) do
        for index = 1, #values do
            prefix = values[index]
            if string.sub(tag, 1, #prefix) == prefix then return true end
        end
    end
    return false
end

local function hasExcludedTag(set)
    local tag
    for tag in pairs(set) do
        if Adapter.NON_EDIBLE_TAGS[tag] then return true end
    end
    return false
end

local function marketSenseDetails(fullType, options)
    options = type(options) == "table" and options or {}
    if type(options.marketSenseDetails) == "table" then
        return options.marketSenseDetails, "provided"
    end
    local api = options.api or rawget(_G, "MarketSense")
    if type(api) ~= "table" or type(api.GetPriceDetails) ~= "function" then
        return nil, "api_unavailable"
    end
    local ok
    local details
    ok, details = pcall(api.GetPriceDetails, fullType)
    if not ok or type(details) ~= "table" then
        return nil, "price_details_unavailable"
    end
    return details, "marketsense"
end

local function evidence(source, value)
    return {
        source = source,
        value = value,
    }
end

local function collectClassificationTags(classification, details)
    local tags = {}
    local state = { count = 0 }
    local raw = classification and classification.rawTags or nil
    collectTags(tags, classification and classification.primary, state, 0)
    collectTags(tags, classification and classification.category, state, 0)
    collectTags(tags, classification and classification.tags, state, 0)
    collectTags(tags, classification and classification.marketSenseTags, state, 0)
    collectTags(tags, raw and raw.primary, state, 0)
    collectTags(tags, raw and raw.category, state, 0)
    collectTags(tags, raw and raw.tags, state, 0)
    collectTags(tags, raw and raw.expandedTags, state, 0)
    collectTags(tags, details and details.primary, state, 0)
    collectTags(tags, details and details.category, state, 0)
    collectTags(tags, details and details.tags, state, 0)
    collectTags(tags, details and details.expandedTags, state, 0)
    return tags
end

local function derive(classification, details, role)
    local tags = collectClassificationTags(classification, details)
    local semantic = {}
    local capabilityEvidence = {}

    local nonEdibleRole = Adapter.NON_EDIBLE_ROLES[role] == true
    local edibleRole = Adapter.EDIBLE_ROLES[role] == true
    local drinkExcluded = hasExact(tags, Adapter.NON_DRINKABLE_TAGS)
    local drinkTag = not drinkExcluded
        and hasPrefix(tags, Adapter.DRINKABLE_TAGS)
    local refillable = hasExact(tags, Adapter.REFILLABLE_TAGS)

    if nonEdibleRole then
        semantic.edible = false
        capabilityEvidence.edible = evidence(
            "marketsense.price_heuristic.role", role)
    elseif edibleRole then
        semantic.edible = true
        capabilityEvidence.edible = evidence(
            "marketsense.price_heuristic.role", role)
    elseif not hasExcludedTag(tags)
        and (tags.food or hasPrefix(tags, { "food" }))
    then
        semantic.edible = true
        capabilityEvidence.edible = evidence(
            "marketsense.taxonomy.food_tag", "food")
    end

    -- MarketSense prices beverages through the food model, so a drink may
    -- carry the generic edible role as well.  For action compatibility it is
    -- still a drink, not an item that the EAT handler should select.
    if drinkTag then
        semantic.edible = false
        capabilityEvidence.edible = evidence(
            "marketsense.taxonomy.beverage_tag", "not_eat_target")
    end

    if drinkTag then
        semantic.drinkable = true
        capabilityEvidence.drinkable = evidence(
            "marketsense.taxonomy.beverage_tag", "beverage")
    elseif drinkExcluded then
        semantic.drinkable = false
        capabilityEvidence.drinkable = evidence(
            "marketsense.taxonomy.non_beverage_liquid", "excluded")
    end

    if refillable then
        semantic.refillable = true
        capabilityEvidence.refillable = evidence(
            "marketsense.taxonomy.container_tag", "containerliquid")
    end

    if semantic.edible == true or semantic.drinkable == true then
        semantic.consumable = true
        capabilityEvidence.consumable = evidence(
            "marketsense.semantic_capability", "edible_or_drinkable")
    end
    return semantic, capabilityEvidence, tags
end

function Adapter.EnrichClassification(fullType, classification, options)
    fullType = boundedText(fullType, 160)
    if fullType == "" then return classification end
    local output = type(classification) == "table" and classification or {}
    local details, detailsSource = marketSenseDetails(fullType, options)
    local heuristic = details and details.priceHeuristic or nil
    local role = normalizedRole(
        output.marketRole or output.role
            or heuristic and heuristic.role
            or details and details.role
    )
    local semantic
    local capabilityEvidence
    local tags
    semantic, capabilityEvidence, tags = derive(output, details, role)

    local capabilities = copyMap(output.capabilities)
    local key
    local value
    local semanticCount = 0
    for key, value in pairs(semantic) do capabilities[key] = value end
    for key in pairs(semantic) do semanticCount = semanticCount + 1 end

    output.capabilities = capabilities
    output.semanticCapabilities = semantic
    output.capabilityEvidence = capabilityEvidence
    output.marketRole = role ~= "" and role or nil
    output.marketSenseTags = {}
    local tag
    local index = 0
    for tag in pairs(tags) do
        index = index + 1
        output.marketSenseTags[index] = boundedText(tag, 64)
        if index >= Adapter.MAX_TAGS then break end
    end
    table.sort(output.marketSenseTags)
    output.semanticClassificationSource = detailsSource
    output.semanticCapabilitiesReady = details ~= nil or semanticCount > 0
    return output
end

Adapter.Enrich = Adapter.EnrichClassification

return Adapter
