-- Stable idle behavior for colonists assigned to remain at their settlement.

PNC = PNC or {}
PNC.BehaviorAtHome = PNC.BehaviorAtHome or {}

local AtHome = PNC.BehaviorAtHome
local Common = PNC.BehaviorCommon
local Animation = PNC.Animation
local Const = PNC.Const

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
    local Companion = PNC.BehaviorCompanion
    local order = record.orderSpec or {}
    local anchorX = tonumber(order.x) or record.anchorX or record.x
    local anchorY = tonumber(order.y) or record.anchorY or record.y
    local anchorZ = tonumber(order.z) or record.anchorZ or record.z or 0
    local radius = math.max(1, tonumber(order.radius)
        or tonumber(Const and Const.GUARD_ENGAGE_RADIUS)
        or tonumber(Const and Const.GUARD_RADIUS) or 3)
    local engaged = Companion and Companion.Internal
        and Companion.Internal.TryRespondToThreat
        and Companion.Internal.TryRespondToThreat(
            record,
            zombie,
            { x = anchorX, y = anchorY, z = anchorZ, radius = radius },
            { areaDefense = true }
        )
    if engaged then
        record.activeBehavior = "AtHome:combat"
        return true
    end

    -- Existing saves may still have a colony_home order anchored to the
    -- former stockpile point. Ask the authority-side home service to repair
    -- that anchor before this behavior freezes the actor in place. A repair
    -- creates the normal durable travel order, so the Travel behavior owns
    -- movement on the next tick for both live and abstract NPCs.
    local homeService = PNC.HomeDutyService
    if homeService and homeService.EnsureHomeAnchor then
        local repaired, repairState = homeService.EnsureHomeAnchor(
            record, order.baseId, "idle_home_anchor")
        if repaired and repairState == "RETURNING_HOME" then
            record.activeBehavior = "AtHome:returning"
            return true
        end
    end

    record.activeBehavior = "AtHome"
    if PNC.NavigationRouter and PNC.NavigationRouter.Clear then
        PNC.NavigationRouter.Clear(record)
    end
    Common.ClearCombatTarget(record, "at_home", zombie)
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
