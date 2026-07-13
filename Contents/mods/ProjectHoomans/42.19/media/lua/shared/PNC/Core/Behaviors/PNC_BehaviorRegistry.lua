--[[
    PNC Behavior Registry
    Maps selected jobs to self-contained behavior handlers. New behavior types
    can register here without expanding the central behavior coordinator.
]]

PNC = PNC or {}
PNC.BehaviorRegistry = PNC.BehaviorRegistry or {}

local Registry = PNC.BehaviorRegistry

Registry.Handlers = Registry.Handlers or {}

function Registry.Register(job, handler)
    job = tostring(job or "")
    if job == "" or type(handler) ~= "function" then
        return false
    end
    Registry.Handlers[job] = handler
    return true
end

function Registry.Unregister(job)
    job = tostring(job or "")
    if job == "" then return false end
    Registry.Handlers[job] = nil
    return true
end

function Registry.Has(job)
    return type(Registry.Handlers[tostring(job or "")]) == "function"
end

function Registry.Tick(record, zombie, job, now)
    local handler = Registry.Handlers[tostring(job or "")]
    if type(handler) ~= "function" then return false end
    return handler(record, zombie, job, now) == true
end

return Registry
