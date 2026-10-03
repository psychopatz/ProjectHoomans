-- Corpse haul live and abstract execution progression.
--
-- This provider owns phase advancement and delegates durable effects and
-- cleanup through the work adapter's explicit internal boundaries.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.CorpseHaulService
local Internal = Service.Internal
local Core = PNC.Core
local Registry = PNC.Registry
local Work = PNC.WorkService
local WorkRepository = PNC.WorkRepository
local Status = PNC.WorkDefinitions and PNC.WorkDefinitions.STATUS or {}
local Definitions = PNC.WorkDefinitions

local operationFailure = Internal.operationFailure
local assignmentForWorkOrder = Internal.assignmentForWorkOrder
local workTaskFor = Internal.workTaskFor
local setWorkPhase = Internal.setWorkPhase
local waitForWorld = Internal.waitForWorld
local isDropPointAllowed = Internal.isDropPointAllowed
local actionStatus = Internal.actionStatus
local transferCorpse = Internal.transferCorpse
local deferredEffectFor = Internal.deferredEffectFor
local deferredWait = Internal.deferredWait
local applyDeferredTransfer = Internal.applyDeferredTransfer

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
                        stopDistance = tonumber(
                            Service.CORPSE_CARRY_DROP_DISTANCE) or 1.75,
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
        if distance <= (tonumber(Service.CORPSE_CARRY_DROP_DISTANCE) or 1.75)
        then
            setWorkPhase(order, lease, "DROP_PENDING", Status.WORKING, {
                x = assignment.dropX, y = assignment.dropY,
                z = assignment.dropZ,
                stopDistance = tonumber(
                    Service.CORPSE_CARRY_DROP_DISTANCE) or 1.75,
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
Internal.releaseAbstractWorker = releaseAbstractWorker
Internal.tickAbstractWorkOrder = tickAbstractWorkOrder
Internal.tickWorkOrder = tickWorkOrder

return Service

