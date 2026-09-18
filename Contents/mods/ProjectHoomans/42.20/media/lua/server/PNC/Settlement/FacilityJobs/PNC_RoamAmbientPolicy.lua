-- Eligibility and deterministic time policy for roaming ambience.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.RoamAmbient = PNC.RoamAmbient or {}

local Service = PNC.RoamAmbient
local Core = PNC.Core
local Const = PNC.Const or {}
local ActorControl = PNC.ActorControl
    or require "PNC/Core/ActorControl/PNC_ActorControl"

Service.NextAttemptAt = Service.NextAttemptAt or {}
Service.CADENCE_MS = 5000
Service.MIN_IDLE_MS = 1200
Service.MAX_ATTEMPTS_PER_TICK = 4
Service.ACTION_COOLDOWN_MS = 30000
Service.SCHEDULE_WINDOW_HOURS = 0.75
Service.NIGHT_START_HOUR = 22
Service.NIGHT_END_HOUR = 6
Service.NIGHT_MIN_REMAINING_HOURS = 1
Service.SLEEP_WAKE_OFFSET_MINUTES = 25
Service.EAT_SLOTS = Service.EAT_SLOTS or {
    { id = "breakfast", hour = 8.0, offsetMinutes = 35 },
    { id = "lunch", hour = 13.0, offsetMinutes = 35 },
    { id = "dinner", hour = 18.5, offsetMinutes = 35 },
}
Service.DRINK_SLOTS = Service.DRINK_SLOTS or {
    { id = "morning", hour = 10.0, offsetMinutes = 50 },
    { id = "afternoon", hour = 15.0, offsetMinutes = 50 },
    { id = "evening", hour = 20.5, offsetMinutes = 50 },
}

function Service.CurrentTime(value)
    return tonumber(value) or (Core and Core.Now and Core.Now() or 0)
end

function Service.GetWorldAgeHours()
    local gameTime = type(getGameTime) == "function" and getGameTime() or nil
    if gameTime and gameTime.getWorldAgeHours then
        return tonumber(gameTime:getWorldAgeHours()) or 0
    end
    return 0
end

function Service.ScheduleState(record)
    local runtime = record.runtime or {}
    record.runtime = runtime
    runtime.roamAmbientSchedule = runtime.roamAmbientSchedule or {}
    return runtime.roamAmbientSchedule
end

function Service.IsRoamOrder(record)
    local order = record and record.orderSpec or nil
    local kind = tostring(order and order.kind or "")
    local mode = tostring(order and order.roamMode or "area")
    if kind == tostring(Const.ORDER_CAMP or "camp")
        and order and order.ambientVisit == true
        and PNC.AmbientVisitService
        and PNC.AmbientVisitService.IsActive
        and PNC.AmbientVisitService.IsActive(record)
    then
        return true
    end
    return kind == tostring(Const.ORDER_ROAM or "roam") and mode == "area"
end

function Service.IsUnowned(record)
    -- A temporary ambient visit is explicitly authorized by the server
    -- lease. It may belong to an AI faction, so the normal player-ownership
    -- test is intentionally not used for this narrow presentation path.
    if PNC.AmbientVisitService
        and PNC.AmbientVisitService.IsActive
        and PNC.AmbientVisitService.IsActive(record)
    then
        return true
    end
    if not record or record.recruited == true
        or record.ownerUsername ~= nil or record.ownerOnlineID ~= nil
        or record.colonyOwned == true
    then
        return false
    end
    if ActorControl and ActorControl.IsPuppetOwned
        and ActorControl.IsPuppetOwned(record)
    then
        return false
    end
    local verifier = PNC.Identity and PNC.Identity.Verifier or nil
    if verifier and verifier.IsCompanion
        and verifier.IsCompanion(record) == true
    then
        return false
    end
    if verifier and verifier.IsColonyOwnedNPC then
        local ok, owned = pcall(verifier.IsColonyOwnedNPC, record)
        if ok and owned == true then return false end
    end
    return true
end

function Service.HasActivePath(record)
    local runtime = record and record.runtime or nil
    local pathing = runtime and runtime.pathing or nil
    local navigation = runtime and runtime.localNavigation or nil
    if pathing and (
        pathing.traversalAction ~= nil
            or pathing.vanillaFenceAction ~= nil
            or pathing.blockedStepToX ~= nil
            or pathing.phase == "requested"
            or pathing.phase == "active"
            or pathing.phase == "blocked"
    ) then
        return true
    end
    return navigation and (
        navigation.nativeActive == true
            or navigation.nativeTraversalState ~= nil
    ) or false
end

function Service.LiveEligible(record, zombie, ignorePath)
    local runtime = record and record.runtime or nil
    local health = record and record.health or nil
    local now = Service.CurrentTime()
    if Core and Core.IsAuthority and not Core.IsAuthority() then return false end
    if not record or not zombie or record.alive == false
        or record.presenceState ~= (Const.PRESENCE_LIVE or "live")
        or not Service.IsRoamOrder(record) or not Service.IsUnowned(record)
    then
        return false
    end
    if health and health.state == "incapacitated" then return false end
    if runtime and (
        runtime.target ~= nil or runtime.combatTarget ~= nil
            or runtime.attackAction ~= nil or runtime.facilityActivity ~= nil
            or runtime.workOrderId ~= nil or runtime.taskLeaseId ~= nil
            or runtime.medicalCare ~= nil or runtime.treatment ~= nil
            or now < (tonumber(runtime.inCombatUntil) or 0)
            or now < (tonumber(health and health.recentDamageUntil) or 0)
    ) then
        return false
    end
    if not ignorePath and (Service.HasActivePath(record)
        or runtime and runtime.followState
            and runtime.followState.ownerMoving == true)
    then
        return false
    end
    return true
end

function Service.CanAttempt(record, zombie, roaming, at)
    local runtime = record and record.runtime or nil
    at = Service.CurrentTime(at)
    if not Service.LiveEligible(record, zombie) or not roaming
        or roaming.phase ~= "idle"
    then
        return false
    end
    if at < (tonumber(roaming.idleSince) or at) + Service.MIN_IDLE_MS then
        return false
    end
    if at < (tonumber(Service.NextAttemptAt[tostring(record.id)]) or 0)
        or at < (tonumber(roaming.ambientCooldownUntil) or 0)
    then
        return false
    end
    return runtime and runtime.animationScene == nil
end

function Service.IsEligible(record, zombie, roaming, at)
    return Service.CanAttempt(record, zombie, roaming, at)
end

return Service
