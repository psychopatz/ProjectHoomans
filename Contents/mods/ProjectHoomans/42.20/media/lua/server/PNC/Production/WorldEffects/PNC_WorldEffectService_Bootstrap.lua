-- Durable work-order provider and event-hook composition.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Service = PNC.WorldEffectService
local Internal = Service.Internal
local Repository = Internal.Repository or PNC.WorkRepository
local now = Internal.Now
local pointKey = Internal.PointKey

-- Work orders keep their existing durable worldEffect field for compatibility.
-- Lumber and future multi-effect domains can use a list or a domain-owned
-- record through another provider without creating a second retry loop.
Service.RegisterProvider("WORK_ORDER", {
    List = function()
        if Repository and type(Repository.Load) == "function" then
            Repository.Load()
        end
        local output = {}
        for _, order in pairs(Repository and Repository.State
            and Repository.State.byId or {}) do
            if type(order) == "table"
                and (type(order.worldEffect) == "table"
                    or type(order.worldEffects) == "table")
            then output[#output + 1] = order end
        end
        return output
    end,
    GetOwnerID = function(order) return order and order.id end,
    GetEffects = function(order)
        local output = {}
        if type(order and order.worldEffect) == "table" then
            output[#output + 1] = order.worldEffect
        end
        for _, effect in ipairs(order and order.worldEffects or {}) do
            if type(effect) == "table" then output[#output + 1] = effect end
        end
        return output
    end,
    IsPending = function(order, effect)
        if not order or order.status ~= "WORLD_EFFECT_PENDING" then
            return false
        end
        local state = tostring(effect and effect.state or "PENDING")
        return state ~= "APPLIED" and state ~= "CANCELLED"
            and state ~= "CONFLICT" and state ~= "FAILED"
    end,
})

if Events and Events.LoadGridsquare and not Service.LoadSquareHookRegistered then
    Events.LoadGridsquare.Add(function(square)
        if not square then return end
        local x = square.getX and square:getX() or square.x
        local y = square.getY and square:getY() or square.y
        local z = square.getZ and square:getZ() or square.z or 0
        local key = pointKey(x, y, z)
        if key then
            -- A load event is the exact transition the effect was waiting for;
            -- do not make it wait out an older exponential backoff window.
            Service.Reconcile(now(), key, Service.MAX_APPLIES_PER_LOAD, true)
        end
    end)
    Service.LoadSquareHookRegistered = true
end

if Events and Events.OnTick and not Service.TickHookRegistered then
    Events.OnTick.Add(function() Service.Pump() end)
    Service.TickHookRegistered = true
end
