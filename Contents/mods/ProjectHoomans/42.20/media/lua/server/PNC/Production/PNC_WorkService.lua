if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorkService = PNC.WorkService or {}

local Service = PNC.WorkService
local Repository = PNC.WorkRepository
local Definitions = PNC.WorkDefinitions
local Status = Definitions.STATUS
local EventsBus = PsychopatzCore and PsychopatzCore.Events
local EventTypes = PNC.EventTypes or {}

local function emit(eventType, payload)
    if eventType and EventsBus and EventsBus.emit then
        EventsBus.emit(eventType, payload)
    end
end

Service.CompletionHandlers = Service.CompletionHandlers or {}
Service.PreparationHandlers = Service.PreparationHandlers or {}
Service.CollectionHandlers = Service.CollectionHandlers or {}
Service.TargetProviders = Service.TargetProviders or {}
Service.ClaimsByStation = Service.ClaimsByStation or {}
Service.ClaimsByWorker = Service.ClaimsByWorker or {}
Service.NextPassAt = Service.NextPassAt or 0
Service.NextPruneAt = Service.NextPruneAt or 0
Service.MAX_TERMINAL_HISTORY = 512
Service.Commands = Service.Commands or {}
Service.Queries = Service.Queries or {}

local function now() return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0 end

local function terminal(order)
    return order.status == Status.CANCELLED or order.status == Status.COMPLETED
end

local function copy(value)
    return PNC.Core and PNC.Core.DeepCopy and PNC.Core.DeepCopy(value) or value
end

local function requirementsMet(record, requirements)
    local rate, reason = Definitions.WorkRate(record, requirements, 1, 1)
    return rate > 0, reason, rate
end

local function belongsToOrder(record, order)
    local affiliation = record and record.affiliation or {}
    local factionId = tostring(affiliation.factionID or affiliation.factionId
        or record and record.factionId or "")
    local colonyId = tostring(affiliation.communityID or affiliation.communityId
        or record and record.communityId or "")
    if colonyId == "" and PNC.HomeDutyService
        and PNC.HomeDutyService.GetColonyId
    then
        colonyId = PNC.HomeDutyService.GetColonyId(record)
    end
    return (order.factionId == "" or factionId == order.factionId)
        and (order.colonyId == "" or colonyId == order.colonyId)
end

local function workerAvailable(record, order)
    if not record or record.alive == false or not belongsToOrder(record, order) then
        return false
    end
    if Service.ClaimsByWorker[tostring(record.id)] then return false end
    local runtime = record.runtime
    if runtime and runtime.workOrderId then return false end
    local job = Definitions.JOB_BY_OPERATION[order.operation]
    local allowed = record.allowedJobs
    -- Colony jobs are opt-out. Archetype tables predate colony production and
    -- therefore missing keys must mean allowed, not disabled.
    if type(allowed) == "table" and allowed[job] == false then return false end
    if PNC.HomeDutyService and PNC.HomeDutyService.IsAtHome
        and not PNC.HomeDutyService.IsAtHome(record, order.baseId)
    then
        return false
    end
    return requirementsMet(record, order.requiredSkills)
end

local function findWorker(order)
    local selected
    local away
    if not PNC.Registry then return nil end
    local function consider(record)
        if selected or not record or record.alive == false
            or not belongsToOrder(record, order)
        then
            return
        end
        local job = Definitions.JOB_BY_OPERATION[order.operation]
        local allowed = record.allowedJobs
        local eligible = not Service.ClaimsByWorker[tostring(record.id)]
            and not (record.runtime and record.runtime.workOrderId)
            and not (type(allowed) == "table" and allowed[job] == false)
            and requirementsMet(record, order.requiredSkills)
        if not eligible then return end
        if workerAvailable(record, order) then
            selected = record
        elseif not away then
            away = record
        end
    end
    if PNC.Registry.ForEach then PNC.Registry.ForEach(consider)
    else for _, record in pairs(PNC.Registry.Data or {}) do consider(record) end end
    if not selected and away and PNC.HomeDutyService
        and PNC.HomeDutyService.SendHome
    then
        PNC.HomeDutyService.SendHome(away, order.baseId, "work_waiting")
        return nil, "WORKER_RETURNING_HOME"
    end
    return selected, selected and nil or "NO_QUALIFIED_WORKER"
end

function Service.RegisterCompletion(operation, handler)
    operation = tostring(operation or "")
    if operation == "" or type(handler) ~= "function" then return false end
    Service.CompletionHandlers[operation] = handler
    return true
end

function Service.RegisterPreparation(operation, handler)
    operation = tostring(operation or "")
    if operation == "" or type(handler) ~= "function" then return false end
    Service.PreparationHandlers[operation] = handler
    return true
end

function Service.RegisterCollection(operation, handler)
    operation = tostring(operation or "")
    if operation == "" or type(handler) ~= "function" then return false end
    Service.CollectionHandlers[operation] = handler
    return true
end

function Service.RegisterTargetProvider(operation, handler)
    operation = tostring(operation or "")
    if operation == "" or type(handler) ~= "function" then return false end
    Service.TargetProviders[operation] = handler
    return true
end

function Service.Commands.Queue(spec)
    spec = type(spec) == "table" and spec or {}
    local operation = tostring(spec.operation or "")
    if not Definitions.CAPABILITY_BY_OPERATION[operation]
        and not Service.TargetProviders[operation]
    then
        return nil, "UNKNOWN_OPERATION"
    end
    local order = {
        schemaVersion = Repository.SCHEMA_VERSION,
        id = Repository.NextId(), operation = operation,
        colonyId = tostring(spec.colonyId or ""),
        factionId = tostring(spec.factionId or ""),
        baseId = tostring(spec.baseId or ""),
        recipeId = tonumber(spec.recipeId),
        quantity = math.max(1, math.floor(tonumber(spec.quantity) or 1)),
        requiredWork = math.max(1, tonumber(spec.requiredWork) or 100),
        progress = math.max(0, tonumber(spec.progress) or 0),
        requiredSkills = copy(spec.requiredSkills or {}),
        payload = copy(spec.payload or {}),
        status = Status.QUEUED, priority = tonumber(spec.priority) or 0,
        revision = 0, createdAt = now(), updatedAt = now(),
    }
    Repository.Put(order)
    emit(EventTypes.WORK_ORDER_QUEUED, { workOrderId = order.id,
        colonyId = order.colonyId, operation = order.operation })
    return copy(order)
end

local function releaseClaim(order, reason, cancelInputs)
    if not order then return end
    local input = order.payload and order.payload.input
    if PNC.WorkInputService and input
        and (cancelInputs == true or input.staged == true)
    then
        -- Collected inputs physically live on the current NPC and must return
        -- to the stockpile before a replacement can collect them. An input
        -- that is only reserved can remain attached to the durable order.
        PNC.WorkInputService.Cancel(order)
    end
    if order.stationId and Service.ClaimsByStation[order.stationId] == order.id then
        Service.ClaimsByStation[order.stationId] = nil
    end
    if order.workerId and Service.ClaimsByWorker[order.workerId] == order.id then
        Service.ClaimsByWorker[order.workerId] = nil
    end
    if order.facilityReservationId and PNC.FacilityReservations then
        PNC.FacilityReservations.Release(order.facilityReservationId,
            reason or "work_released")
    end
    local record = order.workerId and PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(order.workerId) or nil
    if record and record.runtime and record.runtime.workOrderId == order.id then
        record.runtime.workOrderId = nil
        record.runtime.lastProductionWorkAt = nil
        if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
            PNC.OrderSystem.SetOrder(record, order.previousOrder)
        end
    end
    order.workerId, order.stationId, order.facilityId = nil, nil, nil
    order.facilityReservationId, order.previousOrder = nil, nil
    order.stationTarget, order.collectionTarget = nil, nil
    order.executionMode, order.lastAbstractAt = nil, nil
end

local function setLiveOrder(worker, order, target, phase)
    if not target then return false end
    PNC.OrderSystem.SetOrder(worker, {
        kind = "production_work", workOrderId = order.id,
        operation = order.operation, phase = phase,
        x = target.x, y = target.y, z = target.z,
        facilityId = order.facilityId, stationId = order.stationId,
        stockpileNodeId = target.nodeId,
    })
    return true
end

local function collectionTarget(order, worker)
    local standardized = PNC.WorkInputService
        and PNC.WorkInputService.RequiresCollection(order)
    if not standardized and not Service.CollectionHandlers[order.operation]
        or not PNC.StockpileAccessService
    then return nil end
    local node = PNC.StockpileAccessService.FindNearest(order.baseId,
        worker.x or 0, worker.y or 0, worker.z or 0)
    if not node then return nil end
    return { x = node.x, y = node.y, z = node.z, nodeId = node.id }
end

local function requiresCollection(order)
    return PNC.WorkInputService
        and PNC.WorkInputService.RequiresCollection(order)
        or Service.CollectionHandlers[order.operation] ~= nil
            and not (order.payload and order.payload.inputsStaged == true)
end

local function acquireWorkTarget(order, worker, live)
    local provider = Service.TargetProviders[order.operation]
    if provider then return provider(order, worker, live) end
    local capability = Definitions.CAPABILITY_BY_OPERATION[order.operation]
    return PNC.FacilityService.AcquireActivity(order.baseId, worker.id,
        capability, { abstract = live == nil, ttlMs = 30000,
            workOrderId = order.id })
end

local function claimStation(order, worker)
    local live = PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(worker.id) or nil
    local acquired = acquireWorkTarget(order, worker, live)
    if not acquired or not acquired.ok then
        return false, acquired and acquired.reason or "NO_AVAILABLE_WORKSTATION"
    end
    local stationId = tostring(acquired.componentId or "")
    if stationId == "" or Service.ClaimsByStation[stationId] then
        if acquired.reservationId and PNC.FacilityReservations then
            PNC.FacilityReservations.Release(acquired.reservationId,
                "station_claim_conflict")
        end
        return false, "NO_AVAILABLE_WORKSTATION"
    end
    local needsCollection = live and requiresCollection(order)
    local collectTarget = needsCollection and collectionTarget(order, worker)
        or nil
    if needsCollection and not collectTarget then
        if acquired.reservationId and PNC.FacilityReservations then
            PNC.FacilityReservations.Release(acquired.reservationId,
                "stockpile_access_missing")
        end
        return false, "NO_STOCKPILE_ACCESS_NODE"
    end
    Service.ClaimsByStation[stationId], Service.ClaimsByWorker[worker.id] = order.id, order.id
    order.workerId, order.stationId = worker.id, stationId
    order.facilityId = acquired.facilityId
    order.facilityReservationId = acquired.reservationId
    order.stationTarget = copy(acquired.target)
    order.executionMode = live and "LIVE" or "ABSTRACT"
    order.collectionTarget = collectTarget and copy(collectTarget) or nil
    order.status = collectTarget and Status.TRAVEL_TO_STOCKPILE
        or live and Status.TRAVEL_TO_STATION or Status.WORKING
    order.blockedReason = nil
    order.updatedAt, order.revision = now(), order.revision + 1
    worker.runtime = worker.runtime or {}
    worker.runtime.workOrderId = order.id
    worker.runtime.lastProductionWorkAt = nil
    order.previousOrder = copy(worker.orderSpec)
    if live and acquired.target then
        setLiveOrder(worker, order, collectTarget or acquired.target,
            collectTarget and "COLLECT_INPUTS" or "WORK_AT_STATION")
    end
    Repository.MarkDirty()
    return true
end

function Service.Commands.CollectInputs(orderId, workerId)
    local order = Repository.Get(orderId)
    if not order or terminal(order) then return false, "WORK_ORDER_UNAVAILABLE" end
    if tostring(order.workerId or "") ~= tostring(workerId or "") then
        return false, "WORKER_NOT_ASSIGNED"
    end
    local worker = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(workerId)
    local ok, reason
    if PNC.WorkInputService
        and PNC.WorkInputService.RequiresCollection(order)
    then
        ok, reason = PNC.WorkInputService.Collect(order, worker)
    else
        local handler = Service.CollectionHandlers[order.operation]
        if not handler then return false, "COLLECTION_HANDLER_MISSING" end
        ok, reason = handler(order, worker)
    end
    if ok ~= true then
        order.status, order.blockedReason = Status.BLOCKED,
            tostring(reason or "INPUT_COLLECTION_FAILED")
        Repository.MarkDirty()
        return false, order.blockedReason
    end
    order.collectionTarget = nil
    order.status, order.blockedReason = Status.TRAVEL_TO_STATION, nil
    order.updatedAt, order.revision = now(), order.revision + 1
    setLiveOrder(worker, order, order.stationTarget, "WORK_AT_STATION")
    Repository.MarkDirty()
    return true, copy(order)
end

function Service.Commands.Assign(orderId, workerId)
    local order = Repository.Get(orderId)
    local worker = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(workerId)
    if not order or terminal(order) then return false, "WORK_ORDER_UNAVAILABLE" end
    if not workerAvailable(worker, order) then return false, "NO_QUALIFIED_WORKER" end
    return claimStation(order, worker)
end

local function complete(order)
    if order.completionCommitted == true then return true end
    local handler = Service.CompletionHandlers[order.operation]
    if not handler then
        order.status, order.blockedReason = Status.BLOCKED, "COMPLETION_HANDLER_MISSING"
        Repository.MarkDirty(); return false, order.blockedReason
    end
    order.completionStarted = true
    Repository.MarkDirty()
    local ok, reason = handler(order)
    if ok ~= true then
        order.status, order.blockedReason = Status.BLOCKED,
            tostring(reason or "COMPLETION_FAILED")
        Repository.MarkDirty(); return false, order.blockedReason
    end
    order.completionCommitted = true
    order.terminalPersisted = false
    order.status, order.progress = Status.COMPLETED, order.requiredWork
    order.completedAt, order.updatedAt = now(), now()
    order.revision = order.revision + 1
    releaseClaim(order, "complete")
    Repository.MarkDirty()
    emit(EventTypes.WORK_ORDER_COMPLETED, { workOrderId = order.id,
        colonyId = order.colonyId, operation = order.operation })
    return true
end

function Service.Commands.AddProgress(orderId, workerId, amount)
    local order = Repository.Get(orderId)
    if not order or terminal(order) then return false, "WORK_ORDER_UNAVAILABLE" end
    if tostring(order.workerId or "") ~= tostring(workerId or "") then
        return false, "WORKER_NOT_ASSIGNED"
    end
    if order.status == Status.PAUSED then return false, "WORK_ORDER_PAUSED" end
    local worker = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(workerId)
    local eligible, reason = requirementsMet(worker, order.requiredSkills)
    if not eligible then
        order.status, order.blockedReason = Status.BLOCKED, reason
        Repository.MarkDirty(); return false, reason
    end
    order.status = Status.WORKING
    order.progress = math.min(order.requiredWork,
        order.progress + math.max(0, tonumber(amount) or 0))
    order.updatedAt, order.revision = now(), order.revision + 1
    Repository.MarkDirty()
    if order.progress >= order.requiredWork then return complete(order) end
    return true, copy(order)
end

function Service.Commands.AddElapsed(orderId, workerId, elapsedSeconds)
    local order = Repository.Get(orderId)
    local worker = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(workerId)
    if not order or not worker then return false, "WORKER_UNAVAILABLE" end
    local rate, reason = Definitions.WorkRate(worker, order.requiredSkills, 1, 1)
    if rate <= 0 then return false, reason end
    local elapsed = math.max(0, math.min(Definitions.BALANCE.maxElapsedSeconds,
        tonumber(elapsedSeconds) or 0))
    return Service.Commands.AddProgress(orderId, workerId, rate * elapsed)
end

function Service.Commands.Cancel(orderId, reason)
    local order = Repository.Get(orderId)
    if not order or terminal(order) then return false, "WORK_ORDER_UNAVAILABLE" end
    local cancellation = Service.CancellationHandlers
        and Service.CancellationHandlers[order.operation]
    if cancellation then cancellation(order) end
    releaseClaim(order, reason or "cancelled", true)
    order.status, order.cancelledAt = Status.CANCELLED, now()
    order.terminalPersisted = false
    order.blockedReason, order.revision = nil, order.revision + 1
    Repository.MarkDirty()
    emit(EventTypes.WORK_ORDER_CANCELLED, { workOrderId = order.id,
        colonyId = order.colonyId, operation = order.operation })
    return true, copy(order)
end

function Service.Commands.ReleaseWorker(workerId, reason)
    workerId = tostring(workerId or "")
    local orderId = Service.ClaimsByWorker[workerId]
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(workerId) or nil
    orderId = orderId or record and record.runtime
        and record.runtime.workOrderId or nil
    local order = orderId and Repository.Get(orderId) or nil
    if not order or terminal(order) then return false, "WORK_ORDER_UNAVAILABLE" end
    releaseClaim(order, reason or "worker_released")
    order.status = Status.WAITING_FOR_WORKER
    order.blockedReason = nil
    order.updatedAt, order.revision = now(), order.revision + 1
    Repository.MarkDirty()
    return true, copy(order)
end

function Service.Commands.Pause(orderId, paused)
    local order = Repository.Get(orderId)
    if not order or terminal(order) then return false, "WORK_ORDER_UNAVAILABLE" end
    order.status = paused == false and Status.WAITING_FOR_WORKER or Status.PAUSED
    if paused ~= false then releaseClaim(order, "paused") end
    order.revision = order.revision + 1; Repository.MarkDirty()
    return true, copy(order)
end

function Service.Commands.SetPriority(orderId, priority)
    local order = Repository.Get(orderId)
    if not order or terminal(order) then return false, "WORK_ORDER_UNAVAILABLE" end
    order.priority = math.max(-100, math.min(100,
        math.floor(tonumber(priority) or 0)))
    order.revision, order.updatedAt = order.revision + 1, now()
    Repository.MarkDirty()
    return true, copy(order)
end

local function authorizedOrder(player, orderId)
    local context, reason = PNC.ProductionContext.ForPlayer(player)
    local order = Repository.Get(orderId)
    if not context then return nil, reason end
    if not order or order.colonyId ~= tostring(context.colony.id)
        or order.factionId ~= tostring(context.faction.id)
    then return nil, "WORK_ORDER_FORBIDDEN" end
    return order
end

function Service.Commands.CancelForPlayer(player, orderId, reason)
    local order, denied = authorizedOrder(player, orderId)
    if not order then return false, denied end
    return Service.Commands.Cancel(order.id, reason)
end

function Service.Commands.PauseForPlayer(player, orderId, paused)
    local order, denied = authorizedOrder(player, orderId)
    if not order then return false, denied end
    return Service.Commands.Pause(order.id, paused)
end


function Service.Commands.SetPriorityForPlayer(player, orderId, priority)
    local order, denied = authorizedOrder(player, orderId)
    if not order then return false, denied end
    return Service.Commands.SetPriority(order.id, priority)
end

function Service.Queries.Get(id) return copy(Repository.Get(id)) end
function Service.Queries.List(colonyId)
    local output = {}
    Repository.Load()
    for _, order in pairs(Repository.State.byId) do
        if not colonyId or order.colonyId == tostring(colonyId) then
            output[#output + 1] = copy(order)
        end
    end
    table.sort(output, function(left, right)
        if left.priority ~= right.priority then return left.priority > right.priority end
        return left.createdAt < right.createdAt
    end)
    return output
end

function Service.Queries.BuildTaskSnapshot(colonyId)
    local output = {}
    for _, order in ipairs(Service.Queries.List(colonyId)) do
        if not terminal(order) then
            local worker = order.workerId and PNC.Registry
                and PNC.Registry.Get and PNC.Registry.Get(order.workerId) or nil
            local payload = order.payload or {}
            local facilityId = order.facilityId or payload.facilityId
            local facility = facilityId and PNC.SettlementRepository
                and PNC.SettlementRepository.GetFacility(facilityId) or nil
            local required = math.max(1, tonumber(order.requiredWork) or 1)
            local progress = math.max(0, math.min(required,
                tonumber(order.progress) or 0))
            output[#output + 1] = {
                id = order.id,
                operation = order.operation,
                status = order.status,
                blockedReason = order.blockedReason,
                progress = progress,
                requiredWork = required,
                percent = math.floor((progress / required) * 100 + 0.5),
                priority = order.priority,
                workerId = order.workerId,
                workerName = worker and tostring(worker.name or worker.id) or nil,
                executionMode = order.executionMode,
                baseId = order.baseId,
                facilityId = facilityId,
                facilityDefinitionId = facility and facility.definitionId or nil,
                stationId = order.stationId,
                recipeId = order.recipeId,
                quantity = order.quantity,
                technologyId = payload.technologyId,
                specimenFullType = payload.specimenFullType,
            }
        end
    end
    return output
end
function Service.Queries.Diagnostics()
    local output = { queuedOrders = 0, activeOrders = 0, blockedOrders = 0,
        stationClaims = {}, workerClaims = {} }
    for _, order in pairs(Repository.State.byId) do
        if order.status == Status.QUEUED or order.status == Status.WAITING_FOR_WORKER then
            output.queuedOrders = output.queuedOrders + 1
        elseif order.status == Status.BLOCKED then
            output.blockedOrders = output.blockedOrders + 1
        elseif not terminal(order) and order.status ~= Status.PAUSED then
            output.activeOrders = output.activeOrders + 1
        end
    end
    for key, value in pairs(Service.ClaimsByStation) do output.stationClaims[key] = value end
    for key, value in pairs(Service.ClaimsByWorker) do output.workerClaims[key] = value end
    return output
end

function Service.BuildActionInformation(record)
    local orderId = record and record.runtime and record.runtime.workOrderId
    local order = orderId and Repository.Get(orderId) or nil
    if not order or terminal(order) then
        if PNC.HomeDutyService
            and PNC.HomeDutyService.IsReturningHome(record)
        then
            local progress = PNC.Travel and PNC.Travel.Service
                and PNC.Travel.Service.GetProgress(record) or nil
            return {
                kind = "return_home",
                state = progress and progress.state or "en_route",
                percent = math.floor(math.max(0, math.min(1,
                    tonumber(progress and progress.percent) or 0)) * 100 + 0.5),
                baseId = record.runtime and record.runtime.homeBaseId or nil,
            }
        end
        if record and record.orderSpec
            and record.orderSpec.kind == "colony_home"
        then
            return { kind = "at_home", baseId = record.orderSpec.baseId }
        end
        return nil
    end
    local required = math.max(1, tonumber(order.requiredWork) or 1)
    local progress = math.max(0, math.min(required,
        tonumber(order.progress) or 0))
    local payload = order.payload or {}
    local facilityId = payload.facilityId
    local facility = facilityId and PNC.SettlementRepository
        and PNC.SettlementRepository.GetFacility(facilityId) or nil
    return {
        kind = "work_order",
        workOrderId = order.id,
        operation = order.operation,
        status = order.status,
        phase = record.orderSpec and record.orderSpec.phase or nil,
        progress = progress,
        requiredWork = required,
        percent = math.floor((progress / required) * 100 + 0.5),
        facilityId = facilityId,
        facilityDefinitionId = facility and facility.definitionId or nil,
        recipeId = order.recipeId,
        quantity = order.quantity,
        technologyId = payload.technologyId,
        specimenFullType = payload.specimenFullType,
    }
end

local function processOrder(order, at)
    if terminal(order) or order.status == Status.PAUSED then return end
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
        releaseClaim(order, "worker_unavailable")
        order.status, order.blockedReason = Status.WAITING_FOR_WORKER,
            "NO_QUALIFIED_WORKER"
        Repository.MarkDirty(); return
    end
    if not worker then
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
    if PNC.HomeDutyService and PNC.HomeDutyService.IsAtHome
        and not PNC.HomeDutyService.IsAtHome(worker, order.baseId)
    then
        releaseClaim(order, "worker_left_home")
        order.status, order.blockedReason = Status.WAITING_FOR_WORKER,
            "WORKER_RETURNING_HOME"
        PNC.HomeDutyService.SendHome(worker, order.baseId, "worker_left_home")
        Repository.MarkDirty()
        return
    end
    local live = PNC.Registry.GetLiveZombie and PNC.Registry.GetLiveZombie(worker.id)
    local mode = live and "LIVE" or "ABSTRACT"
    if order.facilityReservationId and PNC.FacilityReservations then
        local renewed = PNC.FacilityReservations.Start(
            order.facilityReservationId, 30000)
        if not renewed then
            releaseClaim(order, "station_reservation_lost")
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
            local target = collectionTarget(order, worker)
            if requiresCollection(order) and not target
            then
                releaseClaim(order, "stockpile_access_missing")
                order.status, order.blockedReason = Status.BLOCKED,
                    "NO_STOCKPILE_ACCESS_NODE"
                Repository.MarkDirty()
                return
            end
            order.collectionTarget = target and copy(target) or nil
            setLiveOrder(worker, order, target or order.stationTarget,
                target and "COLLECT_INPUTS" or "WORK_AT_STATION")
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
