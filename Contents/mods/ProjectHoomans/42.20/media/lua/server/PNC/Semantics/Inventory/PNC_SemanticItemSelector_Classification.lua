if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Selector = PNC.Semantics.ItemSelector
local Internal = Selector.Internal

function Internal.Normalized(value)
    local text = string.lower(tostring(value or ""))
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text
end

local function addValue(set, value, state)
    if type(value) == "string" or type(value) == "number" then
        local key = Internal.Normalized(value)
        if key ~= "" and not set[key]
            and state.count < Selector.MAX_TAGS
        then
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

function Internal.Classification(fullType, options)
    fullType = tostring(fullType or "")
    if fullType == "" then return nil, "item_type_missing" end
    options = type(options) == "table" and options or {}
    local includeCapabilities = options.includeCapabilities == true
    local cached = Selector.Cache[fullType]
    if cached and (not includeCapabilities
        or cached.capabilitiesReady == true)
    then
        return cached
    end
    local api = marketSense()
    if type(api) ~= "table" or type(api.GetTags) ~= "function" then
        return nil, "classification_unavailable"
    end
    local tagsOK
    local tags
    if cached then
        tagsOK, tags = true, cached.rawTags
    else
        tagsOK, tags = pcall(api.GetTags, fullType)
    end
    if not tagsOK or type(tags) ~= "table" then
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
    local capabilitiesReady = cached and cached.capabilitiesReady == true
        or false
    if includeCapabilities then
        if type(api.GetItemCapabilities) ~= "function" then
            return nil, "classification_capabilities_unavailable"
        end
        local capabilitiesOK, capabilities = pcall(
            api.GetItemCapabilities, fullType)
        if not capabilitiesOK or type(capabilities) ~= "table" then
            return nil, "classification_capabilities_failed"
        end
        for key, value in pairs(capabilities.capabilities or {}) do
            addCapability(capabilitySet, tostring(key), value,
                capabilityState)
        end
        capabilitiesReady = true
    elseif cached then
        capabilitySet = cached.capabilities or capabilitySet
    end
    local result = {
        fullType = fullType,
        primary = Internal.Normalized(tags.primary),
        category = Internal.Normalized(tags.category),
        tags = tagSet,
        capabilities = capabilitySet,
        capabilitiesReady = capabilitiesReady,
        rawTags = tags,
        available = true,
    }
    Selector.Cache[fullType] = result
    return result
end

function Selector.ClearCache(fullType)
    if fullType ~= nil then
        Selector.Cache[tostring(fullType)] = nil
    else
        Selector.Cache = {}
    end
end

return Selector
