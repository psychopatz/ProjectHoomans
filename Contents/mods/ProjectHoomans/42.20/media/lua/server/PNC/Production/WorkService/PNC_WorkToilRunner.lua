-- Standardized server-authoritative toil lifecycle runner for zone and order chores.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorkToilRunner = PNC.WorkToilRunner or {}

require "PNC/Production/WorkToilRunner/PNC_WorkToilRunner_Steps"
require "PNC/Production/WorkToilRunner/PNC_WorkToilRunner_Approach"

local Runner = PNC.WorkToilRunner

local function nowMs()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

local function resolveDeliveryTarget(order, record, body, lease, adapter, opts)
    if adapter and type(adapter.deliverOutputs) == "function" then
        return adapter.deliverOutputs(order, record, body, lease)
    end
    local outputService = PNC.WorkOutputService
    local effect = order.outputEffect
    if not outputService or not effect then
        Runner.SetOrderPhase(order, Runner.PHASES.COMPLETED, { record = record })
        return true, "COMPLETED"
    end
    local mode = tostring(order.executionMode
        or (lease and lease.executionMode) or "LIVE")
    if body and mode == "LIVE" then
        local ok, done, reason = outputService.TickLiveDelivery(
            order, record, body, effect, nowMs(), opts)
        if done then
            Runner.SetOrderPhase(order, Runner.PHASES.COMPLETED, { record = record })
            return true, reason or "COMPLETED"
        end
        return ok, reason
    end
    local flushed, reason = outputService.FlushAbstractDelivery(
        order, record, effect, nil, opts)
    if flushed then
        Runner.SetOrderPhase(order, Runner.PHASES.COMPLETED, { record = record })
        return true, reason or "COMPLETED"
    end
    return false, reason
end

---Advances a durable work order through ENSURE_TOOLS -> COLLECT_INPUTS ->
---APPROACH_TARGET -> WORK_TARGET -> DELIVER_OUTPUTS.
function Runner.RunToilStep(order, lease, adapter, opts)
    if type(order) ~= "table" then return false, "WORK_ORDER_UNAVAILABLE" end
    opts, adapter = opts or {}, adapter or {}
    local workerId = order.workerId or (lease and lease.npcId)
    local record = workerId and PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(workerId) or nil
    if not record then return false, "WORKER_UNAVAILABLE" end

    local mode = tostring(order.executionMode or (lease and lease.executionMode) or "LIVE")
    local body = mode == "LIVE" and PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(workerId) or nil
    local phase = tostring(order.phase or Runner.PHASES.ENSURE_TOOLS)
    if phase == "" or phase == "WORK_AT_STATION" then
        phase = Runner.PHASES.ENSURE_TOOLS
    end

    if phase == Runner.PHASES.ENSURE_TOOLS then
        local ok, reason
        if adapter.ensureTools then
            ok, reason = adapter.ensureTools(order, record, body, lease)
        else
            ok, reason = Runner.EnsureToolsStep(order, record, body, opts.toolOpts)
        end
        if not ok then
            Runner.SetOrderPhase(order, Runner.PHASES.ENSURE_TOOLS, { record = record })
            return false, reason
        end
        phase = (adapter.collectInputs or order.requiresInputs == true)
            and Runner.PHASES.COLLECT_INPUTS or Runner.PHASES.APPROACH_TARGET
        Runner.SetOrderPhase(order, phase, { record = record })
    end

    if phase == Runner.PHASES.COLLECT_INPUTS then
        local ok, reason = Runner.CollectInputsStep(order, record, body, {
            collectInputs = adapter.collectInputs,
        })
        if not ok then return false, reason end
        phase = Runner.PHASES.APPROACH_TARGET
        Runner.SetOrderPhase(order, phase, { record = record })
    end

    if phase == Runner.PHASES.APPROACH_TARGET then
        local approachState, reason
        if adapter.approachTarget then
            approachState, reason = adapter.approachTarget(order, record, body, lease)
        elseif mode ~= "LIVE" or not body then
            approachState = "arrived"
        else
            local targetPos = adapter.getTargetPos
                and adapter.getTargetPos(order, record, body)
                or { x = order.x, y = order.y, z = order.z }
            approachState = Runner.ObserveLiveApproach(record, body,
                order.targetKey or order.id, targetPos, nowMs(), opts.approachOpts)
        end
        if approachState == "stalled" then
            if adapter.onStalled then
                return adapter.onStalled(order, record, body, reason)
            end
            return false, reason or "TRAVEL_STALLED"
        end
        if approachState ~= "arrived" and approachState ~= true then
            return true, reason or tostring(approachState)
        end
        phase = Runner.PHASES.WORK_TARGET
        Runner.SetOrderPhase(order, phase, { record = record })
    end

    if phase == Runner.PHASES.WORK_TARGET then
        if type(adapter.workTarget) ~= "function" then
            return false, "WORK_TARGET_HANDLER_MISSING"
        end
        local state, reason = adapter.workTarget(order, record, body, lease)
        if state == false then return false, reason end
        if state == "output_ready" or state == "deliver"
            or state == Runner.PHASES.DELIVER_OUTPUTS
        then
            Runner.SetOrderPhase(order, Runner.PHASES.DELIVER_OUTPUTS, { record = record })
            return resolveDeliveryTarget(order, record, body, lease, adapter, opts)
        end
        if state == "completed" or state == Runner.PHASES.COMPLETED then
            Runner.SetOrderPhase(order, Runner.PHASES.COMPLETED, { record = record })
            return true, reason or "COMPLETED"
        end
        return true, reason or "WORKING"
    end

    if phase == Runner.PHASES.DELIVER_OUTPUTS
        or phase == "OUTPUT_APPROACH" or phase == "GRAB_PENDING"
        or phase == "OUTPUT_DESTINATION_APPROACH" or phase == "WAITING_FOR_STOCKPILE"
        or phase == "DEPOSIT_PENDING"
    then
        return resolveDeliveryTarget(order, record, body, lease, adapter, opts)
    end

    return true, phase
end

---Deterministically releases claims, output capacity, staged inputs, held tools,
---and live movement state when a toil order is aborted or preempted.
function Runner.AbortOrder(order, lease, reason)
    if type(order) ~= "table" then return false, "WORK_ORDER_UNAVAILABLE" end
    local abortReason = tostring(reason or "toil_aborted")
    local workerId = order.workerId or (lease and lease.npcId)
    local record = workerId and PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(workerId) or nil
    local body = workerId and PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(workerId) or nil

    local claims = PNC.Tasking and PNC.Tasking.Claims or nil
    if claims then
        if order.id ~= nil and type(claims.ReleaseByOwner) == "function" then
            claims.ReleaseByOwner("order:" .. tostring(order.id), abortReason)
        end
        if lease and lease.leaseId and type(claims.ReleaseByLease) == "function" then
            claims.ReleaseByLease(lease.leaseId, abortReason)
        end
    end

    if PNC.WorkOutputService and type(PNC.WorkOutputService.ReleaseOutputCapacity) == "function" then
        PNC.WorkOutputService.ReleaseOutputCapacity(order, PNC.ColonyStorageService)
    end
    if order.payload and order.payload.input
        and PNC.WorkInputService and type(PNC.WorkInputService.Cancel) == "function"
    then
        PNC.WorkInputService.Cancel(order)
    end
    if record and order.operation
        and PNC.WorkItemService and type(PNC.WorkItemService.Release) == "function"
    then
        PNC.WorkItemService.Release(record, order.operation, nil, { reason = abortReason })
    end
    if record and record.runtime then
        record.runtime.workApproachWatch = nil
        record.runtime.workApproachDiagnostic = nil
    end
    if record and body and PNC.BehaviorCommon
        and type(PNC.BehaviorCommon.HaltMovement) == "function"
    then
        PNC.BehaviorCommon.HaltMovement(record, body, abortReason)
    end
    return true, abortReason
end

return Runner
