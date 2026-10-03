-- Shared Puppet Opera ownership facts and continuation helpers.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}
PNC.PuppetOpera.Override = PNC.PuppetOpera.Override or {}

local Internal = PNC.PuppetOpera.Override.Internal or {}
PNC.PuppetOpera.Override.Internal = Internal

Internal.OverrideKey = "puppetOperaOverride"
Internal.OwnerHeartbeatMS = 10000
Internal.OwnerReservationTTLMS = 30000

Internal.UnsafeActionStates = {
    climbfence = true,
    climbwindow = true,
    climbwall = true,
    falldown = true,
    getup = true,
    ["getup-fromonback"] = true,
    ["getup-fromonfront"] = true,
    ["getup-fromsitting"] = true,
    onground = true,
    ["onground-ragdoll"] = true,
    staggerback = true,
    ["staggerback-knockeddown"] = true,
    thump = true,
}

Internal.PassiveOwnerKinds = {
    camp = true,
    colony_home = true,
    guard = true,
    patrol = true,
    roam = true,
}

function Internal.Now()
    local core = Internal.Core
    return core and core.Now and core.Now() or 0
end

function Internal.RuntimeOf(record)
    if not record then return nil end
    record.runtime = record.runtime or {}
    return record.runtime
end

function Internal.HasValue(value)
    return value ~= nil
        and (type(value) ~= "string" or value ~= "")
end

function Internal.ActionStateOf(body)
    if PNC.LiveBodyControl
        and PNC.LiveBodyControl.GetActionStateName
    then
        return string.lower(tostring(
            PNC.LiveBodyControl.GetActionStateName(body) or ""))
    end
    if body and body.getActionStateName then
        return string.lower(tostring(body:getActionStateName() or ""))
    end
    return ""
end

-- A PNC-owned bump may be replaced even though the engine reports it as the
-- same generic `bumped` action state as an unrelated animation.
function Internal.ReplaceableBump(body)
    local modData = body and body.getModData and body:getModData() or nil
    return modData ~= nil
        and modData.PNC_BumpActionLease == true
end

function Internal.ContextOf(record)
    local threatInternal = Internal.ThreatGuard
        and Internal.ThreatGuard.Internal or nil
    local runtime = record and record.runtime or nil
    local context
    if threatInternal and threatInternal.ResolveContext then
        context = threatInternal.ResolveContext(record)
        if context then return context end
    end
    local kind = tostring(record and record.orderSpec
        and record.orderSpec.kind or "")
    if Internal.PassiveOwnerKinds[kind] then
        return {
            source = kind,
            ownerKind = kind,
            token = kind,
        }
    end
    if runtime and runtime.conversationLease then
        return {
            source = "conversation",
            ownerKind = "conversation",
            token = runtime.conversationLease.token,
        }
    end
    if runtime and Internal.HasValue(runtime.taskLeaseId) then
        return {
            source = "task",
            ownerKind = "task",
            token = runtime.taskLeaseId,
        }
    end
    if runtime and Internal.HasValue(runtime.orderLeaseId) then
        return {
            source = "order",
            ownerKind = "order",
            token = runtime.orderLeaseId,
        }
    end
    if runtime and Internal.HasValue(runtime.facilityActivity) then
        return {
            source = "facility",
            ownerKind = "facility",
            token = runtime.facilityActivity.taskLeaseId,
        }
    end
    if runtime and Internal.HasValue(runtime.workOrderId) then
        return {
            source = "work",
            ownerKind = "work",
            token = runtime.workOrderId,
        }
    end
    if runtime and Internal.HasValue(runtime.medicalCare) then
        return {
            source = "medical",
            ownerKind = "medical",
            token = runtime.medicalCare.leaseId,
        }
    end
    if runtime and Internal.HasValue(runtime.treatment) then
        return {
            source = "treatment",
            ownerKind = "treatment",
            token = runtime.treatment.leaseId,
        }
    end
    if runtime and Internal.HasValue(runtime.roamAmbient) then
        return {
            source = "roam_ambient",
            ownerKind = "roam_ambient",
            token = runtime.roamAmbient.startedAt,
        }
    end
    if runtime and runtime.roamingSeat then
        return {
            source = "roaming_seat",
            ownerKind = "roaming_seat",
            token = runtime.roamingSeat.startedAt,
        }
    end
    return nil
end

function Internal.PathIsActive(runtime)
    local intent = runtime and runtime.moveIntent or nil
    local path = runtime and runtime.pathing or nil
    local navigation = runtime and runtime.localNavigation or nil
    return intent and intent.kind == "move"
        or path and (
            path.phase == "requested"
                or path.phase == "active"
                or path.traversalAction ~= nil
        )
        or navigation and (
            navigation.nativeActive == true
                or navigation.nativeTraversalState ~= nil
        )
        or false
end

function Internal.CollectReservationIDs(record)
    local runtime = record and record.runtime or nil
    local ids = {}
    local state
    local taskLeaseIDs = {}
    local leaseService
    local lease
    local index
    if not runtime then return ids end

    -- These are the live reservation fields used by facility, camp, sleep,
    -- and ambient providers. The set makes aliases idempotent when they
    -- point at the same reservation.
    local function addReservationID(value)
        local id = tostring(value or "")
        if id ~= "" then ids[id] = true end
    end
    addReservationID(runtime.reservationId)
    for _, key in ipairs({
        "facilityActivity", "roamAmbient", "roamingSeat",
        "medicalCare", "treatment",
    }) do
        state = runtime[key]
        if type(state) == "table" then
            addReservationID(state.reservationId)
            if key == "facilityActivity" then
                taskLeaseIDs[#taskLeaseIDs + 1] = state.taskLeaseId
            end
        end
    end

    taskLeaseIDs[#taskLeaseIDs + 1] = runtime.taskLeaseId
    leaseService = PNC.TaskLeaseService
    if leaseService and leaseService.Get then
        for index = 1, #taskLeaseIDs do
            lease = leaseService.Get(taskLeaseIDs[index])
            if lease then addReservationID(lease.reservationId) end
        end
    end
    return ids
end

function Internal.MarkTaskLeaseResumed(record, at)
    local service = PNC.TaskLeaseService
    local taskInternal = PNC.Tasking and PNC.Tasking.Internal or nil
    local lease
    if not record or not service or type(service.ForNPC) ~= "function"
        or not taskInternal
        or type(taskInternal.MarkPuppetOperaResumed) ~= "function"
    then
        return
    end
    lease = service.ForNPC(record.id)
    if lease then taskInternal.MarkPuppetOperaResumed(lease, at) end
end

return PNC.PuppetOpera.Override
