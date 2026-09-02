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

local function clearCorpseTaskMarker(x, y, z, token)
    local corpse = Service.GetCorpseAt(x, y, z, token)
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
        assignment.sourceZ, assignment.haulToken)
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
                assignment.sourceZ, assignment.haulToken)
            clearCorpseTaskMarker(assignment.dropX, assignment.dropY,
                assignment.dropZ, assignment.haulToken)
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
    if not live then return { ok = false, reason = "LIVE_WORKER_REQUIRED" } end
    if not assignment then return { ok = false, reason = "CORPSE_PAYLOAD_INVALID" } end
    corpse = Service.GetCorpseAt(assignment.sourceX, assignment.sourceY,
        assignment.sourceZ, assignment.haulToken)
    if not corpse and tostring(order.phase or "") == "CARRYING"
        and Internal.resolveCorpseForCarry
    then
        corpse = Internal.resolveCorpseForCarry(order, nil, live)
    end
    if not corpse then return { ok = false, reason = "CORPSE_NOT_FOUND" } end
    data = corpse.getModData and corpse:getModData() or nil
    if data and data.PNC_CorpseHaulTaskId
        and tostring(data.PNC_CorpseHaulTaskId) ~= tostring(order.id)
    then
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
    local changed = not task or task.worldWaitReason ~= reason
    if task then
        task.worldWaitReason = reason
        if changed or now >= (tonumber(task.lastWorldWaitLogAt) or 0)
            + Service.CORPSE_COUNT_CACHE_MS
        then
            task.lastWorldWaitLogAt = now
            if Core.LogWarn then
                Core.LogWarn("corpse_haul_waiting order=" .. tostring(order.id)
                    .. " reason=" .. tostring(reason))
            end
        end
    end
    order.status = Status.WORKING
    order.blockedReason = reason
    order.updatedAt = now
    if WorkRepository then WorkRepository.MarkDirty() end
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
            assignment.sourceY, assignment.sourceZ, assignment.haulToken)
    end
    if not corpse then
        corpse = Service.GetCorpseAt(assignment.dropX, assignment.dropY,
            assignment.dropZ, assignment.haulToken)
        if corpse then
            local progressed, progressReason = Work.Commands.AddProgress(
                order.id, order.workerId, order.requiredWork)
            return progressed == true, progressReason
        end
        return false, "CORPSE_NOT_FOUND"
    end
    if not Lifecycle or not Lifecycle.Internal
        or (task and task.carrying and not Lifecycle.Internal.followCorpse)
        or (not task or (not task.carrying
            and not Lifecycle.Internal.moveCorpse))
    then
        return false, "CORPSE_TRANSFER_UNAVAILABLE"
    end
    if task and task.carrying and Lifecycle.Internal.followCorpse then
        ok, reason = Lifecycle.Internal.followCorpse(corpse,
            assignment.dropX + 0.5, assignment.dropY + 0.5,
            assignment.dropZ)
    else
        ok, reason = Lifecycle.Internal.moveCorpse(corpse, destinationSquare,
            assignment.dropX, assignment.dropY, assignment.dropZ)
    end
    if not ok then return false, reason end
    local data = corpse.getModData and corpse:getModData() or nil
    if data then
        data.PNC_CorpseHaulTaskId = order.id
        Internal.transmit(corpse)
    end
    local progressed, progressReason = Work.Commands.AddProgress(
        order.id, order.workerId, order.requiredWork)
    return progressed == true, progressReason
end

local function completeWorkOrder(order)
    local assignment = assignmentForWorkOrder(order)
    local corpse = assignment and Service.GetCorpseAt(assignment.dropX,
        assignment.dropY, assignment.dropZ, assignment.haulToken) or nil
    local data = corpse and corpse.getModData and corpse:getModData() or nil
    if not corpse or not data then return false, "CORPSE_NOT_AT_DESTINATION" end
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
        return false, "LIVE_WORKER_REQUIRED"
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
            return false, sequenceReason
        end
        if sequenceState == "completed" then
            if not Internal.squareAt(assignment.sourceX, assignment.sourceY,
                assignment.sourceZ)
            then
                return waitForWorld(order, task, "SOURCE_CHUNK_LOADING")
            end
            if not Service.GetCorpseAt(assignment.sourceX,
                assignment.sourceY, assignment.sourceZ, assignment.haulToken)
            then
                return false, "CORPSE_NOT_FOUND_AFTER_GRAB"
            end
            if Service.CORPSE_CARRY_ENABLED and Internal.beginCorpseCarry then
                local carrying, carryReason = Internal.beginCorpseCarry(
                    order, task, body, assignment)
                if not carrying then return false, carryReason end
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
            return false, "GRAB_TIMEOUT"
        end
        return true
    end
    if task.phase == "CARRYING" then
        if not isDropPointAllowed(assignment) then
            return false, "DROP_REGION_INVALID"
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
                return false, "CORPSE_CARRY_LOST"
            end
            return false, carryReason
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
            return false, "DROP_REGION_INVALID"
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
            return false, sequenceReason
        end
        if sequenceState == "completed" then
            return transferCorpse(order, assignment, task)
        elseif now - (tonumber(task.phaseStartedAt) or now)
            > Service.INTERACTION_TIMEOUT_MS
        then
            return false, "DROP_TIMEOUT"
        end
        return true
    end
    return false, "UNKNOWN_HAUL_PHASE"
end

local function bindWorkService()
    if not Work or not Work.RegisterTargetProvider
        or not Work.RegisterExecution
        or not Work.RegisterCompletion
    then return false end
    Work.RegisterTargetProvider("CORPSE_HAUL", workTargetProvider)
    Work.RegisterExecution("CORPSE_HAUL", tickWorkOrder)
    Work.RegisterCompletion("CORPSE_HAUL", completeWorkOrder)
    Work.CancellationHandlers = Work.CancellationHandlers or {}
    Work.CancellationHandlers.CORPSE_HAUL = cancelWorkOrder
    return true
end

Internal.assignmentForWorkOrder = assignmentForWorkOrder
Internal.clearWorkRuntime = clearWorkRuntime
Internal.bindWorkService = bindWorkService

return Service
