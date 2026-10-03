-- Corpse haul transfer, completion, and deferred world effects.
--
-- This provider owns the durable world handoff and completion lifecycle.
-- Live cleanup remains delegated through the cleanup boundary.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.CorpseHaulService
local Internal = Service.Internal
local Core = PNC.Core
local Registry = PNC.Registry
local Lifecycle = PNC.BodyLifecycle
local Work = PNC.WorkService
local WorkRepository = PNC.WorkRepository
local Status = PNC.WorkDefinitions and PNC.WorkDefinitions.STATUS or {}
local WorldEffects = PNC.WorldEffectService
local Definitions = PNC.WorkDefinitions

local operationDiagnostic = Internal.operationDiagnostic
local operationFailure = Internal.operationFailure
local assignmentForWorkOrder = Internal.assignmentForWorkOrder
local waitForWorld = Internal.waitForWorld
local isDropPointAllowed = Internal.isDropPointAllowed
local actionStatus = Internal.actionStatus
local clearWorkRuntime = Internal.clearWorkRuntime

local function transferCorpse(order, assignment, task)
    local destinationSquare = Internal.squareAt(assignment.dropX,
        assignment.dropY, assignment.dropZ)
    local corpse = task and task.corpse or nil
    local ok
    local reason

    if not destinationSquare then
        return waitForWorld(order, task, "DESTINATION_CHUNK_LOADING")
    end
    if not corpse then
        corpse = Service.GetCorpseAt(assignment.sourceX,
            assignment.sourceY, assignment.sourceZ, assignment.haulToken,
            assignment.deathMarkerId)
    end
    if not corpse then
        corpse = Service.GetCorpseAt(assignment.dropX, assignment.dropY,
            assignment.dropZ, assignment.haulToken,
            assignment.deathMarkerId)
        if corpse then
            local progressed, progressReason = Work.Commands.AddProgress(
                order.id, order.workerId, order.requiredWork)
            if progressed ~= true then
                return operationFailure(order, task, nil, "TRANSFER",
                    progressReason or "PROGRESS_REJECTED")
            end
            return true
        end
        return operationFailure(order, task, nil, "TRANSFER",
            "CORPSE_NOT_FOUND")
    end
    if not Lifecycle or not Lifecycle.Internal
        or (task and task.carrying and not Lifecycle.Internal.followCorpse)
        or (not task or (not task.carrying
            and not Lifecycle.Internal.moveCorpse))
    then
        return operationFailure(order, task, nil, "TRANSFER",
            "CORPSE_TRANSFER_UNAVAILABLE")
    end
    if task and task.carrying and Lifecycle.Internal.followCorpse then
        ok, reason = Lifecycle.Internal.followCorpse(corpse,
            assignment.dropX + 0.5, assignment.dropY + 0.5,
            assignment.dropZ)
    else
        ok, reason = Lifecycle.Internal.moveCorpse(corpse, destinationSquare,
            assignment.dropX, assignment.dropY, assignment.dropZ)
    end
    if not ok then
        return operationFailure(order, task, nil, "TRANSFER",
            reason or "CORPSE_TRANSFER_FAILED")
    end
    local data = corpse.getModData and corpse:getModData() or nil
    if data and Service.EnsureCorpseHaulMarker then
        data = Service.EnsureCorpseHaulMarker(corpse, true) or data
    end
    if data then
        data.PNC_CorpseHaulTaskId = order.id
        Internal.transmit(corpse)
    end
    local progressed, progressReason = Work.Commands.AddProgress(
        order.id, order.workerId, order.requiredWork)
    if progressed ~= true then
        return operationFailure(order, task, nil, "TRANSFER",
            progressReason or "PROGRESS_REJECTED")
    end
    return true
end

local function completeWorkOrder(order)
    local assignment = assignmentForWorkOrder(order)
    local task = Service.Runtime.byTask[tostring(order and order.id or "")]
    local record = order and Registry and Registry.Get
        and Registry.Get(order.workerId) or nil
    local corpse = assignment and Service.GetCorpseAt(assignment.dropX,
        assignment.dropY, assignment.dropZ, assignment.haulToken,
        assignment.deathMarkerId) or nil
    local data = corpse and corpse.getModData and corpse:getModData() or nil
    if not corpse or not data then
        return operationFailure(order, task, record, "COMPLETION",
            "CORPSE_NOT_AT_DESTINATION")
    end
    data.PNC_CorpseHaulTaskId = nil
    Internal.transmit(corpse)
    local marker = data.PNC_DeathMarkerID
        and Registry.GetDeathMarker and Registry.GetDeathMarker(
            data.PNC_DeathMarkerID) or nil
    if marker and marker.alive == false and PNC.BodyLifecycle
        and PNC.BodyLifecycle.Internal
        and PNC.BodyLifecycle.Internal.stampCorpse
    then
        PNC.BodyLifecycle.Internal.stampCorpse(marker, corpse,
            assignment.haulToken)
        if PNC.BodyLifecycle.Internal.transmitCorpseState then
            PNC.BodyLifecycle.Internal.transmitCorpseState(corpse)
        end
    end
    clearWorkRuntime(order, "corpse_haul_complete")
    return true
end

-- This is a migration guard for orders written by the old shared behavior.
-- Those orders could reach 100% during SOURCE_APPROACH and then become
-- BLOCKED before the corpse was touched. Release the stale assignment and let
-- reconciliation bind the source corpse again. Do not apply this blindly to a
-- drop-phase failure: a corpse may already have been physically transferred.
local function recoverCompletionFailure(order, reason)
    if tostring(order and order.operation or "") ~= "CORPSE_HAUL"
        or tostring(reason or "") ~= "CORPSE_NOT_AT_DESTINATION"
    then
        return false
    end
    local phase = tostring(order.phase or "")
    if phase ~= "SOURCE_APPROACH" and phase ~= "" then return false end
    local released
    local releaseReason
    order.completionStarted = nil
    if Work.Commands.ReleaseAssignment and order.workerId then
        released, releaseReason = Work.Commands.ReleaseAssignment(
            order.workerId, "corpse_haul_completion_retry")
    elseif Work.Commands.ReleaseWorker and order.workerId then
        released, releaseReason = Work.Commands.ReleaseWorker(order.workerId,
            "corpse_haul_completion_retry")
    elseif Work.Internal and Work.Internal.releaseClaim then
        released, releaseReason = Work.Internal.releaseClaim(order,
            "corpse_haul_completion_retry", false, true)
    end
    if released ~= true and Work.Commands.ReleaseWorker and order.workerId then
        -- A stale or partially materialized Tasking lease must not prevent the
        -- durable claim from being repaired. CanContinue will invalidate that
        -- lease on its next reconciliation pass.
        released, releaseReason = Work.Commands.ReleaseWorker(order.workerId,
            "corpse_haul_completion_retry")
    end
    if released ~= true then return false, releaseReason end
    -- clearWorkRuntime releases the old corpse reservation. Clearing the
    -- durable token too lets reconciliation score the physical source corpse
    -- by location and stamp a fresh reservation safely.
    if order.payload then order.payload.haulToken = nil end
    order.status = Status.WAITING_FOR_WORKER
    order.progress = 0
    order.blockedReason = "CORPSE_NOT_AT_DESTINATION"
    order.updatedAt = Core.Now()
    order.revision = (tonumber(order.revision) or 0) + 1
    if WorkRepository then WorkRepository.MarkDirty() end
    if Work.Internal and Work.Internal.markAssignmentDirty then
        Work.Internal.markAssignmentDirty(order,
            "CORPSE_HAUL_COMPLETION_RETRY")
    end
    return true, "CORPSE_HAUL_COMPLETION_RETRY"
end

local function cancelWorkOrder(order)
    clearWorkRuntime(
        order,
        order and order.cancellationReason or "corpse_haul_cancelled"
    )
    return true
end

local function deferredEffectFor(order, assignment)
    local payload = order and order.payload or {}
    local sourceX = tonumber(payload.carryX) or assignment.sourceX
    local sourceY = tonumber(payload.carryY) or assignment.sourceY
    local sourceZ = tonumber(payload.carryZ) or assignment.sourceZ
    return {
        kind = "CORPSE_TRANSFER", state = "PENDING",
        sourceX = sourceX, sourceY = sourceY, sourceZ = sourceZ,
        destinationX = assignment.dropX, destinationY = assignment.dropY,
        destinationZ = assignment.dropZ,
        haulToken = assignment.haulToken,
        deathMarkerId = assignment.deathMarkerId,
        createdAt = Core.Now(), updatedAt = Core.Now(),
    }
end

local function deferredWait(order, effect, reason)
    local now = Core.Now()
    local status = Status.WORLD_EFFECT_PENDING or "WORLD_EFFECT_PENDING"
    local sameState = order.status == status
        and tostring(effect.waitReason or "") == tostring(reason or "")
    effect.state = "PENDING"
    effect.waitReason = tostring(reason or "WORLD_UNAVAILABLE")
    if not sameState then effect.updatedAt = now end
    order.status = status
    order.blockedReason = effect.waitReason
    order.phase = "WORLD_EFFECT_PENDING"
    order.livePhase = nil
    if not sameState then
        order.lastProgressAt, order.updatedAt = now, now
        order.revision = (tonumber(order.revision) or 0) + 1
    end
    if WorldEffects and WorldEffects.MarkPending then
        WorldEffects.MarkPending("WORK_ORDER", order, effect,
            effect.waitReason)
    elseif Internal.indexPendingWorldEffect then
        Internal.indexPendingWorldEffect(order)
    end
    if not sameState and WorkRepository then WorkRepository.MarkDirty() end
    return true, "WORLD_EFFECT_PENDING"
end

local function anyCorpseInSquare(square)
    local found = false
    if not square or not Lifecycle or not Lifecycle.Internal
        or not Lifecycle.Internal.forEachCorpse
    then return false end
    Lifecycle.Internal.forEachCorpse(square, function()
        found = true
    end)
    return found
end

local function finishDeferredTransfer(order, effect, corpse)
    if effect.state ~= "APPLIED" then
        effect.state = "APPLIED"
        effect.appliedAt = Core.Now()
        effect.updatedAt = effect.appliedAt
        if corpse and corpse.getModData then
            local data = corpse:getModData()
            if Service.EnsureCorpseHaulMarker then
                data = Service.EnsureCorpseHaulMarker(corpse, true) or data
            end
            if data then
                data.PNC_CorpseHaulTaskId = order.id
                Internal.transmit(corpse)
            end
        end
    end
    local completed, completionResult = Work.Commands.CompleteDeferred(
        order.id, "corpse_transfer_applied")
    if completed ~= true then
        -- Keep the identity token until the durable order reaches COMPLETED;
        -- a retry can still find the already-moved corpse after a save or
        -- transient command failure.
        effect.state = "PENDING"
        effect.waitReason = "WORLD_COMPLETION_RETRY"
        effect.updatedAt = Core.Now()
        if Internal.indexPendingWorldEffect then
            Internal.indexPendingWorldEffect(order)
        end
        if WorkRepository then WorkRepository.MarkDirty() end
        return false, completionResult or "WORLD_COMPLETION_RETRY"
    end
    -- Runtime cleanup is safe only after the same corpse object has been
    -- verified at the destination and the durable order is terminal. It also
    -- removes the temporary token.
    clearWorkRuntime(order, "corpse_transfer_applied")
    if Internal.indexPendingWorldEffect then
        Internal.indexPendingWorldEffect(order)
    end
    if WorkRepository then WorkRepository.MarkDirty() end
    return true, completionResult
end

local function applyDeferredTransfer(order)
    local assignment = assignmentForWorkOrder(order)
    local effect = order and order.worldEffect
    local sourceSquare
    local destinationSquare
    local corpse
    if not order or not assignment or type(effect) ~= "table" then
        return false, "WORLD_EFFECT_PAYLOAD_INVALID"
    end
    if effect.state == "APPLIED" then
        return finishDeferredTransfer(order, effect)
    end
    sourceSquare = Internal.squareAt(effect.sourceX, effect.sourceY,
        effect.sourceZ)
    destinationSquare = Internal.squareAt(effect.destinationX,
        effect.destinationY, effect.destinationZ)
    if not sourceSquare then
        return deferredWait(order, effect, "SOURCE_CHUNK_LOADING")
    end
    if not destinationSquare then
        return deferredWait(order, effect, "DESTINATION_CHUNK_LOADING")
    end
    corpse = Service.GetCorpseAt(effect.destinationX, effect.destinationY,
        effect.destinationZ, effect.haulToken, effect.deathMarkerId)
    if corpse then
        return finishDeferredTransfer(order, effect, corpse)
    end
    if anyCorpseInSquare(destinationSquare) then
        return deferredWait(order, effect, "DESTINATION_OCCUPIED")
    end
    corpse = Service.GetCorpseAt(effect.sourceX, effect.sourceY,
        effect.sourceZ, effect.haulToken, effect.deathMarkerId)
    if not corpse then
        return deferredWait(order, effect, "SOURCE_CORPSE_MISSING")
    end
    if not Lifecycle or not Lifecycle.Internal
        or not Lifecycle.Internal.moveCorpse
    then
        return deferredWait(order, effect, "CORPSE_TRANSFER_UNAVAILABLE")
    end
    local moved, moveReason = Lifecycle.Internal.moveCorpse(corpse,
        destinationSquare, effect.destinationX, effect.destinationY,
        effect.destinationZ)
    if not moved then
        return deferredWait(order, effect,
            moveReason or "CORPSE_TRANSFER_RETRY")
    end
    return finishDeferredTransfer(order, effect, corpse)
end

Internal.transferCorpse = transferCorpse
Internal.completeWorkOrder = completeWorkOrder
Internal.recoverCompletionFailure = recoverCompletionFailure
Internal.cancelWorkOrder = cancelWorkOrder
Internal.deferredEffectFor = deferredEffectFor
Internal.deferredWait = deferredWait
Internal.anyCorpseInSquare = anyCorpseInSquare
Internal.finishDeferredTransfer = finishDeferredTransfer
Internal.applyDeferredTransfer = applyDeferredTransfer

return Service
