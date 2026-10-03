if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorkService = PNC.WorkService or {}
PNC.WorkService.Internal = PNC.WorkService.Internal or {}

local Service = PNC.WorkService
local Internal = Service.Internal
local Repository = PNC.WorkRepository
local Definitions = PNC.WorkDefinitions
local Status = Definitions.STATUS
local now = Internal.now
local terminal = Internal.terminal
local ScalingDiagnostics = PNC.PerformanceScalingDiagnostics
local processOrder = Internal.ProcessOrder

local function pruneTerminalHistory()
    local terminalOrders = {}
    for _, order in pairs(Repository.State.byId) do
        if terminal(order) and order.terminalPersisted == true then
            terminalOrders[#terminalOrders + 1] = order
        end
    end
    table.sort(terminalOrders, function(a, b)
        return (tonumber(a.completedAt or a.cancelledAt) or 0)
            > (tonumber(b.completedAt or b.cancelledAt) or 0)
    end)
    for index = Service.MAX_TERMINAL_HISTORY + 1, #terminalOrders do
        local order = terminalOrders[index]
        local payload = order.payload or {}
        if payload.storageId and PNC.ColonyStorageService
            and PNC.ColonyStorageService.ForgetProductionTransaction
        then
            PNC.ColonyStorageService.ForgetProductionTransaction(
                payload.storageId, order.id)
        end
        Repository.Remove(order.id)
    end
end

function Internal.Tick(at)
    at = tonumber(at) or now()
    if at < Service.NextPassAt then return 0 end
    Service.NextPassAt = at + Definitions.BALANCE.schedulerCadenceMs
    local timerName
    local timerStart
    if ScalingDiagnostics then
        timerName, timerStart = ScalingDiagnostics.BeginTiming(
            "WorkService.Tick", at)
        ScalingDiagnostics.Increment("WorkService.PumpCalls")
    end
    Repository.Load()
    local reconciliationTimerName
    local reconciliationTimerStart
    if ScalingDiagnostics then
        reconciliationTimerName, reconciliationTimerStart =
            ScalingDiagnostics.BeginTiming("WorkService.Reconcile", at)
    end
    Service.ReconcileWorkerState()
    for _, reconcile in pairs(Service.ReconcileHandlers) do
        reconcile()
    end
    if reconciliationTimerName then
        ScalingDiagnostics.EndTiming(
            reconciliationTimerName, reconciliationTimerStart)
    end
    local ids = {}
    for id, order in pairs(Repository.State.byId) do
        if not terminal(order) then ids[#ids + 1] = id end
    end
    table.sort(ids, function(left, right)
        local a, b = Repository.State.byId[left], Repository.State.byId[right]
        if a.priority ~= b.priority then return a.priority > b.priority end
        return a.createdAt < b.createdAt
    end)
    local processed = math.min(#ids, Definitions.BALANCE.maxOrdersPerPass)
    local orderTimerName
    local orderTimerStart
    if ScalingDiagnostics then
        orderTimerName, orderTimerStart = ScalingDiagnostics.BeginTiming(
            "WorkService.Orders", at)
        ScalingDiagnostics.SetGauge("WorkService.PendingOrders", #ids)
    end
    for index = 1, processed do processOrder(Repository.State.byId[ids[index]], at) end
    if orderTimerName then
        ScalingDiagnostics.EndTiming(orderTimerName, orderTimerStart)
    end
    if ScalingDiagnostics then
        ScalingDiagnostics.Increment("WorkService.OrdersInspected", #ids)
        ScalingDiagnostics.Increment("WorkService.OrdersProcessed", processed)
    end
    if at >= Service.NextPruneAt then
        Service.NextPruneAt = at + 60000
        local pruneTimerName
        local pruneTimerStart
        if ScalingDiagnostics then
            pruneTimerName, pruneTimerStart = ScalingDiagnostics.BeginTiming(
                "WorkService.Prune", at)
        end
        pruneTerminalHistory()
        if pruneTimerName then
            ScalingDiagnostics.EndTiming(pruneTimerName, pruneTimerStart)
        end
    end
    if timerName then ScalingDiagnostics.EndTiming(timerName, timerStart) end
    return processed
end

return Service
