--[[
    Generic NPC knowledge extension registry.

    Definitions live in trusted bootstrap Lua only. Persistent notes store IDs
    and primitive values, never definition tables, providers, or engine data.
]]

PNC = PNC or {}
PNC.KnowledgeDescriptors = PNC.KnowledgeDescriptors or {}
PNC.KnowledgeProviders = PNC.KnowledgeProviders or {}
PNC.KnowledgeResolvers = PNC.KnowledgeResolvers or {}
PNC.KnowledgeEvidenceSources = PNC.KnowledgeEvidenceSources or {}
PNC.KnowledgeCategories = PNC.KnowledgeCategories or {}
PNC.KnowledgeRegistry = PNC.KnowledgeRegistry or {}

local Descriptors = PNC.KnowledgeDescriptors
local Providers = PNC.KnowledgeProviders
local Resolvers = PNC.KnowledgeResolvers
local Sources = PNC.KnowledgeEvidenceSources
local Categories = PNC.KnowledgeCategories
local Registry = PNC.KnowledgeRegistry

Descriptors.byID = Descriptors.byID or {}
Providers.byID = Providers.byID or {}
Resolvers.byID = Resolvers.byID or {}
Sources.byID = Sources.byID or {}
Categories.byID = Categories.byID or {}

Registry.VALUE_TYPES = Registry.VALUE_TYPES or {
    categorical = true, boolean = true, band = true, scalar = true,
    text_enum = true, entity_reference = true,
}
Registry.PRIVACY = Registry.PRIVACY or {
    public = true, obvious = true, observable = true, personal = true,
    private = true, secret = true,
}

local function copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return nil end
    seen[value] = true
    local output = {}
    for key, item in pairs(value) do
        output[copy(key, seen)] = copy(item, seen)
    end
    seen[value] = nil
    return output
end

local function finite(value)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then return nil end
    return value
end

function Registry.IsID(value)
    return type(value) == "string" and #value > 0 and #value <= 128
        and string.match(value, "^[%w_%-%.]+$") ~= nil
end

function Registry.Clamp(value, minimum, maximum)
    value = finite(value) or minimum
    return math.max(minimum, math.min(maximum, value))
end

-- Only tables containing primitive string/number/boolean values are accepted
-- as evidence payloads. This is intentionally smaller than arbitrary ModData.
function Registry.SanitizePayload(value, depth, budget)
    local valueType = type(value)
    local output
    local key
    local item
    if value == nil then return nil, true end
    if valueType == "string" then
        if #value > 128 or string.find(value, "%c") then return nil, false end
        return value, true
    end
    if valueType == "boolean" then return value, true end
    if valueType == "number" then
        value = finite(value)
        return value, value ~= nil
    end
    if valueType ~= "table" or getmetatable(value) ~= nil then
        return nil, false
    end
    depth = depth or 0
    budget = budget or { count = 0, seen = {} }
    if depth >= 2 or budget.seen[value] then return nil, false end
    budget.seen[value] = true
    output = {}
    for key, item in pairs(value) do
        budget.count = budget.count + 1
        if budget.count > 16 or (type(key) ~= "string" and type(key) ~= "number") then
            budget.seen[value] = nil
            return nil, false
        end
        local safeKey, keyOK = Registry.SanitizePayload(key, depth + 1, budget)
        local safeItem, itemOK = Registry.SanitizePayload(item, depth + 1, budget)
        if not keyOK or not itemOK then
            budget.seen[value] = nil
            return nil, false
        end
        output[safeKey] = safeItem
    end
    budget.seen[value] = nil
    return output, true
end

function Categories.Register(definition)
    if type(definition) ~= "table" or not Registry.IsID(definition.id) then
        return false, "invalid_category"
    end
    if Categories.byID[definition.id] then return false, "duplicate_category" end
    Categories.byID[definition.id] = {
        id = definition.id,
        nameKey = definition.nameKey,
        sortOrder = math.floor(finite(definition.sortOrder) or 999),
        defaultExpanded = definition.defaultExpanded == true,
        icon = type(definition.icon) == "string" and definition.icon or nil,
    }
    return true
end

function Categories.Get(id)
    return Categories.byID[tostring(id or "")]
end

function Categories.List()
    local output = {}
    for _, definition in pairs(Categories.byID) do output[#output + 1] = copy(definition) end
    table.sort(output, function(a, b)
        if a.sortOrder == b.sortOrder then return a.id < b.id end
        return a.sortOrder < b.sortOrder
    end)
    return output
end

function Providers.Register(id, provider)
    if not Registry.IsID(id) or type(provider) ~= "table"
        or type(provider.GetValue) ~= "function"
    then return false, "invalid_provider" end
    if Providers.byID[id] then return false, "duplicate_provider" end
    Providers.byID[id] = provider
    return true
end

function Providers.Get(id)
    return Providers.byID[tostring(id or "")]
end

function Providers.GetTruth(npcRecord, descriptor)
    local provider = descriptor and Providers.Get(descriptor.providerID) or nil
    if not provider then return nil, "unknown_provider" end
    local ok, value, reason = pcall(provider.GetValue, npcRecord, descriptor)
    if not ok then return nil, "provider_failed" end
    if value == nil then return nil, reason or "truth_unavailable" end
    local safe, valid = Registry.SanitizePayload(value)
    if not valid then return nil, "unsafe_truth_value" end
    return safe, reason
end

function Sources.Register(id, definition)
    if not Registry.IsID(id) or type(definition) ~= "table" then
        return false, "invalid_evidence_source"
    end
    if Sources.byID[id] then return false, "duplicate_evidence_source" end
    Sources.byID[id] = {
        id = id,
        reliability = Registry.Clamp(definition.reliability, 0, 1),
        mayConfirm = definition.mayConfirm == true,
        bypassFamiliarity = definition.bypassFamiliarity == true,
    }
    return true
end

function Sources.Get(id)
    return Sources.byID[tostring(id or "")]
end

function Resolvers.Register(id, resolver)
    if not Registry.IsID(id) or type(resolver) ~= "table"
        or type(resolver.Resolve) ~= "function"
    then return false, "invalid_resolver" end
    if Resolvers.byID[id] then return false, "duplicate_resolver" end
    Resolvers.byID[id] = resolver
    return true
end

function Resolvers.Get(id)
    return Resolvers.byID[tostring(id or "")]
end

function Descriptors.Register(definition, allowOverride)
    local discovery
    local capabilities
    if type(definition) ~= "table" or not Registry.IsID(definition.id)
        or not Registry.IsID(definition.category)
        or not Registry.IsID(definition.providerID)
        or not Registry.IsID(definition.resolverID)
        or not Registry.VALUE_TYPES[definition.valueType]
        or not Registry.PRIVACY[definition.privacy]
    then return false, "invalid_descriptor" end
    if not Categories.Get(definition.category) then return false, "unknown_category" end
    if Descriptors.byID[definition.id] and allowOverride ~= true then
        return false, "duplicate_descriptor"
    end
    discovery = type(definition.discovery) == "table" and definition.discovery or {}
    capabilities = type(definition.capabilities) == "table" and definition.capabilities or {}
    Descriptors.byID[definition.id] = {
        id = definition.id,
        version = math.max(1, math.floor(finite(definition.version) or 1)),
        category = definition.category,
        providerID = definition.providerID,
        resolverID = definition.resolverID,
        valueType = definition.valueType,
        privacy = definition.privacy,
        presentation = copy(type(definition.presentation) == "table" and definition.presentation or {}),
        discovery = {
            allowInference = discovery.allowInference == true,
            allowObservation = discovery.allowObservation == true,
            allowDisclosure = discovery.allowDisclosure == true,
            allowGossip = discovery.allowGossip == true,
            suspectedThreshold = Registry.Clamp(discovery.suspectedThreshold or 0.30, 0, 1),
            knownThreshold = Registry.Clamp(discovery.knownThreshold or 0.70, 0, 1),
            minimumFamiliarity = math.max(0, finite(discovery.minimumFamiliarity) or 0),
            minimumApproval = finite(discovery.minimumApproval),
        },
        capabilities = {
            observable = capabilities.observable == true,
            disclosable = capabilities.disclosable == true,
            inferable = capabilities.inferable == true,
            gossipable = capabilities.gossipable == true,
            decayable = capabilities.decayable == true,
        },
        aliases = copy(type(definition.aliases) == "table" and definition.aliases or {}),
    }
    return true
end

function Descriptors.Get(id)
    id = tostring(id or "")
    if Descriptors.byID[id] then return Descriptors.byID[id] end
    for _, descriptor in pairs(Descriptors.byID) do
        for index = 1, #descriptor.aliases do
            if descriptor.aliases[index] == id then return descriptor end
        end
    end
    return nil
end

function Descriptors.List()
    local output = {}
    for _, descriptor in pairs(Descriptors.byID) do output[#output + 1] = copy(descriptor) end
    table.sort(output, function(a, b)
        local categoryA = Categories.Get(a.category) or {}
        local categoryB = Categories.Get(b.category) or {}
        if categoryA.sortOrder == categoryB.sortOrder then return a.id < b.id end
        return (categoryA.sortOrder or 999) < (categoryB.sortOrder or 999)
    end)
    return output
end

function Descriptors.ListByCategory(category)
    local output = {}
    for _, descriptor in ipairs(Descriptors.List()) do
        if descriptor.category == category then output[#output + 1] = descriptor end
    end
    return output
end

return Registry
