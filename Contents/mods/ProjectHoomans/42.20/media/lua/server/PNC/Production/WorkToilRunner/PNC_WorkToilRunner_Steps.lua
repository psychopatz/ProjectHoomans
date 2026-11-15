-- WorkToilRunner phase synchronization, tool checks, and input-collection steps.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorkToilRunner = PNC.WorkToilRunner or {}

local Runner = PNC.WorkToilRunner

Runner.PHASES = {
    ENSURE_TOOLS = "ENSURE_TOOLS",
    COLLECT_INPUTS = "COLLECT_INPUTS",
    APPROACH_TARGET = "APPROACH_TARGET",
    WORK_TARGET = "WORK_TARGET",
    DELIVER_OUTPUTS = "DELIVER_OUTPUTS",
    COMPLETED = "COMPLETED",
}

local function nowMs()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

---Sets the toil phase on an order and synchronizes repository/runtime mirrors.
function Runner.SetOrderPhase(order, phase, opts)
    if type(order) ~= "table" then return end
    opts = opts or {}
    local normalized = tostring(phase or Runner.PHASES.APPROACH_TARGET)
    if order.phase ~= normalized or (opts.status and order.status ~= opts.status) then
        order.phase = normalized
        if opts.status then order.status = opts.status end
        order.updatedAt = nowMs()
        order.revision = (tonumber(order.revision) or 0) + 1
        if PNC.WorkRepository and type(PNC.WorkRepository.MarkDirty) == "function" then
            PNC.WorkRepository.MarkDirty()
        end
    end
    local record = opts.record or (order.workerId and PNC.Registry
        and PNC.Registry.Get and PNC.Registry.Get(order.workerId))
    if record and type(record.orderSpec) == "table" then
        record.orderSpec.phase = normalized
    end
end

---Ensures required operation tools for order/record before work proceeds.
function Runner.EnsureToolsStep(order, record, body, opts)
    local itemService = PNC.WorkItemService
    if not itemService or type(itemService.OperationHasRequirements) ~= "function"
        or not itemService.OperationHasRequirements(order.operation)
    then
        return true, "NO_TOOL_REQUIREMENTS"
    end
    local ok, reason = itemService.Ensure(record, order.operation, body, opts)
    if ok then return true, "TOOLS_READY" end
    if type(itemService.PrepareForWorker) == "function" then
        local prepared, prepareReason = itemService.PrepareForWorker(order, record)
        if prepared then return false, prepareReason or "WAITING_FOR_WORK_ITEM" end
        return false, prepareReason or reason
    end
    return false, reason or "TOOL_UNAVAILABLE"
end

---Executes or verifies the COLLECT_INPUTS phase via WorkService/WorkInputService.
function Runner.CollectInputsStep(order, record, body, opts)
    if order.inputsReady == true then return true, "INPUTS_READY" end
    if opts and type(opts.collectInputs) == "function" then
        return opts.collectInputs(order, record, body)
    end
    if PNC.WorkService and PNC.WorkService.Commands
        and type(PNC.WorkService.Commands.CollectInputs) == "function"
    then
        local ok, reason = PNC.WorkService.Commands.CollectInputs(
            order.id, record and record.id)
        if ok then return true, "INPUTS_COLLECTED" end
        return false, reason or "INPUT_COLLECTION_PENDING"
    end
    return true, "NO_INPUT_SERVICE"
end

return Runner
