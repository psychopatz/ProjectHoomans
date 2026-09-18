-- Temporary Puppet Opera ownership for resumable NPC behavior.
--
-- Puppet Opera may suspend any ordinary Hoomans behavior and presentation
-- lease. Combat, vehicles, traversal, grounded recovery, and foreign owners
-- remain safety boundaries. The durable order and provider runtime are kept in
-- place so the normal owner can resume after this lease is released.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}
PNC.PuppetOpera.Override = PNC.PuppetOpera.Override or {}

local Override = PNC.PuppetOpera.Override
local Core = PNC.Core
local Scenes = PNC.AnimationScenes
local MoveIntent = PNC.BehaviorMoveIntent
local PathService = PNC.PathService
local Common = PNC.BehaviorCommon
local Scheduler = PNC.Scheduler
local ThreatGuard = PNC.BehaviorThreatGuard
local ActorControl = PNC.ActorControl
    or require "PNC/Core/ActorControl/PNC_ActorControl"

local OVERRIDE_KEY = "puppetOperaOverride"
local OWNER_HEARTBEAT_MS = 10000
local OWNER_RESERVATION_TTL_MS = 30000

local UNSAFE_ACTION_STATES = {
    attack = true,
    ["attack-network"] = true,
    lunge = true,
    lungenetwork = true,
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

local PASSIVE_OWNER_KINDS = {
    camp = true,
    colony_home = true,
    guard = true,
    patrol = true,
    roam = true,
}

local function nowValue()
    return Core and Core.Now and Core.Now() or 0
end

local function runtimeOf(record)
    if not record then return nil end
    record.runtime = record.runtime or {}
    return record.runtime
end

local function addReservationID(ids, value)
    local id = tostring(value or "")
    if id ~= "" then ids[id] = true end
end

local function collectReservationIDs(record)
    local runtime = record and record.runtime or nil
    local ids = {}
    local state
    local taskLeaseIDs = {}
    local leaseService
    local lease
    local index
    if not runtime then return ids end

    -- These are the live reservation fields used by facility, camp, sleep,
    -- and ambient providers. The set makes the camp/activity/task aliases
    -- idempotent when they point at the same reservation.
    addReservationID(ids, runtime.reservationId)
    for _, key in ipairs({
        "facilityActivity", "roamAmbient", "roamingSeat",
        "medicalCare", "treatment",
    }) do
        state = runtime[key]
        if type(state) == "table" then
            addReservationID(ids, state.reservationId)
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
            if lease then addReservationID(ids, lease.reservationId) end
        end
    end
    return ids
end

local function markTaskLeaseResumed(record, at)
    local service = PNC.TaskLeaseService
    local internal = PNC.Tasking and PNC.Tasking.Internal or nil
    local lease
    if not record or not service or type(service.ForNPC) ~= "function"
        or not internal or type(internal.MarkPuppetOperaResumed) ~= "function"
    then
        return
    end
    lease = service.ForNPC(record.id)
    if lease then internal.MarkPuppetOperaResumed(lease, at) end
end

local function hasValue(value)
    return value ~= nil
        and (type(value) ~= "string" or value ~= "")
end

local function actionStateOf(body)
    if PNC.LiveBodyControl
        and PNC.LiveBodyControl.GetActionStateName
    then
        return string.lower(tostring(
            PNC.LiveBodyControl.GetActionStateName(body) or ""
        ))
    end
    if body and body.getActionStateName then
        return string.lower(tostring(body:getActionStateName() or ""))
    end
    return ""
end

local function contextOf(record)
    local internal = ThreatGuard and ThreatGuard.Internal or nil
    local runtime = record and record.runtime or nil
    local context
    if internal and internal.ResolveContext then
        context = internal.ResolveContext(record)
        if context then return context end
    end
    local kind = tostring(record and record.orderSpec
        and record.orderSpec.kind or "")
    if PASSIVE_OWNER_KINDS[kind] then
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
    if runtime and hasValue(runtime.taskLeaseId) then
        return {
            source = "task",
            ownerKind = "task",
            token = runtime.taskLeaseId,
        }
    end
    if runtime and hasValue(runtime.orderLeaseId) then
        return {
            source = "order",
            ownerKind = "order",
            token = runtime.orderLeaseId,
        }
    end
    if runtime and hasValue(runtime.facilityActivity) then
        return {
            source = "facility",
            ownerKind = "facility",
            token = runtime.facilityActivity.taskLeaseId,
        }
    end
    if runtime and hasValue(runtime.workOrderId) then
        return {
            source = "work",
            ownerKind = "work",
            token = runtime.workOrderId,
        }
    end
    if runtime and hasValue(runtime.medicalCare) then
        return {
            source = "medical",
            ownerKind = "medical",
            token = runtime.medicalCare.leaseId,
        }
    end
    if runtime and hasValue(runtime.treatment) then
        return {
            source = "treatment",
            ownerKind = "treatment",
            token = runtime.treatment.leaseId,
        }
    end
    if runtime and hasValue(runtime.roamAmbient) then
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

local function pathIsActive(runtime)
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

local function hasCombat(runtime, record, body)
    if runtime and (
        runtime.target ~= nil
            or runtime.combatTarget ~= nil
            or runtime.attackAction ~= nil
            or nowValue() < (tonumber(runtime.inCombatUntil) or 0)
    ) then
        return true
    end
    if PNC.LiveBodyControl
        and PNC.LiveBodyControl.IsPresentationCombatActive
        and PNC.LiveBodyControl.IsPresentationCombatActive(record, nowValue())
    then
        return true
    end
    if body and body.getTarget and body:getTarget() ~= nil then
        return true
    end
    return false
end

function Override.IsOwned(record, sessionID)
    local value = record and record.runtime
        and record.runtime[OVERRIDE_KEY] or nil
    return value ~= nil
        and tostring(value.sessionId or "") == tostring(sessionID or "")
end

function Override.GetState(record)
    return record and record.runtime
        and record.runtime[OVERRIDE_KEY] or nil
end

function Override.GetReadiness(record, body, options)
    options = type(options) == "table" and options or {}
    local runtime = runtimeOf(record)
    local current = runtime and runtime[OVERRIDE_KEY] or nil
    local lease = runtime and runtime.puppetOperaLease or nil
    local actionState
    local context
    local ownerKind
    local suspendable
    local modData
    if not record then return false, "npc_record_missing" end
    if not body then return false, "npc_body_unavailable" end
    if record.alive == false or body.isDead and body:isDead() then
        return false, "npc_dead"
    end
    if body.getVehicle and body:getVehicle() then
        return false, "npc_in_vehicle"
    end
    if body.isSeatedInVehicle and body:isSeatedInVehicle() then
        return false, "npc_seated"
    end
    if current and tostring(current.sessionId or "")
        ~= tostring(options.sessionId or "")
    then
        return false, "npc_owned_by_other_puppet_override"
    end
    if lease and tostring(lease.sessionId or "")
        ~= tostring(options.sessionId or "")
    then
        return false, "npc_owned_by_other_puppet_session"
    end
    if hasCombat(runtime, record, body) then
        return false, "npc_in_combat"
    end
    actionState = actionStateOf(body)
    modData = body.getModData and body:getModData() or nil
    if actionState == "bumped" then
        if not modData
            or modData.PNC_BumpActionLease ~= true
            or modData.PNC_BumpNonCombat ~= true
        then
            return false, "npc_action_state_busy"
        end
    end
    if UNSAFE_ACTION_STATES[actionState] == true then
        return false, "npc_action_state_busy"
    end
    if PathService and PathService.IsTraversalActive
        and PathService.IsTraversalActive(record, body)
    then
        return false, "npc_traversal_active"
    end
    if PNC.Compatibility and PNC.Compatibility.ActorOwnership
        and PNC.Compatibility.ActorOwnership.IsForeignOwned
        and PNC.Compatibility.ActorOwnership.IsForeignOwned(body)
    then
        return false, "npc_owned_by_foreign_mod"
    end

    context = contextOf(record)
    ownerKind = context and tostring(context.ownerKind or "") or "idle"
    -- All non-combat Hoomans behavior is resumable at this boundary. Do not
    -- reject a moving, working, talking, or tasking NPC merely because
    -- its provider currently owns a runtime field; the control lease below
    -- prevents those providers from writing over the scene and the original
    -- runtime remains available for restoration.
    suspendable = context ~= nil
        or pathIsActive(runtime)
        or runtime and runtime.animationScene ~= nil
        or record.activeJob ~= nil
        or false
    return true, {
        ownerKind = ownerKind,
        ownerToken = context and context.token or nil,
        context = context,
        suspendable = suspendable,
        reason = suspendable and "suspendable" or "ready",
        actionState = actionState,
    }
end

function Override.CanAcquire(record, body, options)
    return Override.GetReadiness(record, body, options)
end

-- Provider behavior is intentionally paused while a Puppet Opera session owns
-- the actor. Its facility/seat/task reservations still need a small
-- owner-scoped heartbeat, otherwise the normal provider tick that renews them
-- would expire while it is correctly being suppressed.
function Override.Maintain(session, actor, at)
    local record = actor and actor.record or nil
    local runtime = record and record.runtime or nil
    local state = runtime and runtime[OVERRIDE_KEY] or nil
    local timestamp = tonumber(at) or nowValue()
    local reservations
    local ids
    local id
    local renewed
    local details
    if type(session) ~= "table" or type(actor) ~= "table" then
        return false, "npc_override_arguments_invalid"
    end
    if not state
        or tostring(state.sessionId or "")
            ~= tostring(session.sessionId or "")
    then
        return false, "npc_override_not_owned"
    end
    if timestamp < (tonumber(state.nextReservationRenewAt) or 0) then
        return true
    end

    state.lastHeartbeatAt = timestamp
    state.nextReservationRenewAt = timestamp + OWNER_HEARTBEAT_MS
    reservations = PNC.FacilityReservations
    if not reservations or not reservations.Start then return true end
    ids = collectReservationIDs(record)
    for id in pairs(ids) do
        renewed, details = reservations.Start(id, OWNER_RESERVATION_TTL_MS)
        if renewed ~= true then
            state.reservationLost = true
            state.reservationLostID = id
            state.reservationLostReason = tostring(details or "renew_failed")
            return false, "puppet_opera_reservation_lost:" .. id
        end
    end
    state.lastReservationRenewAt = timestamp
    state.reservationLost = nil
    state.reservationLostID = nil
    state.reservationLostReason = nil
    return true
end

local function continuationOf(record, context)
    local runtime = record and record.runtime or {}
    local scene = runtime.animationScene
    return {
        ownerKind = context and context.ownerKind or "idle",
        ownerToken = context and context.token or nil,
        orderKind = record and record.orderSpec
            and record.orderSpec.kind or nil,
        activeJob = record and record.activeJob or nil,
        activeBehavior = record and record.activeBehavior or nil,
        sceneID = scene and scene.id or nil,
        sceneRevision = scene and scene.revision or nil,
    }
end

function Override.Acquire(session, actor)
    if type(session) ~= "table" or type(actor) ~= "table" then
        return false, "npc_override_arguments_invalid"
    end
    local record = actor.record
    local body = actor.body
    local runtime = runtimeOf(record)
    local accepted
    local info
    local currentScene
    local continuation
    local modData
    local halted
    local haltReason
    local acquiredAt
    if not runtime or not body then
        return false, "npc_override_actor_unavailable"
    end
    accepted, info = Override.CanAcquire(record, body, {
        sessionId = session.sessionId,
    })
    if accepted ~= true then return false, info end
    continuation = continuationOf(record, info.context)
    currentScene = runtime.animationScene
    if currentScene then
        if not Scenes or not Scenes.Suspend then
            return false, "npc_scene_suspend_unavailable"
        end
        local suspended, suspendReason = Scenes.Suspend(
            record,
            body,
            "puppet_opera_override"
        )
        if suspended ~= true or runtime.animationScene then
            return false, suspendReason or "npc_scene_would_not_release"
        end
    end
    modData = body.getModData and body:getModData() or nil
    if modData
        and modData.PNC_BumpActionLease == true
        and modData.PNC_BumpNonCombat == true
        and PNC.Animation
        and PNC.Animation.FinishBump
    then
        PNC.Animation.FinishBump(body, true)
    end
    if pathIsActive(runtime) then
        if Common and Common.HaltMovement then
            halted, haltReason = Common.HaltMovement(
                record,
                body,
                "puppet_opera_override"
            )
            if halted == false then
                return false, haltReason or "npc_movement_pause_rejected"
            end
        elseif PathService and PathService.Commands
            and PathService.Commands.Reset
        then
            halted, haltReason = PathService.Commands.Reset(
                record,
                body,
                "puppet_opera_override"
            )
            if halted == false then
                return false, haltReason or "npc_movement_pause_rejected"
            end
        else
            return false, "npc_movement_pause_unavailable"
        end
    end
    acquiredAt = nowValue()
    runtime[OVERRIDE_KEY] = {
        sessionId = tostring(session.sessionId),
        ownerId = tostring(session.ownerId or ""),
        ownerKind = tostring(info.ownerKind or "idle"),
        ownerToken = info.ownerToken,
        acquiredAt = acquiredAt,
        nextReservationRenewAt = acquiredAt,
        continuation = continuation,
    }
    record.activeJob = "PuppetOpera"
    record.activeBehavior = "PuppetOpera:" .. tostring(session.sessionId)
    actor.overrideOwned = true
    actor.overrideOwnerKind = info.ownerKind
    actor.lastReason = info.suspendable
        and "npc_owner_suspended" or "npc_owner_claimed"
    return true, actor.lastReason
end

function Override.Release(session, actor)
    if type(session) ~= "table" or type(actor) ~= "table" then
        return false, "npc_override_arguments_invalid"
    end
    local record = actor.record
    local runtime = record and record.runtime or nil
    local state = runtime and runtime[OVERRIDE_KEY] or nil
    local continuation = state and state.continuation or nil
    if not state
        or tostring(state.sessionId or "")
            ~= tostring(session.sessionId or "")
    then
        return false, "npc_override_not_owned"
    end
    local intent = runtime.moveIntent
    if intent
        and tostring(intent.puppetOperaSessionId or "")
            == tostring(session.sessionId or "")
        and MoveIntent and MoveIntent.Hold
    then
        MoveIntent.Hold(
            record,
            "puppet_opera_restore",
            ActorControl.MakeOwner(session.sessionId)
        )
    end
    runtime[OVERRIDE_KEY] = nil
    markTaskLeaseResumed(record, nowValue())
    if record.activeJob == "PuppetOpera"
        and continuation
        and tostring(record.orderSpec and record.orderSpec.kind or "")
            == tostring(continuation.orderKind or "")
    then
        record.activeJob = continuation.activeJob
        record.activeBehavior = continuation.activeBehavior
    elseif record.activeJob == "PuppetOpera" then
        record.activeJob = nil
        record.activeBehavior = nil
    end
    if Scheduler and Scheduler.Schedule and record.id then
        Scheduler.Schedule(record, nowValue() + 50)
    end
    actor.overrideOwned = false
    actor.lastReason = "npc_owner_restored"
    return true, "npc_owner_restored"
end

return Override
