-- Threat-guard target visibility, hostility, and spatial eligibility.

local ThreatGuard = PNC.BehaviorThreatGuard
local Internal = ThreatGuard.Internal

function Internal.IsThreat(target, threatContext)
    local dx
    local dy
    local radius
    if not target or target.kind == nil
        or not threatContext
    then
        return false
    end
    if target.visible == false and target.proximityAlert ~= true then
        return false
    end
    if target.immediateSelfDefense == true then return true end
    if target.kind ~= "zombie"
        and target.threatening ~= true
        and target.groupAlert ~= true
    then
        return false
    end
    if tonumber(target.z) ~= nil
        and math.abs((tonumber(target.z) or 0) - threatContext.z) >= 1
    then
        return false
    end
    dx = (tonumber(target.x) or 0) - threatContext.x
    dy = (tonumber(target.y) or 0) - threatContext.y
    radius = threatContext.radius
    if target.groupAlert == true then
        radius = math.max(
            radius,
            tonumber(target.alertRadius) or radius
        )
    end
    return dx * dx + dy * dy <= radius * radius
end

return Internal
