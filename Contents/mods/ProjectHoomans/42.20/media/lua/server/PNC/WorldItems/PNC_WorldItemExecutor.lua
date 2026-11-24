-- Tasking execution coordinator and provider registration for world-item actions.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

require "PNC/WorldItems/PNC_WorldItemExecutor_Actions"
require "PNC/WorldItems/PNC_WorldItemExecutor_Commit"
require "PNC/WorldItems/PNC_WorldItemExecutor_Lifecycle"

PNC = PNC or {}
PNC.WorldItemExecutor = PNC.WorldItemExecutor or {}

local Executor = PNC.WorldItemExecutor
local Internal = Executor.Internal
local Service = PNC.WorldItemService
local Common = PNC.BehaviorCommon

local function nowMs()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

local function clearRuntime(record, body, reason, intent)
    if intent and Internal and Internal.RestoreRipHandProp then
        Internal.RestoreRipHandProp(intent, record, body)
    end
    if Common and Common.HaltMovement then
        Common.HaltMovement(record, body, reason or "world_item_end")
    end
    if PNC.AnimationScenes and PNC.AnimationScenes.Interrupt and record and body then
        PNC.AnimationScenes.Interrupt(record, body, reason or "world_item_end")
    end
    if record then
        if record.runtime then record.runtime.worldItem = nil end
        if record.activeBehavior == "RipClothing" or record.activeBehavior == "ScavengeItem" then
            record.activeBehavior = nil
        end
    end
end

local function finishLease(lease, intent, record, body, reason)
    clearRuntime(record, body, reason, intent)
    Service.ClearIntent(intent.npcId, nil)
    if lease and PNC.Tasking and PNC.Tasking.Commands and PNC.Tasking.Commands.Complete then
        PNC.Tasking.Commands.Complete(lease.leaseId, reason or "WORLD_ITEM_DONE")
    end
    return true
end

local function abortLease(lease, intent, record, body, reason)
    clearRuntime(record, body, reason, intent)
    Service.ClearIntent(intent.npcId, nil)
    if PNC.Tasking and PNC.Tasking.Commands and PNC.Tasking.Commands.CancelForNPC then
        PNC.Tasking.Commands.CancelForNPC(lease.npcId, reason or "WORLD_ITEM_FAILED")
    end
    return false, reason
end

function Executor.Tick(lease)
    local npcId = lease and lease.npcId
    local intent = Service.GetActiveIntent(npcId)
    local record = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(npcId) or nil
    local body = record and PNC.Registry.GetLiveZombie and PNC.Registry.GetLiveZombie(record.id) or nil
    local now = nowMs()
    if not intent or not record or record.alive == false or not body then
        if intent then Service.ClearIntent(npcId, nil) end
        if PNC.Tasking and PNC.Tasking.Commands and PNC.Tasking.Commands.CancelForNPC then
            PNC.Tasking.Commands.CancelForNPC(npcId, "WORLD_ITEM_ACTOR_UNAVAILABLE")
        end
        return false, "actor_unavailable"
    end

    if intent.phase == "INTERACTING" then
        if now < (tonumber(intent.actionUntil) or 0) then
            record.activeBehavior = intent.action == "rip_bandage" and "RipClothing" or "ScavengeItem"
            return true
        end
        if PNC.Tasking and PNC.Tasking.Commands and PNC.Tasking.Commands.SetPhase then
            PNC.Tasking.Commands.SetPhase(npcId, "ATOMIC_COMMIT")
        end
        local ok, commitReason = Internal.CommitAction(intent, record, body)
        if not ok then return abortLease(lease, intent, record, body, commitReason) end
        return finishLease(lease, intent, record, body, "WORLD_ITEM_COMPLETED")
    end

    local valid, validReason = Internal.IsCandidateStillValid(intent)
    if not valid then return abortLease(lease, intent, record, body, validReason) end

    if Internal.WithinInteractionRadius(record, body, intent.candidate) then
        Internal.BeginInteract(intent, record, body, now)
        return true
    end

    local approach, appReason = Internal.ApproachLocation(intent, record)
    if not approach then return abortLease(lease, intent, record, body, appReason) end

    local lane = record.runtime and record.runtime.pathing or nil
    if lane and lane.phase == "blocked" then
        intent.failedApproaches = intent.failedApproaches or {}
        intent.failedApproaches[approach.key] = true
        intent.approachTarget = nil
        intent.approachFailures = (tonumber(intent.approachFailures) or 0) + 1
        if intent.approachFailures >= 3 then
            return abortLease(lease, intent, record, body, lane.blockReason or "path_blocked")
        end
        return true
    end

    local stopDist = intent.candidate.sourceType == "container" and 0.8 or 0.65
    local ok, movement = Common.MoveRecord(
        record, body, approach.x, approach.y, approach.z,
        "walk", stopDist, "world_item_" .. intent.action)
    if not ok then
        intent.failedApproaches = intent.failedApproaches or {}
        intent.failedApproaches[approach.key] = true
        intent.approachTarget = nil
        intent.approachFailures = (tonumber(intent.approachFailures) or 0) + 1
        if intent.approachFailures >= 3 then
            return abortLease(lease, intent, record, body, tostring(movement or "move_failed"))
        end
        return true
    end
    intent.updatedAt = now
    if movement == "arrived" then Internal.BeginInteract(intent, record, body, now) end
    return true
end

function Executor.Cancel(lease, reason)
    local npcId = lease and lease.npcId
    local record = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(npcId) or nil
    local body = record and PNC.Registry.GetLiveZombie and PNC.Registry.GetLiveZombie(record.id) or nil
    clearRuntime(record, body, reason or "world_item_cancelled")
    Service.ClearIntent(npcId, nil)
    return true
end

function Executor.Complete(lease, reason)
    local npcId = lease and lease.npcId
    local record = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(npcId) or nil
    local body = record and PNC.Registry.GetLiveZombie and PNC.Registry.GetLiveZombie(record.id) or nil
    clearRuntime(record, body, reason or "world_item_complete")
    Service.ClearIntent(npcId, nil)
    return true
end

if PNC.Tasking and PNC.Tasking.Commands and PNC.Tasking.Commands.RegisterProvider then
    PNC.Tasking.Commands.RegisterProvider("world_item", Executor)
end

return Executor
