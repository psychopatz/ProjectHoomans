-- Interrupt automatic ambient seating when a nearby hostile becomes visible.
-- The underlying facility activity remains authoritative so the NPC can
-- resume its seat after the transient combat response ends.

PNC = PNC or {}
PNC.BehaviorSeatedThreat = PNC.BehaviorSeatedThreat or {}

local SeatedThreat = PNC.BehaviorSeatedThreat
local Targeting = PNC.BehaviorTargeting
local Perception = PNC.Perception
local BehaviorCombat = PNC.BehaviorCombat
local Common = PNC.BehaviorCommon
local Scenes = PNC.AnimationScenes
local Const = PNC.Const

local FACILITY_ORDER = "facility_activity"
local CAMP_ORDER = "camp"
local HOME_ORDER = "colony_home"
local SCAN_MS = tonumber(Const and Const.SEATED_THREAT_SCAN_MS) or 750
local VALIDATE_MS = tonumber(Const and Const.SEATED_THREAT_VALIDATE_MS) or 250

local function currentTime(value)
    return tonumber(value) or PNC.Core.Now()
end

local function isFacilityActivity(record)
    local runtime = record and record.runtime or nil
    local activity = runtime and runtime.facilityActivity or nil
    local order = record and record.orderSpec or nil
    local previous = activity and activity.previousOrder or nil
    local previousKind = tostring(previous and previous.kind or "")
    return order and tostring(order.kind or "") == FACILITY_ORDER
        and activity ~= nil
        and activity.automatic == true
        and activity.seating == true
        and tostring(activity.taskLeaseId or "") == ""
        and (previousKind == CAMP_ORDER or previousKind == HOME_ORDER)
end

local function isSeatingScene(scene)
    return scene and scene.blocking == true
end

local function activityContext(record)
    local runtime = record and record.runtime or nil
    local activity = runtime and runtime.facilityActivity or {}
    local previous = activity.previousOrder or {}
    local kind = tostring(previous.kind or "")
    local x = tonumber(previous.x)
        or tonumber(activity.campX)
        or tonumber(record and record.x)
        or 0
    local y = tonumber(previous.y)
        or tonumber(activity.campY)
        or tonumber(record and record.y)
        or 0
    local z = tonumber(previous.z)
        or tonumber(activity.campZ)
        or tonumber(record and record.z)
        or 0
    local radius
    if kind == CAMP_ORDER then
        radius = tonumber(Const and Const.CAMP_ENGAGE_RADIUS)
            or tonumber(activity.campRadius)
            or tonumber(Const and Const.CAMP_RADIUS)
            or 3
    else
        radius = tonumber(previous.radius)
            or tonumber(Const and Const.GUARD_ENGAGE_RADIUS)
            or tonumber(Const and Const.GUARD_RADIUS)
            or 3
    end
    return {
        kind = kind,
        x = x,
        y = y,
        z = z,
        radius = math.max(0.5, radius),
    }
end

local function withinContext(target, context)
    local dx
    local dy
    if not target or not context then return false end
    if tonumber(target.z) ~= nil
        and math.abs((tonumber(target.z) or 0) - context.z) >= 1
    then
        return false
    end
    dx = (tonumber(target.x) or 0) - context.x
    dy = (tonumber(target.y) or 0) - context.y
    return (dx * dx) + (dy * dy) <= context.radius * context.radius
end

local function isSeatedThreat(target)
    return target
        and target.kind == "zombie"
        and target.visible ~= false
        and (
            target.immediateSelfDefense == true
                or target.threatening == true
        )
        or false
end

local function targetInWorld(record, target)
    if not target or not Targeting
        or not Targeting.UpdateTargetFromWorld
    then
        return nil
    end
    return Targeting.UpdateTargetFromWorld(record, target)
end

local function shouldScan(runtime, now)
    if now < (tonumber(runtime.seatedThreatNextScanAt) or 0) then
        return false
    end
    runtime.seatedThreatNextScanAt = now + SCAN_MS
    return true
end

local function resolveTarget(record, runtime, context, now)
    local current
    local target
    if runtime.target then
        if now < (tonumber(runtime.seatedThreatNextValidateAt) or 0) then
            if isSeatedThreat(runtime.target)
                and withinContext(runtime.target, context)
            then
                return runtime.target
            end
            runtime.target = nil
        else
            current = targetInWorld(record, runtime.target)
            runtime.seatedThreatNextValidateAt = now + VALIDATE_MS
            if current
                and isSeatedThreat(current)
                and withinContext(current, context)
            then
                return current
            end
            runtime.target = nil
        end
    end
    if not shouldScan(runtime, now)
        or not Perception
        or not Perception.FindImmediateZombieThreat
    then
        return nil
    end
    target = Perception.FindImmediateZombieThreat(record, context.radius)
    if not isSeatedThreat(target) or not withinContext(target, context) then
        return nil
    end
    runtime.seatedThreatNextValidateAt = now + VALIDATE_MS
    return target
end

local function clearTransientState(record, zombie, reason)
    local runtime = record.runtime or {}
    if Common and Common.ClearCombatTarget then
        Common.ClearCombatTarget(
            record,
            reason or "seated_combat_resolved",
            zombie
        )
    end
    runtime.seatedThreat = nil
    runtime.seatedThreatNextScanAt = nil
    runtime.seatedThreatNextValidateAt = nil
end

local function continueCombat(record, zombie, now, state)
    local runtime = record.runtime or {}
    local context = activityContext(record)
    local target = resolveTarget(record, runtime, context, now)
    if not target then
        clearTransientState(record, zombie, "seated_combat_resolved")
        return false
    end
    runtime.target = target
    record.activeBehavior = "Seated:combat"
    if BehaviorCombat and BehaviorCombat.TickEngage then
        BehaviorCombat.TickEngage(record, zombie, target)
    end
    state.lastTargetKind = tostring(target.kind or "unknown")
    return true
end

local function enterCombat(record, zombie, now, scene)
    local runtime = record.runtime or {}
    local context = activityContext(record)
    local target = resolveTarget(record, runtime, context, now)
    local interrupted
    if not target then return false end
    if not Scenes or not Scenes.Interrupt then return false end
    interrupted = Scenes.Interrupt(record, zombie, "combat")
    if interrupted ~= true then return false end
    runtime.target = target
    runtime.seatedThreat = {
        active = true,
        enteredAt = now,
        sceneId = tostring(scene and scene.id or ""),
        contextKind = context.kind,
        lastTargetKind = tostring(target.kind or "unknown"),
    }
    record.activeBehavior = "Seated:combat"
    if BehaviorCombat and BehaviorCombat.TickEngage then
        BehaviorCombat.TickEngage(record, zombie, target)
    end
    return true
end

function SeatedThreat.Tick(record, zombie, now)
    local runtime = record and record.runtime or nil
    local activity = runtime and runtime.facilityActivity or nil
    local scene = runtime and runtime.animationScene or nil
    local state = runtime and runtime.seatedThreat or nil
    now = currentTime(now)
    if not runtime or not activity then return false end

    if state and state.active == true then
        if not isFacilityActivity(record) or not zombie then
            runtime.seatedThreat = nil
            return false
        end
        return continueCombat(record, zombie, now, state)
    end

    if not zombie or not isFacilityActivity(record)
        or not isSeatingScene(scene)
    then
        return false
    end
    return enterCombat(record, zombie, now, scene)
end

return SeatedThreat
