-- Stable idle behavior for colonists assigned to remain at their settlement.

PNC = PNC or {}
PNC.BehaviorAtHome = PNC.BehaviorAtHome or {}

local AtHome = PNC.BehaviorAtHome
local Common = PNC.BehaviorCommon
local Animation = PNC.Animation

local function normalize(_, spec)
    spec = type(spec) == "table" and spec or {}
    return {
        kind = "colony_home",
        baseId = tostring(spec.baseId or ""),
        x = tonumber(spec.x),
        y = tonumber(spec.y),
        z = tonumber(spec.z) or 0,
        radius = math.max(1, tonumber(spec.radius) or 3),
    }
end

function AtHome.Tick(record, zombie)
    record.activeBehavior = "AtHome"
    if PNC.NavigationRouter and PNC.NavigationRouter.Clear then
        PNC.NavigationRouter.Clear(record)
    end
    Common.HaltMovement(record, zombie, "at_home")
    if zombie and Animation and Animation.Apply then
        Animation.Apply(zombie, record, "Idle")
    end
    return true
end

if PNC.OrderSystem and PNC.OrderSystem.RegisterNormalizer then
    PNC.OrderSystem.RegisterNormalizer("colony_home", normalize)
end
if PNC.JobSystem and PNC.JobSystem.RegisterOrder then
    PNC.JobSystem.RegisterOrder("colony_home", "AtHome")
end
if PNC.BehaviorRegistry and PNC.BehaviorRegistry.Register then
    PNC.BehaviorRegistry.Register("AtHome", AtHome.Tick)
end

return AtHome
