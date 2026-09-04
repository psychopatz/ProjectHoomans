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
local emit = Internal.emit
local now = Internal.now
local terminal = Internal.terminal
local copy = Internal.copy
local requirementsMet = Internal.requirementsMet
local releaseClaim = Internal.releaseClaim
local setLiveOrder = Internal.setLiveOrder
local workerAvailable = Internal.workerAvailable
local claimStation = Internal.claimStation
local returnHomeAfterWork = Internal.returnHomeAfterWork

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
    order.updatedAt, order.lastProgressAt = now(), now()
    order.recoveryAttempts = nil
    order.lastRecoveryAt = nil
    order.lastRecoveryReason = nil
    order.recoveryQuarantined = nil
    order.revision = order.revision + 1
    setLiveOrder(worker, order, order.stationTarget, "WORK_AT_STATION")
    Repository.MarkDirty()
    return true, copy(order)
end

function Service.Commands.Assign(orderId, workerId)
    local order = Repository.Get(orderId)
    local worker = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(workerId)
    if not order or terminal(order) then return false, "WORK_ORDER_UNAVAILABLE" end
    local available, reason = workerAvailable(worker, order)
    if not available then return false, reason or "NO_QUALIFIED_WORKER" end
    return claimStation(order, worker)
end

local function complete(order)
    if order.completionCommitted == true then return true end
    local worker = order.workerId and PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(order.workerId) or nil
    local handler = Service.CompletionHandlers[order.operation]
    if not handler then
        order.status, order.blockedReason = Status.BLOCKED, "COMPLETION_HANDLER_MISSING"
        Repository.MarkDirty(); return false, order.blockedReason
    end
    order.completionStarted = true
    Repository.MarkDirty()
    local callOk, ok, reason = pcall(handler, order)
    if not callOk then
        order.completionError = tostring(ok)
        ok, reason = false, "COMPLETION_EXCEPTION"
        if PNC.Core and PNC.Core.LogWarn then
            PNC.Core.LogWarn("work completion exception order="
                .. tostring(order.id) .. " error=" .. tostring(order.completionError))
        end
    end
    if ok ~= true then
        if order.cancellationRequested == true then
            releaseClaim(order, order.cancellationReason or "cancelled", true,
                true)
            order.status, order.cancelledAt = Status.CANCELLED, now()
            order.completionStarted, order.blockedReason = nil, nil
            order.terminalPersisted = false
            order.revision = order.revision + 1
            Repository.MarkDirty()
            return true, "CANCELLED_AFTER_ATOMIC_FAILURE"
        end
        order.status, order.blockedReason = Status.BLOCKED,
            tostring(reason or "COMPLETION_FAILED")
        order.completionStarted = nil
        Repository.MarkDirty(); return false, order.blockedReason
    end
    local completedWorker = worker
    order.completionCommitted = true
    order.terminalPersisted = false
    order.status, order.progress = Status.COMPLETED, order.requiredWork
    if order.cancellationRequested == true then
        order.cancellationOutcome = "COMPLETED_DURING_CANCELLATION"
    end
    order.cancellationRequested, order.cancellationReason = nil, nil
    order.completedAt, order.updatedAt = now(), now()
    order.revision = order.revision + 1
    releaseClaim(order, "complete")
    if returnHomeAfterWork then
        returnHomeAfterWork(completedWorker, order)
    end
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
    if order.operation == "CRAFT"
        and PNC.RecipeKnowledge and PNC.RecipeKnowledge.Queries
        and PNC.RecipeKnowledge.Queries.CanCraft
    then
        local researched = PNC.ResearchService and PNC.ResearchService.Queries
            and PNC.ResearchService.Queries.HasRecipe
            and PNC.ResearchService.Queries.HasRecipe(order.colonyId,
                order.recipeId)
        if not researched then
            local known = PNC.RecipeKnowledge.Queries.CanCraft(
                worker, order.recipeId)
            if not known then
                order.status, order.blockedReason = Status.BLOCKED,
                    "RECIPE_BOOK_REQUIRED"
                Repository.MarkDirty()
                return false, order.blockedReason
            end
        end
    end
    local eligible, reason = requirementsMet(worker, order.requiredSkills)
    if not eligible then
        order.status, order.blockedReason = Status.BLOCKED, reason
        Repository.MarkDirty(); return false, reason
    end
    order.status = Status.WORKING
    local before = order.progress
    order.progress = math.min(order.requiredWork,
        order.progress + math.max(0, tonumber(amount) or 0))
    if order.progress > before then
        order.lastProgressAt = now()
        order.recoveryAttempts = nil
        order.lastRecoveryAt = nil
        order.lastRecoveryReason = nil
        order.recoveryQuarantined = nil
    end
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

-- Completes an order whose physical side effect was already applied by its
-- domain adapter. This is deliberately separate from AddProgress: deferred
-- world effects must never call the ordinary completion handler again, since
-- that handler quite reasonably expects a live, loaded world object.
function Service.Commands.CompleteDeferred(orderId, reason)
    local order = Repository.Get(orderId)
    if not order or terminal(order) then
        return false, "WORK_ORDER_UNAVAILABLE"
    end
    if order.status ~= Status.WORLD_EFFECT_PENDING
        or type(order.worldEffect) ~= "table"
        or tostring(order.worldEffect.state or "") ~= "APPLIED"
    then
        return false, "WORLD_EFFECT_NOT_APPLIED"
    end
    local completedWorker = order.workerId and PNC.Registry
        and PNC.Registry.Get and PNC.Registry.Get(order.workerId) or nil
    order.completionCommitted = true
    order.completionStarted = nil
    order.cancellationRequested, order.cancellationReason = nil, nil
    order.terminalPersisted = false
    order.status, order.progress = Status.COMPLETED, order.requiredWork
    order.blockedReason = nil
    order.completedAt, order.updatedAt = now(), now()
    order.completionReason = tostring(reason or "deferred_world_effect")
    order.revision = (tonumber(order.revision) or 0) + 1
    releaseClaim(order, order.completionReason, false, false)
    if returnHomeAfterWork and completedWorker then
        returnHomeAfterWork(completedWorker, order)
    end
    Repository.MarkDirty()
    emit(EventTypes.WORK_ORDER_COMPLETED, { workOrderId = order.id,
        colonyId = order.colonyId, operation = order.operation,
        deferred = true })
    return true, copy(order)
end


return Service
