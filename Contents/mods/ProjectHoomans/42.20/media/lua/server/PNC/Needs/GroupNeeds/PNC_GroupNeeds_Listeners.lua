if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Needs = PNC.GroupNeeds

function Needs.RegisterListener(eventName, listener)
    eventName = tostring(eventName or "")
    if eventName == "" or type(listener) ~= "function" then return false end
    Needs.Listeners[eventName] = Needs.Listeners[eventName] or {}
    Needs.Listeners[eventName][#Needs.Listeners[eventName] + 1] = listener
    return true
end

function Needs.UnregisterListener(eventName, listener)
    local listeners = Needs.Listeners[tostring(eventName or "")]
    if type(listeners) ~= "table" or type(listener) ~= "function" then
        return false
    end
    for index = #listeners, 1, -1 do
        if listeners[index] == listener then
            table.remove(listeners, index)
            if #listeners <= 0 then
                Needs.Listeners[tostring(eventName)] = nil
            end
            return true
        end
    end
    return false
end

function Needs.Emit(eventName, ...)
    local listeners = Needs.Listeners[tostring(eventName or "")] or {}
    for index, listener in ipairs(listeners) do
        local ok, listenerError = pcall(listener, ...)
        if not ok and PNC.Core and PNC.Core.LogWarn then
            PNC.Core.LogWarn("PNC group needs listener failed event="
                .. tostring(eventName) .. " index=" .. tostring(index)
                .. " error=" .. tostring(listenerError))
        end
    end
end

return Needs
