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
local startsAtHome = Internal.startsAtHome
local returnsHome = Internal.returnsHome
local observeWorkLocation = Internal.observeWorkLocation
local isFollowing = Internal.isFollowing

local function releaseAssignment(order, reason)
    if not order then return false, "WORK_ORDER_UNAVAILABLE" end
    if Service.Commands.ReleaseAssignment then
        local released, releaseReason = Service.Commands.ReleaseAssignment(
            order.workerId, reason)
        if released == true then return true end
        -- If no Tasking lease exists, release the durable work claim directly.
        -- Never hide an active lease cleanup failure.
        if releaseReason ~= "WORK_ORDER_UNAVAILABLE" then
            return false, releaseReason
        end
    end
    return releaseClaim(order, reason, false, true)
end

local function processOrder(order, at)
    if terminal(order) or order.status == Status.PAUSED then return end
    if order.recoveryQuarantined == true then
        local changed = order.status ~= Status.BLOCKED
            or order.blockedReason == nil
        order.status = Status.BLOCKED
        order.blockedReason = order.blockedReason
            or "TASK_RECOVERY_EXHAUSTED"
        if changed then Repository.MarkDirty() end
        return
    end
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
        local released, releaseReason = releaseAssignment(order,
            "worker_unavailable")
        if released == false then
            order.blockedReason = releaseReason or "WORKER_UNAVAILABLE"
            Repository.MarkDirty(); return
        end
        order.status, order.blockedReason = Status.WAITING_FOR_WORKER,
            "NO_QUALIFIED_WORKER"
        Repository.MarkDirty(); return
    end
    if not worker then
        if PNC.Tasking and PNC.Tasking.Providers
            and PNC.Tasking.Providers.work
        then
            if order.status ~= Status.WAITING_FOR_WORKER
                or order.blockedReason ~= nil
            then
                order.status, order.blockedReason = Status.WAITING_FOR_WORKER, nil
                order.updatedAt, order.revision = at, order.revision + 1
                Repository.MarkDirty()
            end
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
    if observeWorkLocation then observeWorkLocation(worker, order, at) end
    local returningHome = PNC.HomeDutyService
        and PNC.HomeDutyService.IsReturningHome
        and PNC.HomeDutyService.IsReturningHome(worker, order.baseId)
    local followingDuringProvision = order.operation == "PROVISION_PICKUP"
        and isFollowing and isFollowing(worker)
    if returningHome or followingDuringProvision
        or (startsAtHome(order) and not Internal.executionIsRemote(order)
        and PNC.HomeDutyService
        and PNC.HomeDutyService.IsAtHome
        and not PNC.HomeDutyService.IsAtHome(worker, order.baseId))
    then
        local released, releaseReason
        if Service.Commands.ReleaseAssignment then
            released, releaseReason = releaseAssignment(order,
                "worker_left_home")
        else
            released, releaseReason = releaseClaim(order,
                "worker_left_home", false, true)
        end
        if released == false then
            Repository.MarkDirty()
            return
        end
        order.status, order.blockedReason = Status.WAITING_FOR_WORKER,
            returnsHome(order) and "WORKER_RETURNING_HOME"
                or "WORKER_NOT_AT_HOME"
        if returnsHome(order) and PNC.HomeDutyService
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
            local released, releaseReason = releaseAssignment(order,
                "station_reservation_lost")
            if released == false then
                order.blockedReason = releaseReason
                Repository.MarkDirty(); return
            end
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
                local released, releaseReason = releaseAssignment(order,
                    "stockpile_access_missing")
                if released == false then
                    order.blockedReason = releaseReason
                    Repository.MarkDirty(); return
                end
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
    if not live and order.status == Status.WORKING
        and not (Definitions.MANUAL_PROGRESS
            and Definitions.MANUAL_PROGRESS[order.operation])
    then
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
