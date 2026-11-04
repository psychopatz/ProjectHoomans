-- Optional external conversation openers.
--
-- Project Hoomans owns the native context-menu surface, but a compatible
-- integration may own the conversation content and authorization transport.
-- The registry keeps that handoff explicit without making PNC depend on any
-- provider mod.

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Openers = PNC.Conversation.Openers or {}
PNC.Conversation.Openers = Openers
Openers.Providers = Openers.Providers or {}
Openers.ProviderOrder = Openers.ProviderOrder or {}

local function appendUnique(value)
    for _, existing in ipairs(Openers.ProviderOrder) do
        if existing == value then return end
    end
    Openers.ProviderOrder[#Openers.ProviderOrder + 1] = value
end

local function sortProviders()
    table.sort(Openers.ProviderOrder, function(left, right)
        local a = Openers.Providers[left] or {}
        local b = Openers.Providers[right] or {}
        local pa = tonumber(a.priority) or 50
        local pb = tonumber(b.priority) or 50
        if pa ~= pb then return pa > pb end
        return tostring(left) < tostring(right)
    end)
end

function Openers.Register(spec)
    if type(spec) ~= "table" then
        return false, "opener_spec_required"
    end
    local id = tostring(spec.id or "")
    if id == "" then return false, "opener_id_required" end
    if type(spec.open) ~= "function" then
        return false, "opener_callback_required"
    end
    Openers.Providers[id] = {
        id = id,
        priority = tonumber(spec.priority) or 50,
        canOpen = spec.canOpen,
        open = spec.open,
    }
    appendUnique(id)
    sortProviders()
    return true, id
end

function Openers.Unregister(id)
    id = tostring(id or "")
    if not Openers.Providers[id] then return false end
    Openers.Providers[id] = nil
    for index = #Openers.ProviderOrder, 1, -1 do
        if Openers.ProviderOrder[index] == id then
            table.remove(Openers.ProviderOrder, index)
        end
    end
    return true
end

function Openers.Try(entry, player)
    for _, id in ipairs(Openers.ProviderOrder) do
        local provider = Openers.Providers[id]
        local eligible = true
        if provider and type(provider.canOpen) == "function" then
            local ok, value = pcall(provider.canOpen, entry, player)
            eligible = ok and value == true
        end
        if eligible and provider then
            local ok, result, reason = pcall(
                provider.open,
                entry,
                player
            )
            if not ok then
                return true, false, "external_opener_failed"
            end
            return true, result, reason
        end
    end
    return false, nil, "no_external_opener"
end

return Openers
