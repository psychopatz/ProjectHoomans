-- Versioned, capability-based cross-mod actor contract.
--
-- Adapters translate a foreign actor system into stable references. They own
-- their actor lookup, relationship rules, damage implementation, and native
-- presentation. Hoomans core only calls the capabilities that are present.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
PNC.Compatibility.API = PNC.Compatibility.API or {}

local API = PNC.Compatibility.API

API.VERSION = 1
API.Adapters = API.Adapters or {}

local function adapterID(value)
    if value == nil then return nil end
    local id = tostring(value)
    return id ~= "" and id or nil
end

local function hasCapability(adapter, capability)
    return adapter
        and type(adapter.capabilities) == "table"
        and adapter.capabilities[capability] == true
end

function API.RegisterAdapter(specification)
    local id
    local version
    if type(specification) ~= "table" then return false end
    id = adapterID(specification.id)
    version = tonumber(specification.apiVersion) or API.VERSION
    if not id or version > API.VERSION then
        return false
    end
    specification.id = id
    specification.apiVersion = version
    specification.capabilities = specification.capabilities or {}
    API.Adapters[id] = specification
    return true
end

function API.GetAdapter(id)
    return API.Adapters[adapterID(id) or ""]
end

function API.GetAdapters()
    return API.Adapters
end

function API.HasCapability(id, capability)
    return hasCapability(API.GetAdapter(id), capability)
end

-- Third-party callbacks are the only protected boundary here. A broken
-- optional integration must fail closed rather than stop the NPC update loop.
function API.Call(id, method, context)
    local adapter = API.GetAdapter(id)
    local callback
    local ok
    local first
    local second
    local third
    if not adapter or type(method) ~= "string" then
        return false, nil, "adapter_unavailable"
    end
    callback = adapter[method]
    if type(callback) ~= "function" then
        return false, nil, "capability_unavailable"
    end
    ok, first, second, third = pcall(callback, context or {})
    if not ok then
        return false, nil, "adapter_callback_error"
    end
    return true, first, second, third
end

function API.GetActorRef(provider, actor, context)
    local ok
    local reference
    ok, reference = API.Call(provider, "getActorRef", {
        actor = actor,
        context = context,
    })
    return ok and reference or nil
end

function API.ResolveTarget(reference, context)
    if type(reference) ~= "table" then return nil end
    local ok
    local target
    ok, target = API.Call(reference.provider, "resolveTarget", {
        ref = reference,
        context = context,
    })
    return ok and target or nil
end

function API.EnumerateTargets(context)
    local output = {}
    local id
    local adapter
    local ok
    local candidates
    local key
    local candidate
    for id, adapter in pairs(API.Adapters) do
        if hasCapability(adapter, "targeting")
            and type(adapter.enumerateTargets) == "function"
        then
            ok, candidates = API.Call(id, "enumerateTargets", context)
            if ok and type(candidates) == "table" then
                for key, candidate in pairs(candidates) do
                    if type(candidate) == "table" then
                        candidate.provider = candidate.provider or id
                        candidate.actorId = candidate.actorId
                            or candidate.id
                        candidate.kind = candidate.kind or "foreign_npc"
                        output[#output + 1] = candidate
                    end
                end
            end
        end
    end
    return output
end

function API.CanAttack(attacker, target, context)
    local provider = target and target.provider
    local ok
    local allowed
    local reason
    if not provider then return false, "target_provider_missing" end
    if not API.HasCapability(provider, "relationships") then
        return false, "relationship_capability_unavailable"
    end
    ok, allowed, reason = API.Call(provider, "canAttack", {
        attacker = attacker,
        target = target,
        context = context,
    })
    if not ok then return false, reason end
    return allowed == true, reason
end

function API.ApplyDamage(target, context)
    local provider = target and target.provider
    local ok
    local applied
    local reason
    if not provider then return false, "target_provider_missing" end
    if not API.HasCapability(provider, "damage") then
        return false, "damage_capability_unavailable"
    end
    ok, applied, reason = API.Call(provider, "applyDamage", {
        target = target,
        context = context,
    })
    if not ok then return false, reason end
    return applied == true, reason
end

function API.EmitEvent(eventName, context)
    local emitted = 0
    local id
    local adapter
    local ok
    local handled
    if type(eventName) ~= "string" or eventName == "" then
        return 0, "event_name_required"
    end
    for id, adapter in pairs(API.Adapters) do
        if hasCapability(adapter, "events")
            and type(adapter.onEvent) == "function"
        then
            ok, handled = API.Call(id, "onEvent", {
                event = eventName,
                context = context or {},
            })
            if ok and handled == true then
                emitted = emitted + 1
            end
        end
    end
    return emitted, emitted > 0 and "event_handled" or "event_unhandled"
end

return API
