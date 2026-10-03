-- Puppet Opera NPC ownership acquire and release lifecycle.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}
PNC.PuppetOpera.Override = PNC.PuppetOpera.Override or {}

local Override = PNC.PuppetOpera.Override
local Internal = Override.Internal or {}
local OVERRIDE_KEY = Internal.OverrideKey

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
    local runtime = Internal.RuntimeOf(record)
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
        local scenes = Internal.Scenes
        if not scenes or not scenes.Suspend then
            return false, "npc_scene_suspend_unavailable"
        end
        local suspended, suspendReason = scenes.Suspend(
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
        and Internal.ReplaceableBump(body)
        and PNC.Animation
        and PNC.Animation.FinishBump
    then
        PNC.Animation.FinishBump(body, true)
    end
    if Internal.PathIsActive(runtime) then
        local common = Internal.Common
        local pathService = Internal.PathService
        if common and common.HaltMovement then
            halted, haltReason = common.HaltMovement(
                record,
                body,
                "puppet_opera_override"
            )
            if halted == false then
                return false, haltReason or "npc_movement_pause_rejected"
            end
        elseif pathService and pathService.Commands
            and pathService.Commands.Reset
        then
            halted, haltReason = pathService.Commands.Reset(
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
    acquiredAt = Internal.Now()
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
    local moveIntent = Internal.MoveIntent
    if intent
        and tostring(intent.puppetOperaSessionId or "")
            == tostring(session.sessionId or "")
        and moveIntent and moveIntent.Hold
    then
        moveIntent.Hold(
            record,
            "puppet_opera_restore",
            Internal.ActorControl.MakeOwner(session.sessionId)
        )
    end
    runtime[OVERRIDE_KEY] = nil
    Internal.MarkTaskLeaseResumed(record, Internal.Now())
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
    local scheduler = Internal.Scheduler
    if scheduler and scheduler.Schedule and record.id then
        scheduler.Schedule(record, Internal.Now() + 50)
    end
    actor.overrideOwned = false
    actor.lastReason = "npc_owner_restored"
    return true, "npc_owner_restored"
end

return Override
