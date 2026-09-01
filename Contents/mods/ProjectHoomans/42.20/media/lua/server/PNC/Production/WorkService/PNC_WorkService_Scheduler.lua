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
local EventsBus = PsychopatzCore and PsychopatzCore.Events
local EventTypes = PNC.EventTypes or {}
local now = Internal.now
local terminal = Internal.terminal
local copy = Internal.copy
local markAssignmentDirty = Internal.markAssignmentDirty
local findWorker = Internal.findWorker
local releaseClaim = Internal.releaseClaim
local collectionTarget = Internal.collectionTarget
local requiresCollection = Internal.requiresCollection
local setLiveOrder = Internal.setLiveOrder
local claimStation = Internal.claimStation
local requiresHome = Internal.requiresHome
local autoReturnHome = Internal.autoReturnHome
local isFollowing = Internal.isFollowing

local function processOrder(order, at)
    if terminal(order) or order.status == Status.PAUSED then return end
    if order.status == Status.CANCELLING
        or order.cancellationRequested == true
    then
        Service.Commands.Cancel(order.id,
            order.cancellationReason or "recovered_cancellation")
        return
    end
    local prepare = Service.PreparationHandlers[order.operation]
    if prepare then
        local ready, preparationReason = prepare(order)
        if ready ~= true then
            order.status, order.blockedReason = Status.BLOCKED,
                tostring(preparationReason or "INPUT_RESERVATION_UNAVAILABLE")
            Repository.MarkDirty(); return
        elseif order.status == Status.BLOCKED then
            order.status, order.blockedReason = Status.WAITING_FOR_WORKER, nil
            Repository.MarkDirty()
        end
    end
    local worker = order.workerId and PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(order.workerId) or nil
    if order.workerId and (not worker or worker.alive == false) then
        releaseClaim(order, "worker_unavailable", false, true)
        order.status, order.blockedReason = Status.WAITING_FOR_WORKER,
            "NO_QUALIFIED_WORKER"
        Repository.MarkDirty(); return
    end
    if not worker then
        if PNC.Tasking and PNC.Tasking.Providers
            and PNC.Tasking.Providers.work
        then
            order.status = Status.WAITING_FOR_WORKER
            local retryAt = tonumber(Service.AssignmentRetryAt
                and Service.AssignmentRetryAt[order.id]) or 0
            if at >= retryAt then
                Service.AssignmentRetryAt = Service.AssignmentRetryAt or {}
                Service.AssignmentRetryAt[order.id] = at + 5000
                markAssignmentDirty(order, "WORK_REQUEST_WAITING")
            end
            return
        end
        local waitingReason
        worker, waitingReason = findWorker(order)
        if not worker then
            order.status, order.blockedReason = Status.WAITING_FOR_WORKER,
                waitingReason or "NO_QUALIFIED_WORKER"
            return
        end
        local ok, reason = claimStation(order, worker)
        if not ok then
            order.status, order.blockedReason = Status.BLOCKED, reason
            Repository.MarkDirty(); return
        end
    end
    local returningHome = PNC.HomeDutyService
        and PNC.HomeDutyService.IsReturningHome
        and PNC.HomeDutyService.IsReturningHome(worker, order.baseId)
    local followingDuringProvision = order.operation == "PROVISION_PICKUP"
        and isFollowing and isFollowing(worker)
    if returningHome or followingDuringProvision
        or (requiresHome(order) and PNC.HomeDutyService
        and PNC.HomeDutyService.IsAtHome
        and not PNC.HomeDutyService.IsAtHome(worker, order.baseId))
    then
        releaseClaim(order, "worker_left_home", false, true)
        order.status, order.blockedReason = Status.WAITING_FOR_WORKER,
            autoReturnHome(order) and "WORKER_RETURNING_HOME"
                or "WORKER_NOT_AT_HOME"
        if autoReturnHome(order) and PNC.HomeDutyService
            and PNC.HomeDutyService.SendHome
        then
            PNC.HomeDutyService.SendHome(worker, order.baseId,
                "worker_left_home")
        end
        Repository.MarkDirty()
        return
    end
    local live = PNC.Registry.GetLiveZombie and PNC.Registry.GetLiveZombie(worker.id)
    local mode = live and "LIVE" or "ABSTRACT"
    if order.facilityReservationId and PNC.FacilityReservations then
        local renewed = PNC.FacilityReservations.Start(
            order.facilityReservationId, 30000)
        if not renewed then
            releaseClaim(order, "station_reservation_lost", false, true)
            order.status, order.blockedReason = Status.WAITING_FOR_WORKER,
                "STATION_RESERVATION_LOST"
            Repository.MarkDirty(); return
        end
    end
    if order.executionMode ~= mode then
        order.executionMode, order.lastAbstractAt = mode, at
        if mode == "ABSTRACT" then order.status = Status.WORKING end
        order.revision = order.revision + 1
        Repository.MarkDirty()
    end
    if live and order.stationTarget then
        local current = worker.orderSpec
        if not current or current.kind ~= "production_work"
            or tostring(current.workOrderId or "") ~= order.id
        then
            local target = collectionTarget(order, worker, live)
            if requiresCollection(order) and not target
            then
                releaseClaim(order, "stockpile_access_missing", false, true)
                order.status, order.blockedReason = Status.BLOCKED,
                    "NO_STOCKPILE_ACCESS_NODE"
                Repository.MarkDirty()
                return
            end
            order.collectionTarget = target and copy(target) or nil
            setLiveOrder(worker, order, target or order.stationTarget,
                target and "COLLECT_INPUTS"
                    or order.livePhase or "WORK_AT_STATION")
            order.status = target and Status.TRAVEL_TO_STOCKPILE
                or Status.TRAVEL_TO_STATION
        end
    end
    if not live and order.status == Status.WORKING then
        local previous = tonumber(order.lastAbstractAt) or at
        order.lastAbstractAt = at
        Service.Commands.AddElapsed(order.id, worker.id,
            math.max(0, (at - previous) / 1000))
    end
end

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

function Service.Tick(at)
    at = tonumber(at) or now()
    if at < Service.NextPassAt then return 0 end
    Service.NextPassAt = at + Definitions.BALANCE.schedulerCadenceMs
    Repository.Load()
    Service.ReconcileWorkerState()
    for _, reconcile in pairs(Service.ReconcileHandlers) do
        reconcile()
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
    for index = 1, processed do processOrder(Repository.State.byId[ids[index]], at) end
    if at >= Service.NextPruneAt then
        Service.NextPruneAt = at + 60000
        pruneTerminalHistory()
    end
    return processed
end

if Events and Events.OnTick and not Service.TickHookRegistered then
    Events.OnTick.Add(function() Service.Tick() end)
    Service.TickHookRegistered = true
end

return Service
