-- Matches stable item identity, MarketSense criteria, and stack limits.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Selector = PNC.Semantics.ItemSelector
local Internal = Selector.Internal

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

local function containsAnyTagGroup(set, groups)
    if type(groups) ~= "table" then return false end
    for groupIndex = 1, #groups do
        local values = requestedValues(groups[groupIndex])
        if #values > 0 and containsAll(set, values) then return true end
    end
    return false
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
    local requestedCapabilities = request.capabilities
        or request.capability
    local requestedAlternatives = type(request.tagAlternatives) == "table"
        and #request.tagAlternatives > 0 and request.tagAlternatives or nil
    if requestedTags == nil and request.concept ~= nil then
        requestedTags = Selector.TagsForConcept(request.concept)
        requestedAlternatives = requestedAlternatives
            or Selector.TagAlternativesForConcept
                and Selector.TagAlternativesForConcept(request.concept)
            or nil
        if requestedTags == nil and requestedCapabilities == nil then
            requestedCapabilities = Selector.CapabilitiesForConcept
                and Selector.CapabilitiesForConcept(request.concept) or nil
        end
        if requestedTags == nil and requestedCapabilities == nil
            and requestedAlternatives == nil
        then
            requestedTags = request.concept
        end
    end
    local tags = requestedValues(requestedTags)
    local capabilities = requestedValues(requestedCapabilities)
    local hasTagAlternatives = type(requestedAlternatives) == "table"
        and #requestedAlternatives > 0
    local hasText = tostring(request.text or "") ~= ""
    if hasText and not Internal.TextMatches(item, request.text, fullType)
    then
        return false, "item_text_mismatch"
    end
    local needsClassification = #tags > 0 or #capabilities > 0
        or hasTagAlternatives
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
    if hasTagAlternatives
        and not containsAnyTagGroup(details.tags, requestedAlternatives)
    then
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
        local requestedCapabilities = request.capabilities
            or request.capability
        local requestedAlternatives = type(request.tagAlternatives) == "table"
            and #request.tagAlternatives > 0
            and request.tagAlternatives or nil
        if requestedTags == nil and request.concept ~= nil then
            requestedTags = Selector.TagsForConcept(request.concept)
            requestedAlternatives = requestedAlternatives
                or Selector.TagAlternativesForConcept
                    and Selector.TagAlternativesForConcept(request.concept)
                or nil
            if requestedTags == nil and requestedCapabilities == nil then
                requestedCapabilities = Selector.CapabilitiesForConcept
                    and Selector.CapabilitiesForConcept(request.concept)
                    or nil
            end
            if requestedTags == nil and requestedCapabilities == nil
                and requestedAlternatives == nil
            then
                requestedTags = request.concept
            end
        end
        local tags = requestedValues(requestedTags)
        local capabilities = requestedValues(requestedCapabilities)
        local alternativeCount = 0
        if type(requestedAlternatives) == "table"
            and type(requestedAlternatives[1]) == "table"
        then
            alternativeCount = #requestedValues(requestedAlternatives[1])
        end
        value = value + (#tags + #capabilities + alternativeCount) * 20
    end
    return value
end

return Selector
