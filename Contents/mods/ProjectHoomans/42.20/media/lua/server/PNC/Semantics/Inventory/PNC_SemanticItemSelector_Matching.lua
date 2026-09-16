if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Selector = PNC.Semantics.ItemSelector
local Internal = Selector.Internal

function Internal.ItemType(item)
    return tostring(item and (item.type or item.fullType) or "")
end

local function searchText(value)
    local text = string.lower(tostring(value or ""))
    text = string.gsub(text, "[^%w]+", " ")
    text = string.gsub(text, "%s+", " ")
    text = string.gsub(text, "^%s+", "")
    return string.gsub(text, "%s+$", "")
end

local function singular(value)
    value = searchText(value)
    if string.sub(value, -3) == "ies" and #value > 3 then
        return string.sub(value, 1, -4) .. "y"
    end
    if string.sub(value, -1) == "s"
        and string.sub(value, -2) ~= "ss"
        and string.sub(value, -2) ~= "us"
        and string.sub(value, -2) ~= "is"
    then
        return string.sub(value, 1, -2)
    end
    return value
end

local function fuzzyLimit(value)
    local length = #tostring(value or "")
    if length < 4 then return 0 end
    return length >= 8 and 2 or 1
end

local function editDistanceAtMost(left, right, limit)
    left = tostring(left or "")
    right = tostring(right or "")
    limit = tonumber(limit) or 0
    if left == right then return true end
    if limit < 1 then return false end
    if math.abs(#left - #right) > limit then return false end

    local previous = {}
    local current
    local row
    local column
    for column = 0, #right do previous[column] = column end
    for row = 1, #left do
        current = { [0] = row }
        for column = 1, #right do
            local cost = string.sub(left, row, row)
                == string.sub(right, column, column) and 0 or 1
            current[column] = math.min(
                current[column - 1] + 1,
                previous[column] + 1,
                previous[column - 1] + cost
            )
        end
        previous = current
    end
    return previous[#right] <= limit
end

local function fuzzySingleWord(query, candidate)
    local limit = fuzzyLimit(query)
    if limit < 1 then return false end
    for token in string.gmatch(candidate, "%S+") do
        if editDistanceAtMost(query, singular(token), limit) then
            return true
        end
    end
    return false
end

function Internal.ItemText(item, fullType)
    local values = {}
    local function add(value)
        value = searchText(value)
        if value ~= "" then values[#values + 1] = value end
    end
    add(item and item.customName)
    add(item and item.displayName)
    add(item and item.itemState and item.itemState.customName)
    add(item and item.itemState and item.itemState.displayName)
    add(fullType or Internal.ItemType(item))
    return table.concat(values, " ")
end

function Internal.TextMatches(item, queryText, fullType)
    local query = searchText(queryText)
    if query == "" then return false end
    local candidate = Internal.ItemText(item, fullType)
    if string.find(candidate, query, 1, true) then return true end
    local reduced = singular(query)
    if reduced ~= query and string.find(candidate, reduced, 1, true)
        ~= nil
    then
        return true
    end
    -- Keep typo recovery deliberately narrow: one short English word and a
    -- maximum edit distance of one (two only for long words). This avoids
    -- turning an item request into an expensive or overly permissive parser.
    return not string.find(query, " ", 1, true)
        and fuzzySingleWord(reduced, candidate)
end

local function requestedValues(value)
    if type(value) == "string" or type(value) == "number" then
        return { Internal.Normalized(value) }
    end
    local values = {}
    if type(value) == "table" then
        for index = 1, #value do
            local entry = Internal.Normalized(value[index])
            if entry ~= "" then values[#values + 1] = entry end
        end
        -- Semantic mentions and MarketSense projections commonly expose
        -- capabilities as a boolean map (`edible = true`) rather than an
        -- array. Accept both shapes at the selector boundary so contextual
        -- references and task requests use the same contract.
        for key, enabled in pairs(value) do
            if type(key) ~= "number" and enabled == true then
                local entry = Internal.Normalized(key)
                if entry ~= "" then values[#values + 1] = entry end
            end
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

function Selector.Matches(item, request)
    request = type(request) == "table" and request or {}
    if type(item) ~= "table" then return false, "item_invalid" end
    local fullType = Internal.ItemType(item)
    if fullType == "" then return false, "item_type_missing" end
    if request.itemID and tostring(request.itemID) ~= tostring(item.id) then
        return false, "item_id_mismatch"
    end
    if request.fullType and tostring(request.fullType) ~= fullType then
        return false, "item_type_mismatch"
    end
    local requestedTags = request.tags or request.tag
    if requestedTags == nil and request.concept ~= nil then
        requestedTags = Selector.TagsForConcept(request.concept)
            or request.concept
    end
    local tags = requestedValues(requestedTags)
    local capabilities = requestedValues(request.capabilities
        or request.capability)
    local hasText = tostring(request.text or "") ~= ""
    if hasText and not Internal.TextMatches(item, request.text, fullType)
    then
        return false, "item_text_mismatch"
    end
    local needsClassification = #tags > 0 or #capabilities > 0
        or request.category ~= nil or request.primary ~= nil
    local details
    local classificationReason
    if needsClassification then
        details, classificationReason = Internal.Classification(fullType, {
            includeCapabilities = #capabilities > 0,
        })
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
    if request.category and details.category ~= Internal.Normalized(
        request.category)
    then
        return false, "item_category_mismatch"
    end
    if request.primary and details.primary ~= Internal.Normalized(
        request.primary)
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

function Internal.Score(item, request, details)
    local value = 0
    if request.itemID and tostring(request.itemID) == tostring(item.id) then
        value = value + 1000
    end
    if request.fullType and tostring(request.fullType) == Internal.ItemType(item)
    then
        value = value + 500
    end
    if request.text and Internal.TextMatches(item, request.text,
        Internal.ItemType(item))
    then
        value = value + 250
    end
    if details then
        if request.category
            and details.category == Internal.Normalized(request.category)
        then value = value + 50 end
        if request.primary
            and details.primary == Internal.Normalized(request.primary)
        then value = value + 50 end
        local requestedTags = request.tags or request.tag
        if requestedTags == nil and request.concept ~= nil then
            requestedTags = Selector.TagsForConcept(request.concept)
                or request.concept
        end
        local tags = requestedValues(requestedTags)
        value = value + #tags * 20
    end
    return value
end

return Selector
