local Registry = PNC.Conversation.Registry
local Internal = Registry.Internal

function Registry.RegisterConditionHandler(id, handler)
    id = tostring(id or "")
    if not Internal.ValidID(id) or type(handler) ~= "table"
        or type(handler.evaluate) ~= "function"
        or Registry.conditionHandlers[id]
    then return false end
    Registry.conditionHandlers[id] = Internal.Copy(handler)
    Internal.BumpRevision()
    return true
end

function Registry.UnregisterConditionHandler(id)
    id = tostring(id or "")
    if not Registry.conditionHandlers[id] then return false end
    Registry.conditionHandlers[id] = nil
    Internal.BumpRevision()
    return true
end

function Registry.RegisterEffectHandler(id, handler)
    id = tostring(id or "")
    if not Internal.ValidID(id) or type(handler) ~= "table"
        or type(handler.validate) ~= "function"
        or type(handler.apply) ~= "function"
        or type(handler.simulate) ~= "function"
        or Registry.effectHandlers[id]
    then return false end
    Registry.effectHandlers[id] = Internal.Copy(handler)
    Internal.BumpRevision()
    return true
end

function Registry.UnregisterEffectHandler(id)
    id = tostring(id or "")
    if not Registry.effectHandlers[id] then return false end
    Registry.effectHandlers[id] = nil
    Internal.BumpRevision()
    return true
end
