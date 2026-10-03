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
local WorkSequence = PNC.WorkSequence

require "PNC/Tasking/CorpseHaulService/PNC_CorpseHaulService_WorkAdapter_Diagnostics"
local operationDiagnostic = Internal.operationDiagnostic
local operationFailure = Internal.operationFailure

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

Internal.assignmentForWorkOrder = assignmentForWorkOrder
Internal.clearCorpseTaskMarker = clearCorpseTaskMarker
require "PNC/Tasking/CorpseHaulService/PNC_CorpseHaulService_WorkAdapter_Cleanup"
local resetLiveWorkState = Internal.resetLiveWorkState
local clearWorkRuntime = Internal.clearWorkRuntime
require "PNC/Tasking/CorpseHaulService/PNC_CorpseHaulService_WorkAdapter_Targeting"
local workTargetProvider = Internal.workTargetProvider
local isDropPointAllowed = Internal.isDropPointAllowed
local waitForWorld = Internal.waitForWorld
local actionStatus = Internal.actionStatus
require "PNC/Tasking/CorpseHaulService/PNC_CorpseHaulService_WorkAdapter_Transfer"
local transferCorpse = Internal.transferCorpse
local completeWorkOrder = Internal.completeWorkOrder
local recoverCompletionFailure = Internal.recoverCompletionFailure
local cancelWorkOrder = Internal.cancelWorkOrder
local deferredEffectFor = Internal.deferredEffectFor
local deferredWait = Internal.deferredWait
local applyDeferredTransfer = Internal.applyDeferredTransfer

Internal.workTaskFor = workTaskFor
Internal.setWorkPhase = setWorkPhase
require "PNC/Tasking/CorpseHaulService/PNC_CorpseHaulService_WorkAdapter_Tick"
local releaseAbstractWorker = Internal.releaseAbstractWorker
local tickAbstractWorkOrder = Internal.tickAbstractWorkOrder
local tickWorkOrder = Internal.tickWorkOrder

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
    if Work.RegisterCompletionRecovery then
        Work.RegisterCompletionRecovery("CORPSE_HAUL",
            recoverCompletionFailure)
    end
    Work.CancellationHandlers = Work.CancellationHandlers or {}
    Work.CancellationHandlers.CORPSE_HAUL = cancelWorkOrder
    return true
end

Internal.assignmentForWorkOrder = assignmentForWorkOrder
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
