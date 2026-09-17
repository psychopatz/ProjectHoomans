-- Bounded extraction of MarketSense taxonomy and price facts.

PNC = PNC or {}
PNC.Gifts = PNC.Gifts or {}
PNC.Gifts.Foundation = PNC.Gifts.Foundation or {}
local Foundation = PNC.Gifts.Foundation
local Facts = Foundation.MarketSenseFacts or {}
Foundation.MarketSenseFacts = Facts
local Capabilities = Foundation.MarketSenseCapabilities

local function bounded(value, maximum)
    value = tostring(value or "")
    if #value > (maximum or 96) then
        return string.sub(value, 1, maximum or 96)
    end
    return value
end

local function normalized(value)
    value = string.lower(tostring(value or ""))
    return string.gsub(value, "[^%w]", "")
end

local function finite(value)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge then
        return nil
    end
    return value
end

local function collect(value, output, seen, depth)
    local index
    local key
    local child
    depth = tonumber(depth) or 0
    if depth > 3 or #output >= 64 then return end
    if type(value) == "string" or type(value) == "number" then
        local item = normalized(value)
        if item ~= "" and not seen[item] then
            seen[item] = true
            output[#output + 1] = item
        end
        return
    end
    if type(value) ~= "table" then return end
    for index = 1, #value do
        collect(value[index], output, seen, depth + 1)
    end
    for key, child in pairs(value) do
        if type(key) ~= "number" then
            if child == true then
                local item = normalized(key)
                if item ~= "" and not seen[item] then
                    seen[item] = true
                    output[#output + 1] = item
                end
            elseif type(child) == "string" or type(child) == "number" then
                collect(key, output, seen, depth + 1)
                collect(child, output, seen, depth + 1)
            end
        end
    end
end

local function values(value)
    local output = {}
    local seen = {}
    collect(value, output, seen, 0)
    table.sort(output)
    return output
end

local function merge(first, second)
    local output = {}
    local seen = {}
    local index
    for index = 1, #(first or {}) do
        if not seen[first[index]] then
            seen[first[index]] = true
            output[#output + 1] = first[index]
        end
    end
    for index = 1, #(second or {}) do
        if not seen[second[index]] and #output < 64 then
            seen[second[index]] = true
            output[#output + 1] = second[index]
        end
    end
    table.sort(output)
    return output
end

local function firstText(primary, fallback)
    if primary == nil or tostring(primary) == "" then primary = fallback end
    return bounded(primary, 96)
end

local function lastSegment(value)
    local segment = string.match(tostring(value or ""), "([^%.]+)$")
    return segment or tostring(value or "")
end

local function firstRaw(value, depth)
    local index
    local child
    depth = tonumber(depth) or 0
    if depth > 3 then return nil end
    if type(value) == "string" or type(value) == "number" then
        return tostring(value)
    end
    if type(value) ~= "table" then return nil end
    for index = 1, #value do
        child = firstRaw(value[index], depth + 1)
        if child then return child end
    end
    return nil
end

local function candidate(output, seen, kind, value, priority)
    local key = normalized(value)
    if key == "" or key == "general" or key == "unknown" or seen[key] then
        return
    end
    seen[key] = true
    output[#output + 1] = {
        type = kind, key = key, value = bounded(value, 96), priority = priority,
    }
end

function Facts.FromDetails(fullType, details, options)
    options = type(options) == "table" and options or {}
    details = type(details) == "table" and details or {}
    local tagDetails = type(options.marketSenseTags) == "table"
        and options.marketSenseTags or {}
    local primary = firstText(details.primary, details.category)
    local category = firstText(details.category, primary)
    local expandedRaw = details.expandedTags or tagDetails.expandedTags
    local subcategory = details.subcategory
    if subcategory == nil or tostring(subcategory) == "" then
        subcategory = lastSegment(firstRaw(expandedRaw) or "")
    end
    local leaf = firstText(details.leaf, primary)
    local tags = merge(values(details.tags), values(tagDetails.tags))
    local expandedTags = merge(values(expandedRaw),
        values(tagDetails.expandedTags))
    local marketSenseTags = merge(tags, expandedTags)
    local role = details.priceHeuristic
        and details.priceHeuristic.role or details.role
    role = bounded(role, 64)
    local capabilities = {}
    local semanticAdapter = PNC.Semantics
        and PNC.Semantics.MarketSenseAdapter
    if semanticAdapter and type(semanticAdapter.EnrichClassification) == "function" then
        local classification = semanticAdapter.EnrichClassification(fullType, {
            primary = primary, category = category, tags = tags,
            expandedTags = expandedTags, marketRole = role,
        }, { marketSenseDetails = details })
        capabilities = Capabilities.Copy(classification
            and classification.capabilities)
    end
    if not Capabilities.HasEntries(capabilities) then
        capabilities = Capabilities.Fallback(primary, category,
            marketSenseTags, role)
    end
    local candidates = {}
    local candidateSeen = {}
    local index
    candidate(candidates, candidateSeen, "leaf", leaf, 5)
    candidate(candidates, candidateSeen, "subcategory", subcategory, 4)
    for index = 1, #expandedTags do
        candidate(candidates, candidateSeen, "tag", expandedTags[index], 3)
    end
    for index = 1, #tags do
        candidate(candidates, candidateSeen, "tag", tags[index], 2)
    end
    candidate(candidates, candidateSeen, "category", category, 1)
    candidate(candidates, candidateSeen, "primary", primary, 1)
    local price = math.max(0, finite(details.price) or 0)
    local condition = finite(options.condition) or finite(details.condition) or 1
    condition = math.max(0, math.min(1, condition))
    local facts = {
        schemaVersion = 1,
        fullType = bounded(fullType, 160),
        primary = primary, category = category,
        subcategory = bounded(subcategory, 96), leaf = leaf,
        primaryKey = normalized(primary), categoryKey = normalized(category),
        subcategoryKey = normalized(subcategory), leafKey = normalized(leaf),
        tags = tags, expandedTags = expandedTags,
        marketSenseTags = marketSenseTags, tagSet = {}, price = price,
        priceSource = bounded(options.priceSource or details.priceSource
            or "unknown", 64),
        marketRole = role ~= "" and role or nil,
        condition = condition, capabilities = capabilities,
        preferenceCandidates = candidates,
        marketSenseSource = bounded(options.detailsSource or "provided", 64),
    }
    for index = 1, #marketSenseTags do
        facts.tagSet[marketSenseTags[index]] = true
    end
    return facts
end

return Facts
