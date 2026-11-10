-- Optional-provider projection policy.
--
-- Core SurvivorWorld records remain canonical when an adopter is disabled.
-- Project Hoomans only projects a provider-owned actor while that provider is
-- available for the current session. Future providers can register their own
-- availability checker without making PNC depend on their package.

PNC = PNC or {}
PNC.OptionalProviderPolicy = PNC.OptionalProviderPolicy or {}

local Policy = PNC.OptionalProviderPolicy
local Checkers = Policy.Checkers or {}
Policy.Checkers = Checkers

local ACTOR_IDENTITY_EXTENSION = "PsychopatzCore.ActorIdentity"
local CORE_PROVIDER_IDS = {
    PsychopatzCore = true,
    ProjectHoomans = true,
}
local REQUIRED_OPTIONAL_PROVIDERS = {
    DTHoomans = true,
    DTAbstract = true,
}

local function text(value)
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function globalAvailability(providerID)
    local namespace = string.match(providerID, "^[%w_]+")
    local value = namespace and _G[namespace] or nil
    if type(value) == "table" and value.Enabled ~= nil then
        return value.Enabled ~= false
    end
    return nil
end

function Policy.Register(providerID, checker)
    providerID = text(providerID)
    if not providerID or type(checker) ~= "function" then
        return false, "invalid_provider_checker"
    end
    Checkers[providerID] = checker
    return true, "registered"
end

function Policy.IsAvailable(providerID)
    providerID = text(providerID)
    if not providerID or CORE_PROVIDER_IDS[providerID] then
        return true
    end
    local checker = Checkers[providerID]
    if checker then
        local ok, available = pcall(checker, providerID)
        return ok and available == true
    end
    local global = globalAvailability(providerID)
    if global ~= nil then return global == true end
    if REQUIRED_OPTIONAL_PROVIDERS[providerID] then return false end
    return true
end

local function actorProviderID(actor)
    local extensions = actor
        and type(actor.extensions) == "table"
        and actor.extensions or {}
    local identity = extensions[ACTOR_IDENTITY_EXTENSION]
    local provider = type(identity) == "table"
        and (identity.providerID or identity.provider) or nil
    return text(provider)
end

function Policy.ProviderID(actor, entry)
    local provider = actorProviderID(actor)
    if provider then return provider end
    return text(entry and (entry.providerID or entry.provider))
end

local function optionalArchetype(archetypeID)
    archetypeID = text(archetypeID)
    if not archetypeID then return false end
    return archetypeID == "trader"
        or string.sub(archetypeID, 1, 3) == "DT."
end

function Policy.ShouldProject(actor, entry)
    local provider = Policy.ProviderID(actor, entry)
    if provider and not CORE_PROVIDER_IDS[provider] then
        return Policy.IsAvailable(provider)
    end
    local archetypeID = text(entry and entry.factionArchetypeID)
    if optionalArchetype(archetypeID) then
        return Policy.IsAvailable("DTHoomans")
    end
    return true
end

function Policy.MarkUnavailable(record, reason)
    if type(record) ~= "table" then return false end
    record.runtime = record.runtime or {}
    record.runtime.providerUnavailable = true
    record.runtime.providerUnavailableReason = tostring(
        reason or "optional_provider_unavailable")
    record.available = false
    return true
end

function Policy.ClearUnavailable(record)
    if type(record) ~= "table" then return false end
    local changed = false
    record.runtime = record.runtime or {}
    if record.runtime.providerUnavailable ~= nil then
        record.runtime.providerUnavailable = nil
        record.runtime.providerUnavailableReason = nil
        changed = true
    end
    if record.available == false then
        record.available = true
        changed = true
    end
    return changed
end

return Policy
