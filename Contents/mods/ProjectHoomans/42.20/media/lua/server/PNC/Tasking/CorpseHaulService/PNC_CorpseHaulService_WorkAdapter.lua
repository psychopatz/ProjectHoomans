if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.CorpseHaulService
local Internal = Service.Internal
local Core = PNC.Core
local Registry = PNC.Registry
local Lifecycle = PNC.BodyLifecycle
local Stockpile = PNC.StockpileAccessService
local Work = PNC.WorkService
local WorkRepository = PNC.WorkRepository
local Status = PNC.WorkDefinitions and PNC.WorkDefinitions.STATUS or {}
local WorldEffects = PNC.WorldEffectService
local Definitions = PNC.WorkDefinitions
local WorkSequence = PNC.WorkSequence
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"

function Service.GetTask(taskId)
    return Service.Runtime.byTask[tostring(taskId or "")]
end

function Service.IsLifecycleProtected(taskId)
    local task = Service.GetTask(taskId)
    if task then return true end
    local order
    if WorkRepository and WorkRepository.Get then
        order = WorkRepository.Get(taskId)
    end
    return order ~= nil and order.operation == "CORPSE_HAUL"
        and not Internal.terminalWorkOrder(order)
end

function Service.IsRecordProtected(record)
    local runtime = record and record.runtime or nil
    local taskId = runtime and (runtime.corpseHaulTaskId
        or runtime.workOrderId) or nil
    return taskId ~= nil and Service.IsLifecycleProtected(taskId)
end

-- Keep the operation boundary observable. WorkTaskProvider intentionally
-- releases a failed lease so another worker can retry, which otherwise erases
-- the failure from the durable order and leaves only a generic WAITING state.
-- The task/order retain the last reason while console output is throttled per
-- stage/reason pair.
local function operationDiagnostic(order, task, record, stage, reason, kind)
    if not order then return end
    local now = Core.Now()
    local normalizedStage = tostring(stage or "UNKNOWN")
    local normalizedReason = tostring(reason or "UNKNOWN")
    local key = normalizedStage .. ":" .. normalizedReason
    local shouldLog = true
    local stateChanged = order.lastDiagnosticReason ~= normalizedReason
        or order.lastDiagnosticStage ~= normalizedStage
    local failureChanged = tostring(kind or "FAIL") == "FAIL"
        and (order.lastExecutionFailureReason ~= normalizedReason
            or order.lastExecutionFailurePhase
                ~= tostring(order.phase or ""))
    local previousKey = task and task.lastDiagnosticKey
        or order.lastDiagnosticKey
    local previousAt = task and tonumber(task.lastDiagnosticAt)
        or tonumber(order.lastDiagnosticLogAt)
    local interval = kind == "WAIT"
        and (tonumber(Service.CORPSE_HAUL_WORLD_WAIT_DIAGNOSTIC_INTERVAL_MS)
            or 30000)
        or tonumber(Service.CORPSE_HAUL_DIAGNOSTIC_INTERVAL_MS) or 2000
    if previousKey == key and previousAt
        and now - previousAt < interval
    then
        shouldLog = false
    end
    if shouldLog and task then
        task.lastDiagnosticKey = key
        task.lastDiagnosticAt = now
    end
    if shouldLog then
        order.lastDiagnosticKey = key
        order.lastDiagnosticLogAt = now
    end
    record = record or Registry and Registry.Get
        and Registry.Get(order.workerId) or nil
    if stateChanged then
        order.lastDiagnosticReason = normalizedReason
        order.lastDiagnosticStage = normalizedStage
        order.lastDiagnosticAt = now
    end
    if failureChanged then
        order.lastExecutionFailureReason = normalizedReason
        order.lastExecutionFailurePhase = tostring(order.phase or "")
        order.lastExecutionFailureAt = now
    end
    if (stateChanged or failureChanged or shouldLog)
        and WorkRepository and WorkRepository.MarkDirty
    then
        WorkRepository.MarkDirty()
    end
    if shouldLog and Core.Log then
        local payload = order.payload or {}
        local live = record and Registry and Registry.GetLiveZombie
            and Registry.GetLiveZombie(record.id) or nil
        local x = tonumber(live and live.getX and live:getX())
            or tonumber(record and record.x) or "?"
        local y = tonumber(live and live.getY and live:getY())
            or tonumber(record and record.y) or "?"
        local z = tonumber(live and live.getZ and live:getZ())
            or tonumber(record and record.z) or "?"
        Core.Log(kind == "WAIT" and "INFO" or "WARN",
            "corpse_haul_diagnostic stage="
            .. normalizedStage .. " kind=" .. tostring(kind or "FAIL")
            .. " order=" .. tostring(order.id or "unknown")
            .. " npc=" .. tostring(order.workerId or record and record.id
                or "unknown")
            .. " phase=" .. tostring(order.phase or "")
            .. " status=" .. tostring(order.status or "")
            .. " reason=" .. normalizedReason
            .. " pos=" .. tostring(x) .. "," .. tostring(y) .. ","
            .. tostring(z)
            .. " source=" .. tostring(payload.sourceX or "?") .. ","
            .. tostring(payload.sourceY or "?") .. ","
            .. tostring(payload.sourceZ or "?")
            .. " token=" .. tostring(payload.haulToken or "?")
            .. " death=" .. tostring(payload.deathMarkerId
                or payload.corpseId or "?"))
    end
end

local function operationFailure(order, task, record, stage, reason)
    operationDiagnostic(order, task, record, stage, reason, "FAIL")
    return false, reason
end

local function clearCorpseTaskMarker(x, y, z, token, deathMarkerId)
    local corpse = Service.GetCorpseAt(x, y, z, token, deathMarkerId)
    local data = corpse and corpse.getModData and corpse:getModData() or nil
    local changed = false
    if data and tostring(data.PNC_CorpseHaulTaskId or "") ~= "" then
        data.PNC_CorpseHaulTaskId = nil
        changed = true
    end
    if Internal.clearCorpseHaulToken(corpse, token) then changed = true end
    if changed then Internal.transmit(corpse) end
end

local function assignmentForWorkOrder(order)
    local payload = order and order.payload or nil
    local token = tostring(payload and payload.haulToken or "")
    if token == "" then return nil end
    local sourceX = tonumber(payload.sourceX)
    local sourceY = tonumber(payload.sourceY)
    local sourceZ = tonumber(payload.sourceZ)
    local dropX = tonumber(payload.dropX)
    local dropY = tonumber(payload.dropY)
    local dropZ = tonumber(payload.dropZ)
    if not sourceX or not sourceY or not sourceZ
        or not dropX or not dropY or not dropZ
    then return nil end
    return {
        taskId = tostring(order.id), haulToken = token,
        deathMarkerId = payload.deathMarkerId or payload.corpseId,
        baseId = order.baseId, facilityId = payload.facilityId,
        sourceX = sourceX, sourceY = sourceY, sourceZ = sourceZ,
        interactionX = tonumber(payload.interactionX) or sourceX,
        interactionY = tonumber(payload.interactionY) or sourceY,
        interactionZ = tonumber(payload.interactionZ) or sourceZ,
        dropX = dropX, dropY = dropY, dropZ = dropZ,
        carryX = tonumber(payload.carryX),
        carryY = tonumber(payload.carryY),
        carryZ = tonumber(payload.carryZ),
        destinationRegion = payload.destinationRegion
            and (Core.DeepCopy and Core.DeepCopy(payload.destinationRegion)
                or payload.destinationRegion) or nil,
    }
end

local function workTaskFor(order, lease, assignment)
    local taskId = tostring(order and order.id or lease and lease.taskId or "")
    local task = Service.Runtime.byTask[taskId]
    local record = Registry and Registry.Get and Registry.Get(lease.npcId) or nil
    local corpse = Service.GetCorpseAt(assignment.sourceX, assignment.sourceY,
        assignment.sourceZ, assignment.haulToken,
        assignment.deathMarkerId)
    if not task then
        task = {
            taskId = taskId, haulToken = assignment.haulToken,
            npcId = tostring(lease.npcId),
            dropKey = Internal.pointKey(assignment.dropX, assignment.dropY,
                assignment.dropZ),
            phase = tostring(order.phase or "SOURCE_APPROACH"),
        }
        Service.Runtime.byTask[taskId] = task
        Service.Runtime.byToken[assignment.haulToken] = taskId
        Service.Runtime.byDrop[task.dropKey] = taskId
    end
    if record then
        record.runtime = record.runtime or {}
        record.runtime.corpseHaulTaskId = taskId
    end
    if corpse and corpse.getModData then
        local data = corpse:getModData()
        if data then
            data.PNC_CorpseHaulTaskId = taskId
            Internal.transmit(corpse)
        end
    end
    task.phase = tostring(order.phase or task.phase or "SOURCE_APPROACH")
    return task
end

local function setWorkPhase(order, lease, phase, status, target)
    local record = Registry and Registry.Get and Registry.Get(order.workerId)
        or nil
    local assignment = assignmentForWorkOrder(order)
    order.phase, order.status = phase, status
    order.livePhase = phase
    order.blockedReason = nil
    order.updatedAt, order.lastProgressAt = Core.Now(), Core.Now()
    order.revision = (tonumber(order.revision) or 0) + 1
    if target then order.stationTarget = {
        x = target.x, y = target.y, z = target.z,
    } end
    if lease then
        local task = Service.Runtime.byTask[tostring(order.id)]
        if task then
            task.phase = phase
            task.phaseStartedAt = Core.Now()
        end
        if PNC.TaskLeaseService and PNC.TaskLeaseService.SetPhase then
            local leasePhase
            if phase == "GRAB_PENDING" then
                leasePhase = "WAITING"
            elseif phase == "DROP_PENDING" then
                leasePhase = "ATOMIC_COMMIT"
            elseif phase == "SOURCE_APPROACH"
                or phase == "DESTINATION_APPROACH"
                or phase == "CARRYING"
            then
                leasePhase = "TRAVEL"
            else
                leasePhase = "WORKING"
            end
            PNC.TaskLeaseService.SetPhase(lease.leaseId, leasePhase)
        end
    end
    if record and assignment and target and PNC.WorkService
        and PNC.WorkService.Internal
        and PNC.WorkService.Internal.setLiveOrder
    then
        PNC.WorkService.Internal.setLiveOrder(record, order, target, phase)
    end
    if WorkRepository then WorkRepository.MarkDirty() end
end

local function resetLiveWorkState(record, zombie, reason)
    local runtime = record and record.runtime or nil
    local sceneStopped = false
    local pathReset = false
    local pathService = PNC.PathService
    local scene = runtime and runtime.animationScene or nil
    local sequence = runtime and runtime.workSequence or nil
    local ownsScene = scene
        and (
            sequence and tostring(sequence.sceneId or "")
                == tostring(scene.id or "")
            or tostring(scene.id or "") == "production.corpse_grab"
            or tostring(scene.id or "") == "production.corpse_drop"
        )

    if not runtime then return sceneStopped, pathReset end

    -- Corpse interaction scenes are intentionally nonblocking, so they do
    -- not synchronously revoke a route when an order leaves the worker. The
    -- operation boundary must do that explicitly or a stale Follow/native
    -- route can keep owning the body after the corpse task is gone.
    if ownsScene
        and PNC.AnimationScenes
        and PNC.AnimationScenes.Stop
    then
        sceneStopped = PNC.AnimationScenes.Stop(
            record,
            zombie,
            reason or "corpse_haul_cleanup"
        ) == true
    end

    if pathService and pathService.Commands
        and pathService.Commands.Reset
    then
        pathService.Commands.Reset(
            record,
            zombie,
            reason or "corpse_haul_cleanup"
        )
        pathReset = true
    elseif pathService and pathService.Reset then
        pathService.Reset(zombie, record, reason or "corpse_haul_cleanup")
        pathReset = true
    else
        runtime.localNavigation = nil
        runtime.pathing = nil
        runtime.moveIntent = nil
    end

    -- Follow state is a separate owner-movement projection and can outlive
    -- the movement lane. A terminal corpse operation must not leave that
    -- sampled flag behind for the next order.
    runtime.followState = nil
    runtime.target = nil
    runtime.corpseHaulCarrying = nil
    runtime.lastPathX = nil
    runtime.lastPathY = nil
    runtime.corpseHaulCleanupAt = Core.Now()
    runtime.corpseHaulCleanupReason = reason or "corpse_haul_cleanup"
    runtime.corpseHaulCleanupSceneStopped = sceneStopped
    runtime.corpseHaulCleanupPathReset = pathReset
    if zombie and zombie.setVariable then
        zombie:setVariable("PNCCorpseCarrying", false)
    end
    return sceneStopped, pathReset
end

local function clearWorkRuntime(order, reason)
    local taskId = tostring(order and order.id or "")
    local assignment = assignmentForWorkOrder(order)
    local task = Service.Runtime.byTask[taskId]
    local record = order and order.workerId and Registry and Registry.Get
        and Registry.Get(order.workerId) or nil
    local zombie = record and Registry and Registry.GetLiveZombie
        and Registry.GetLiveZombie(record.id) or nil
    local status = order and tostring(order.status or "") or ""
    local preserveCarriedCorpse = (task and task.carrying
        or tostring(order.phase or "") == "CARRYING")
        and order.completionStarted ~= true
        and status ~= tostring(Status.CANCELLING or "CANCELLING")
        and status ~= tostring(Status.CANCELLED or "CANCELLED")
        and status ~= tostring(Status.COMPLETED or "COMPLETED")
        and status ~= tostring(Status.FAILED or "FAILED")
    if preserveCarriedCorpse and task and order.payload
        and task.carryX and task.carryY and task.carryZ
    then
        order.payload.carryX, order.payload.carryY, order.payload.carryZ =
            task.carryX, task.carryY, task.carryZ
    end
    resetLiveWorkState(record, zombie, reason)
    local carriedCorpse = Internal.clearCorpseCarry
        and Internal.clearCorpseCarry(order, task, zombie) or nil
    if carriedCorpse then
        local data = carriedCorpse.getModData
            and carriedCorpse:getModData() or nil
        if not preserveCarriedCorpse and data
            and tostring(data.PNC_CorpseHaulTaskId or "")
            == taskId
        then
            data.PNC_CorpseHaulTaskId = nil
            Internal.transmit(carriedCorpse)
        end
        if not preserveCarriedCorpse
            and Internal.clearCorpseHaulToken(carriedCorpse,
                assignment and assignment.haulToken or nil)
        then
            Internal.transmit(carriedCorpse)
        end
    end
    if assignment then
        if not preserveCarriedCorpse then
            clearCorpseTaskMarker(assignment.sourceX, assignment.sourceY,
                assignment.sourceZ, assignment.haulToken,
                assignment.deathMarkerId)
            clearCorpseTaskMarker(assignment.dropX, assignment.dropY,
                assignment.dropZ, assignment.haulToken,
                assignment.deathMarkerId)
        end
        Service.Runtime.byToken[assignment.haulToken] = nil
        Service.Runtime.byDrop[Internal.pointKey(assignment.dropX,
            assignment.dropY, assignment.dropZ)] = nil
    end
    if not preserveCarriedCorpse and order and order.payload then
        order.payload.carryX, order.payload.carryY, order.payload.carryZ = nil,
            nil, nil
    end
    Service.Runtime.byTask[taskId] = nil
    if record and record.runtime
        and tostring(record.runtime.corpseHaulTaskId or "") == taskId
    then
        record.runtime.corpseHaulTaskId = nil
    end
    if record and WorkSequence and WorkSequence.Reset then
        WorkSequence.Reset(record)
    end
end

local function workTargetProvider(order, worker, live)
    local assignment = assignmentForWorkOrder(order)
    local corpse
    local data
    local phase
    local targetX
    local targetY
    local targetZ
    if not assignment then
        operationDiagnostic(order, nil, worker, "TARGET",
            "CORPSE_PAYLOAD_INVALID", "FAIL")
        return { ok = false, reason = "CORPSE_PAYLOAD_INVALID" }
    end
    if not live then
        -- Abstract claiming reserves only the durable identity and target
        -- coordinates. It must not inspect or navigate the corpse: its source
        -- chunk may be unloaded, which is a normal state for simulation.
        phase = tostring(order.phase or "SOURCE_APPROACH")
        return {
            ok = true, componentId = "corpse:" .. assignment.haulToken,
            claimKey = "corpse:" .. assignment.haulToken,
            targetKind = "corpse_transfer", target = {
                x = assignment.dropX, y = assignment.dropY,
                z = assignment.dropZ,
            }, phase = phase,
        }
    end
    corpse = Service.GetCorpseAt(assignment.sourceX, assignment.sourceY,
        assignment.sourceZ, assignment.haulToken,
        assignment.deathMarkerId)
    if not corpse and tostring(order.phase or "") == "CARRYING"
        and Internal.resolveCorpseForCarry
    then
        corpse = Internal.resolveCorpseForCarry(order, nil, live)
    end
    if not corpse then
        operationDiagnostic(order, nil, worker, "TARGET", "CORPSE_NOT_FOUND",
            "FAIL")
        return { ok = false, reason = "CORPSE_NOT_FOUND" }
    end
    data = corpse.getModData and corpse:getModData() or nil
    if data and data.PNC_CorpseHaulTaskId
        and tostring(data.PNC_CorpseHaulTaskId) ~= tostring(order.id)
    then
        operationDiagnostic(order, nil, worker, "TARGET",
            "CORPSE_ALREADY_RESERVED", "FAIL")
        return { ok = false, reason = "CORPSE_ALREADY_RESERVED" }
    end
    phase = tostring(order.phase or "SOURCE_APPROACH")
    if phase == "DESTINATION_APPROACH" or phase == "CARRYING"
        or phase == "DROP_PENDING"
    then
        targetX, targetY, targetZ = assignment.dropX, assignment.dropY,
            assignment.dropZ
    else
        targetX, targetY, targetZ = assignment.interactionX,
            assignment.interactionY, assignment.interactionZ
    end
    return {
        ok = true, componentId = "corpse:" .. assignment.haulToken,
        claimKey = "corpse:" .. assignment.haulToken,
        targetKind = "corpse", target = {
            x = targetX, y = targetY, z = targetZ,
        },
        phase = phase,
    }
end

local function isDropPointAllowed(assignment)
    local x = assignment and assignment.dropX
    local y = assignment and assignment.dropY
    local z = assignment and assignment.dropZ
    if not assignment then return false end
    if assignment.destinationRegion then
        return GridRegion.containsPoint(assignment.destinationRegion, x, y, z)
    end
    if not Stockpile then return false end
    if Stockpile.ContainsFacilityRegionTile then
        return Stockpile.ContainsFacilityRegionTile(assignment.facilityId,
            x, y, z) == true
    end
    local region = Stockpile.GetFacilityRegion
        and Stockpile.GetFacilityRegion(assignment.facilityId) or nil
    return region ~= nil and GridRegion.containsPoint(region, x, y, z) == true
end

local function waitForWorld(order, task, reason)
    local now = Core.Now()
    local sameState = order.status == (Status.WAITING_FOR_WORLD
        or "WAITING_FOR_WORLD")
        and tostring(order.blockedReason or "") == tostring(reason or "")
    operationDiagnostic(order, task, nil, "WORLD_WAIT", reason, "WAIT")
    if task then
        task.worldWaitReason = reason
    end
    order.status = Status.WAITING_FOR_WORLD or "WAITING_FOR_WORLD"
    order.blockedReason = reason
    if not sameState then
        order.updatedAt = now
        if WorkRepository then WorkRepository.MarkDirty() end
    end
    return true
end

local function actionStatus(record, order)
    if not WorkSequence or not WorkSequence.Status then
        return "failed", "WORK_SEQUENCE_UNAVAILABLE"
    end
    local status = WorkSequence.Status(record, order)
    if status == "failed" then
        local state = WorkSequence.GetState and WorkSequence.GetState(record)
        return status, state and state.failed or "WORK_SCENE_FAILED"
    end
    return status
end

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

local function releaseAbstractWorker(order)
    if not order or not order.workerId or not Work
        or not Work.Commands or not Work.Commands.ReleaseWorker
    then return true end
    local released, reason = Work.Commands.ReleaseWorker(order.workerId,
        "world_effect_pending")
    return released == true, reason or "WORLD_EFFECT_WORKER_RELEASE_FAILED"
end

local function tickAbstractWorkOrder(order)
    order = WorkRepository and WorkRepository.Get(order and order.id) or order
    if not order then return false, "WORK_ORDER_UNAVAILABLE" end
    if order.status == Status.WORLD_EFFECT_PENDING then
        return applyDeferredTransfer(order)
    end
    local assignment = assignmentForWorkOrder(order)
    local record = order.workerId and Registry and Registry.Get
        and Registry.Get(order.workerId) or nil
    if not assignment then
        return operationFailure(order, nil, record, "ABSTRACT",
            "CORPSE_PAYLOAD_INVALID")
    end
    if not record or record.alive == false then
        return operationFailure(order, nil, record, "ABSTRACT",
            "ABSTRACT_WORKER_UNAVAILABLE")
    end
    local current = Core.Now()
    local previous = tonumber(order.lastAbstractAt)
        or tonumber(order.lastProgressAt) or current
    local elapsed = math.max(0, math.min(
        tonumber(Definitions.BALANCE.maxElapsedSeconds) or 10,
        (current - previous) / 1000))
    local rate, rateReason = Definitions.WorkRate(record,
        order.requiredSkills, 1, 1)
    order.lastAbstractAt = current
    if rate <= 0 then
        return operationFailure(order, nil, record, "ABSTRACT",
            rateReason or "ABSTRACT_WORK_RATE_UNAVAILABLE")
    end
    if elapsed <= 0 then return true end
    order.status = Status.WORKING
    order.progress = math.min(order.requiredWork,
        (tonumber(order.progress) or 0) + rate * elapsed)
    order.lastProgressAt, order.updatedAt = current, current
    order.revision = (tonumber(order.revision) or 0) + 1
    if order.progress < order.requiredWork then
        if WorkRepository then WorkRepository.MarkDirty() end
        return true
    end
    order.progress = order.requiredWork
    order.worldEffect = order.worldEffect or deferredEffectFor(order, assignment)
    order.worldEffect.kind = "CORPSE_TRANSFER"
    local waited, waitReason = deferredWait(order, order.worldEffect,
        "WORLD_EFFECT_READY")
    if waited ~= true then return false, waitReason end
    local applied, applyReason = applyDeferredTransfer(order)
    if applied == true and order.status == Status.COMPLETED then return true end
    local released, releaseReason = releaseAbstractWorker(order)
    if released ~= true then
        return operationFailure(order, nil, record, "ABSTRACT",
            releaseReason)
    end
    return true, applyReason
end

local function tickWorkOrder(order, lease)
    order = WorkRepository and WorkRepository.Get(order and order.id) or order
    local assignment = assignmentForWorkOrder(order)
    local record = order and Registry and Registry.Get
        and Registry.Get(order.workerId) or nil
    local body = record and Registry.GetLiveZombie
        and Registry.GetLiveZombie(record.id) or nil
    local task
    local now = Core.Now()
    local distance
    if not assignment or not record or not body then
        return operationFailure(order, nil, record, "EXECUTE",
            "LIVE_WORKER_REQUIRED")
    end
    task = workTaskFor(order, lease, assignment)
    task.phase = tostring(order.phase or task.phase or "SOURCE_APPROACH")
    if task.phase ~= "GRAB_PENDING" and task.phase ~= "DROP_PENDING" then
        task.worldWaitReason = nil
    end
    if task.phase == "SOURCE_APPROACH" then
        distance = Core.Distance(body:getX(), body:getY(),
            assignment.interactionX, assignment.interactionY)
        if distance <= 1.5 then
            setWorkPhase(order, lease, "GRAB_PENDING", Status.WORKING, {
                x = assignment.interactionX, y = assignment.interactionY,
                z = assignment.interactionZ,
            })
        end
        return true
    end
    if task.phase == "GRAB_PENDING" then
        local sequenceState, sequenceReason = actionStatus(record, order)
        if sequenceState == "failed" then
            return operationFailure(order, task, record, "GRAB",
                sequenceReason or "WORK_SEQUENCE_FAILED")
        end
        if sequenceState == "completed" then
            if not Internal.squareAt(assignment.sourceX, assignment.sourceY,
                assignment.sourceZ)
            then
                return waitForWorld(order, task, "SOURCE_CHUNK_LOADING")
            end
            if not Service.GetCorpseAt(assignment.sourceX,
                assignment.sourceY, assignment.sourceZ, assignment.haulToken,
                assignment.deathMarkerId)
            then
                return operationFailure(order, task, record, "GRAB",
                    "CORPSE_NOT_FOUND_AFTER_GRAB")
            end
            if Service.CORPSE_CARRY_ENABLED and Internal.beginCorpseCarry then
                local carrying, carryReason = Internal.beginCorpseCarry(
                    order, task, body, assignment)
                if not carrying then
                    return operationFailure(order, task, record, "GRAB",
                        carryReason or "CORPSE_CARRY_FAILED")
                end
                setWorkPhase(order, lease, "CARRYING",
                    Status.TRAVEL_TO_STATION, {
                        x = assignment.dropX, y = assignment.dropY,
                        z = assignment.dropZ,
                    })
            else
                setWorkPhase(order, lease, "DESTINATION_APPROACH",
                    Status.TRAVEL_TO_STATION, {
                        x = assignment.dropX, y = assignment.dropY,
                        z = assignment.dropZ,
                    })
            end
        elseif now - (tonumber(task.phaseStartedAt) or now)
            > Service.INTERACTION_TIMEOUT_MS
        then
            return operationFailure(order, task, record, "GRAB",
                "GRAB_TIMEOUT")
        end
        return true
    end
    if task.phase == "CARRYING" then
        if not isDropPointAllowed(assignment) then
            return operationFailure(order, task, record, "CARRY",
                "DROP_REGION_INVALID")
        end
        local carried
        local carryReason
        if Internal.tickCorpseCarry then
            carried, carryReason = Internal.tickCorpseCarry(order, task,
                record, body, assignment, now)
        else
            carried, carryReason = false, "CORPSE_CARRY_UNAVAILABLE"
        end
        if not carried then
            if carryReason == "CORPSE_FOLLOW_DESTINATION_UNAVAILABLE"
                or carryReason == "CORPSE_FOLLOW_SOURCE_UNAVAILABLE"
                or carryReason == "CORPSE_NOT_FOUND_WHILE_CARRYING"
            then
                task.carryMissingSince = task.carryMissingSince or now
                if now - task.carryMissingSince
                    <= (tonumber(Service.CORPSE_CARRY_RECOVERY_TIMEOUT_MS)
                        or 15000)
                then
                    return waitForWorld(order, task, "CARRY_CORPSE_LOADING")
                end
                return operationFailure(order, task, record, "CARRY",
                    "CORPSE_CARRY_LOST")
            end
            return operationFailure(order, task, record, "CARRY",
                carryReason or "CORPSE_CARRY_FAILED")
        end
        task.carryMissingSince = nil
        distance = Core.Distance(body:getX(), body:getY(),
            assignment.dropX, assignment.dropY)
        if distance <= 0.8 then
            setWorkPhase(order, lease, "DROP_PENDING", Status.WORKING, {
                x = assignment.dropX, y = assignment.dropY,
                z = assignment.dropZ,
            })
        end
        return true
    end
    if task.phase == "DESTINATION_APPROACH" then
        if not isDropPointAllowed(assignment) then
            return operationFailure(order, task, record, "DESTINATION",
                "DROP_REGION_INVALID")
        end
        distance = Core.Distance(body:getX(), body:getY(),
            assignment.dropX, assignment.dropY)
        if distance <= 0.8 then
            setWorkPhase(order, lease, "DROP_PENDING", Status.WORKING, {
                x = assignment.dropX, y = assignment.dropY,
                z = assignment.dropZ,
            })
        end
        return true
    end
    if task.phase == "DROP_PENDING" then
        local sequenceState, sequenceReason = actionStatus(record, order)
        if sequenceState == "failed" then
            return operationFailure(order, task, record, "DROP",
                sequenceReason or "WORK_SEQUENCE_FAILED")
        end
        if sequenceState == "completed" then
            return transferCorpse(order, assignment, task)
        elseif now - (tonumber(task.phaseStartedAt) or now)
            > Service.INTERACTION_TIMEOUT_MS
        then
            return operationFailure(order, task, record, "DROP",
                "DROP_TIMEOUT")
        end
        return true
    end
    return operationFailure(order, task, record, "EXECUTE",
        "UNKNOWN_HAUL_PHASE")
end

local function bindWorkService()
    if not Work or not Work.RegisterTargetProvider
        or not Work.RegisterExecution
        or not Work.RegisterAbstractExecution
        or not Work.RegisterCompletion
    then return false end
    Work.RegisterTargetProvider("CORPSE_HAUL", workTargetProvider)
    Work.RegisterExecution("CORPSE_HAUL", tickWorkOrder)
    Work.RegisterAbstractExecution("CORPSE_HAUL", tickAbstractWorkOrder)
    Work.RegisterCompletion("CORPSE_HAUL", completeWorkOrder)
    Work.CancellationHandlers = Work.CancellationHandlers or {}
    Work.CancellationHandlers.CORPSE_HAUL = cancelWorkOrder
    return true
end

Internal.assignmentForWorkOrder = assignmentForWorkOrder
Internal.clearWorkRuntime = clearWorkRuntime
Internal.applyDeferredCorpseTransfer = applyDeferredTransfer
Internal.bindWorkService = bindWorkService

if WorldEffects and WorldEffects.Register then
    WorldEffects.Register("CORPSE_TRANSFER", {
        Apply = function(order)
            return applyDeferredTransfer(order)
        end,
        GetPoints = function(_, effect)
            return {
                { role = "source", x = effect.sourceX,
                    y = effect.sourceY, z = effect.sourceZ },
                { role = "destination", x = effect.destinationX,
                    y = effect.destinationY, z = effect.destinationZ },
            }
        end,
    })
end

return Service
