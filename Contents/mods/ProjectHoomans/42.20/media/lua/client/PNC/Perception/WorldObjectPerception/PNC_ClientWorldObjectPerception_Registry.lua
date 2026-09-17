-- Provider registry for client-local world-object perception.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and PsychopatzCore.RuntimeRole.AllowsClientCode
    and not PsychopatzCore.RuntimeRole.AllowsClientCode()
then return end

local Perception = PNC.Perception.WorldObjects

function Perception.RegisterProvider(id, definition)
    id = tostring(id or "")
    if id == "" or type(definition) ~= "table"
        or type(definition.describe) ~= "function"
    then
        return false, "invalid_perception_provider"
    end
    local existing = Perception.Providers[id]
    definition.id = id
    Perception.Providers[id] = definition
    if not existing then
        Perception.ProviderOrder[#Perception.ProviderOrder + 1] = id
    end
    table.sort(Perception.ProviderOrder, function(left, right)
        local a = Perception.Providers[left] or {}
        local b = Perception.Providers[right] or {}
        local ao = tonumber(a.order) or 1000
        local bo = tonumber(b.order) or 1000
        if ao ~= bo then return ao < bo end
        return tostring(left) < tostring(right)
    end)
    Perception.ProviderVersion = Perception.ProviderVersion + 1
    Perception.SnapshotCache = {}
    return true, definition
end

function Perception.GetProvider(id)
    return Perception.Providers[tostring(id or "")]
end

function Perception.ListProviders()
    local output = {}
    for index = 1, #Perception.ProviderOrder do
        local provider = Perception.Providers[Perception.ProviderOrder[index]]
        if provider then
            local fallback = Perception.Internal.Text(provider.label, 64)
            output[#output + 1] = {
                id = provider.id,
                label = fallback or provider.labelKey or provider.id,
                labelKey = provider.labelKey,
                order = tonumber(provider.order) or 1000,
            }
        end
    end
    return output
end

-- Candidate hooks are the cheap pre-scan side of a provider. They decide
-- whether an ordinary loaded-cell object is worth decorating; the provider's
-- `describe` hook still owns the authoritative facts. This keeps generic
-- floor/wall entries out of the bounded perception budget while allowing a
-- future domain (plants, appliances, etc.) to opt in without changing the
-- shared scanner.
function Perception.IsCandidate(object, square, metadata)
    for index = 1, #Perception.ProviderOrder do
        local id = Perception.ProviderOrder[index]
        local provider = Perception.Providers[id]
        if provider and type(provider.candidate) == "function" then
            local ok, accepted = pcall(provider.candidate, object, square,
                metadata)
            if ok and accepted == true then return true end
        end
    end
    return false
end

return Perception
