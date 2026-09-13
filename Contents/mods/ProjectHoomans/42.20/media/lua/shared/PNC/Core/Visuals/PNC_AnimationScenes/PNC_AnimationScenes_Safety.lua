local Scenes = PNC.AnimationScenes
local Core = PNC.Core
local Diagnostics = PNC.PerformanceScalingDiagnostics

local function auditSafety(record, zombie, runtime, scene, reason, now)
    local path = runtime and runtime.pathing or nil
    local navigation = runtime and runtime.localNavigation or nil
    local followState = runtime and runtime.followState or nil
    if not Diagnostics or Diagnostics.SeatingAuditEnabled ~= true
        or not Diagnostics.LogSeatingState
        or not Diagnostics.IsSeatingRuntime
        or not Diagnostics.IsSeatingRuntime(runtime, scene)
    then
        return
    end
    Diagnostics.LogSeatingState(
        "safety_interrupt",
        record,
        zombie,
        scene,
        reason,
        {
            "now=" .. tostring(now or ""),
            "targetKind=" .. tostring(runtime and runtime.target
                and runtime.target.kind or ""),
            "attackAction=" .. tostring(runtime and runtime.attackAction
                or ""),
            "visualMovingUntil=" .. tostring(path
                and path.visualMovingUntil or ""),
            "specialMoveUntil=" .. tostring(path
                and path.specialMoveUntil or ""),
            "safetyNativeActive=" .. tostring(navigation
                and navigation.nativeActive == true),
            "safetyNativeTraversal=" .. tostring(navigation
                and navigation.nativeTraversalState or ""),
            "safetyFollowOwnerMoving=" .. tostring(followState
                and followState.ownerMoving == true),
        }
    )
end

function Scenes.InterruptForSafety(record, zombie, now)
    local runtime = record and record.runtime or nil
    local scene = runtime and runtime.animationScene or nil
    local path = runtime and runtime.pathing or nil
    local navigation = runtime and runtime.localNavigation or nil
    local followState = runtime and runtime.followState or nil
    local health = record and record.health or nil
    local target = runtime and runtime.target or nil
    local hasCombatTarget = type(target) == "table"
        and target.kind ~= nil
    now = tonumber(now) or Core.Now()
    if not scene then return false end
    if hasCombatTarget
        or runtime.attackAction ~= nil
        or now < (tonumber(runtime.inCombatUntil) or 0)
        or now < (tonumber(health and health.recentDamageUntil) or 0)
    then
        if Diagnostics and Diagnostics.SeatingAuditEnabled == true then
            auditSafety(record, zombie, runtime, scene, "combat", now)
        end
        return Scenes.Interrupt(record, zombie, "combat")
    end
    if path and (
            path.phase == "requested"
            or path.phase == "active"
            or now < (tonumber(path.visualMovingUntil) or 0)
            or now < (tonumber(path.specialMoveUntil) or 0)
        )
        or navigation and (
            navigation.nativeActive == true
            or navigation.nativeTraversalState ~= nil
        )
        or followState and followState.ownerMoving == true
    then
        if Diagnostics and Diagnostics.SeatingAuditEnabled == true then
            auditSafety(record, zombie, runtime, scene, "movement", now)
        end
        return Scenes.Interrupt(record, zombie, "movement")
    end
    return false
end
