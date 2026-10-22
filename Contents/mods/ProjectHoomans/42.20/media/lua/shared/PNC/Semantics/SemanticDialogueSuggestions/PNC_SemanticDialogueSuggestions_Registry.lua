-- Bounded, versioned choice-provider registry.
--
-- Providers contribute declarative candidates.  This module owns only the
-- reusable registration, normalization, ordering, and dedupe mechanism; it
-- does not evaluate gameplay authority or execute a choice.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Registry = PNC.Semantics.DialogueChoiceRegistry or {}
PNC.Semantics.DialogueChoiceRegistry = Registry

Registry.VERSION = 1
Registry.CANDIDATE_SCHEMA = "semantic.choice.v1"
Registry.MAX_PROVIDERS = 32
Registry.MAX_CANDIDATES = 24

-- Generic collection consumes the already-presented candidate contract. The
-- legacy Project Hoomans static/capability providers remain registered for
-- their authoritative eligibility adapters, but raw definitions must not
-- bypass those adapters merely because they are discoverable in the registry.
local function isCanonicalCandidate(candidate)
    return type(candidate) == "table"
        and type(candidate.frame) == "table"
        and type(candidate.display) == "table"
end

local providers = Registry._providers or {}
Registry._providers = providers

local function validID(value)
    value = tostring(value or "")
    return value ~= "" and string.find(value, "[^%w_%.%-]") == nil
end

local function providerOrder(left, right)
    local leftOrder = tonumber(left.order) or 0
    local rightOrder = tonumber(right.order) or 0
    if leftOrder ~= rightOrder then return leftOrder < rightOrder end
    return tostring(left.id) < tostring(right.id)
end

local function copyProvider(provider)
    return {
        id = provider.id,
        sourceKind = provider.sourceKind,
        order = tonumber(provider.order) or 0,
        enabled = provider.enabled ~= false,
    }
end

function Registry.RegisterProvider(provider)
    if type(provider) ~= "table" then
        return false, "provider_must_be_object"
    end
    local id = tostring(provider.id or "")
    if not validID(id) then return false, "provider_id_invalid" end
    if type(provider.collect) ~= "function" then
        return false, "provider_collect_required"
    end
    if providers[id] == nil then
        local count = 0
        for _ in pairs(providers) do count = count + 1 end
        if count >= Registry.MAX_PROVIDERS then
            return false, "provider_limit"
        end
    end
    providers[id] = provider
    return true, "registered"
end

function Registry.GetProvider(id)
    return providers[tostring(id or "")]
end

function Registry.ProviderForSourceKind(sourceKind)
    local candidates = Registry.ListProviders()
    for _, summary in ipairs(candidates) do
        if summary.sourceKind == sourceKind then return summary.id end
    end
    return nil
end

function Registry.ListProviders()
    local output = {}
    for _, provider in pairs(providers) do
        if provider.enabled ~= false then
            output[#output + 1] = copyProvider(provider)
        end
    end
    table.sort(output, providerOrder)
    return output
end

function Registry.NormalizeCandidate(candidate, providerID, localOrder)
    if type(candidate) ~= "table" then
        return nil, "candidate_must_be_object"
    end
    local id = tostring(candidate.id or candidate.candidateID or "")
    if id == "" then return nil, "candidate_id_required" end
    local provider = Registry.GetProvider(providerID)
    if not provider then return nil, "provider_unknown" end
    if provider.enabled == false then return nil, "provider_disabled" end

    local output = {}
    local key
    local value
    for key, value in pairs(candidate) do output[key] = value end
    output.id = id
    output.candidateSchema = candidate.candidateSchema
        or Registry.CANDIDATE_SCHEMA
    output.providerID = candidate.providerID or provider.id
    output.providerOrder = tonumber(candidate.providerOrder)
        or tonumber(provider.order) or 0
    output.rank = tonumber(candidate.rank) or tonumber(localOrder) or 0

    local source = type(candidate.source) == "table"
        and candidate.source or {}
    local normalizedSource = {}
    for key, value in pairs(source) do normalizedSource[key] = value end
    normalizedSource.providerID = normalizedSource.providerID
        or output.providerID
    normalizedSource.kind = normalizedSource.kind
        or provider.sourceKind
    output.source = normalizedSource
    return output
end

function Registry.NormalizeList(candidates, providerID, maximum)
    maximum = tonumber(maximum) or Registry.MAX_CANDIDATES
    if type(candidates) ~= "table" then return {}, "candidates_invalid" end
    local output = {}
    local seen = {}
    local provider = Registry.GetProvider(providerID)
    if not provider then return {}, "provider_unknown" end
    for index = 1, #candidates do
        if #output >= maximum then break end
        local candidate = Registry.NormalizeCandidate(
            candidates[index], providerID, index
        )
        if candidate and not seen[candidate.id] then
            seen[candidate.id] = true
            output[#output + 1] = candidate
        end
    end
    return output, "normalized"
end

function Registry.Collect(context, maximum)
    maximum = tonumber(maximum) or Registry.MAX_CANDIDATES
    local output = {}
    local seen = {}
    local providersInOrder = Registry.ListProviders()
    for _, summary in ipairs(providersInOrder) do
        if #output >= maximum then break end
        local provider = Registry.GetProvider(summary.id)
        local ok, candidates = pcall(provider.collect, context)
        if ok and type(candidates) == "table" then
            for index = 1, #candidates do
                if #output >= maximum then break end
                local candidate = Registry.NormalizeCandidate(
                    candidates[index], provider.id, index
                )
                if candidate and isCanonicalCandidate(candidate)
                    and not seen[candidate.id]
                then
                    seen[candidate.id] = true
                    output[#output + 1] = candidate
                end
            end
        end
    end
    return output
end

-- Optional/domain adapters can contribute through the same provider contract
-- without forcing the central projection to invoke every provider twice.
function Registry.CollectProvider(providerID, context, maximum)
    maximum = tonumber(maximum) or Registry.MAX_CANDIDATES
    local provider = Registry.GetProvider(providerID)
    if not provider or provider.enabled == false then return {} end
    local ok, candidates = pcall(provider.collect, context)
    if not ok or type(candidates) ~= "table" then return {} end
    return Registry.NormalizeList(candidates, provider.id, maximum)
end

function Registry.Snapshot()
    return {
        schemaVersion = Registry.VERSION,
        candidateSchema = Registry.CANDIDATE_SCHEMA,
        providers = Registry.ListProviders(),
    }
end

return Registry
