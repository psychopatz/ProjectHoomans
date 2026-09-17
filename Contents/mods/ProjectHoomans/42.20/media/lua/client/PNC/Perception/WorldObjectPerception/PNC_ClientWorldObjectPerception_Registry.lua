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

return Perception
