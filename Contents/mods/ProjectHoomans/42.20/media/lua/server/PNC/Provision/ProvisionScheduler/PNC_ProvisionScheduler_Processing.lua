if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Scheduler = PNC.ProvisionScheduler
local H = Scheduler.Internal
local Registry = PNC.ProvisionRuleRegistry
local Evaluator = PNC.ProvisionEvaluator
local Metrics = PNC.SupplyMetrics

local function isFollowing(record)
    if PNC.HomeDutyService and PNC.HomeDutyService.IsFollowing then
        return PNC.HomeDutyService.IsFollowing(record) == true
    end
    local order = record and record.orderSpec or nil
    return tostring(order and order.kind or "") == tostring(
        PNC.Const and PNC.Const.ORDER_FOLLOW or "follow")
end

local function setIncomingProjection(record, ruleID, request)
    local provision = record.runtime and record.runtime.provision
    local supply = record.runtime and record.runtime.supply
        and record.runtime.supply.byKind
        and record.runtime.supply.byKind[request.resourceKind]
    local projection = { hunger = 0, thirst = 0 }
    for _, selected in ipairs(supply and supply.selected or {}) do
        local quantity = math.max(0, tonumber(selected.quantity) or 0)
        projection.hunger = projection.hunger
            + (tonumber(selected.hunger) or 0) * quantity
        projection.thirst = projection.thirst
            + (tonumber(selected.thirst) or 0)
                * math.max(1, tonumber(selected.remainingUses) or 1)
                * quantity
    end
    if provision then
        provision.incomingProjection = provision.incomingProjection or {}
        provision.incomingProjection[ruleID] = projection
    end
end

local function clearProvisionState(runtime, ruleID)
    if not runtime then return end
    if runtime.pending then runtime.pending[ruleID] = nil end
    if runtime.incoming then runtime.incoming[ruleID] = nil end
    runtime.incomingProjection = runtime.incomingProjection or {}
    runtime.incomingProjection[ruleID] = nil
end

local function quarantineRule(runtime, ruleID, reason)
    if not runtime then return end
    runtime.quarantined = runtime.quarantined or {}
    runtime.quarantined[ruleID] = true
    runtime.lastRequestResult = reason
end

function H.Process(entry)
    local record = PNC.Registry and PNC.Registry.Get(entry.npcID)
    if not record or record.alive == false then
        return true, nil, { ok = false, reason = "npc_missing" }
    end
    local definition = Registry.Get(entry.ruleID)
    if not definition then
        return true, nil, { ok = false, reason = "unknown_rule" }
    end
    if isFollowing(record) then
        return false, H.WorldHour() + 0.25, {
            ruleId = definition.id, ok = false, attempted = false,
            reason = "provision_blocked_while_following",
        }
    end
    if PNC.HomeDutyService and PNC.HomeDutyService.IsAtHome
        and not PNC.HomeDutyService.IsAtHome(record)
    then
        return false, H.WorldHour() + 0.25, {
            ruleId = definition.id, ok = false, attempted = false,
            reason = "provision_waiting_for_home",
        }
    end
    local existingRuntime = record.runtime
        and record.runtime.provision or nil
    local pending = existingRuntime and existingRuntime.pending
        and existingRuntime.pending[entry.ruleID] or nil
    if pending then
        local work = PNC.WorkService
        local order = work and work.Queries and work.Queries.Get
            and work.Queries.Get(pending.workOrderId) or nil
        local status = order and order.status or nil
        if order and order.recoveryQuarantined == true then
            clearProvisionState(existingRuntime, entry.ruleID)
            quarantineRule(existingRuntime, entry.ruleID,
                "provision_pickup_quarantined")
            return true, nil, {
                ruleId = definition.id, ok = false, attempted = true,
                reason = "provision_pickup_quarantined",
                workOrderId = order.id,
            }
        end
        if order and status ~= "COMPLETED" and status ~= "CANCELLED"
            and status ~= "FAILED"
        then
            return false, H.WorldHour() + 0.25, {
                ruleId = definition.id, ok = false, attempted = true,
                reason = "provision_pickup_in_progress",
            }
        end
        clearProvisionState(existingRuntime, entry.ruleID)
    end
    local runtime = record.runtime and record.runtime.provision
    if runtime then runtime.dirtyRules[entry.ruleID] = nil end
    Metrics.Increment("provisionEvaluations")
    local evaluation, evaluationReason = Evaluator.Evaluate(record, definition)
    if not evaluation then
        return true, nil, {
            ruleId = definition.id, ok = false,
            reason = evaluationReason or "evaluation_failed",
        }
    end
    if evaluation.satisfied then
        if runtime then
            runtime.quarantined = runtime.quarantined or {}
            runtime.quarantined[entry.ruleID] = nil
        end
        return true, nil, {
            ruleId = definition.id, ok = true, attempted = false,
            reason = "satisfied", onHand = evaluation.onHand,
        }
    end
    if runtime and runtime.quarantined
        and runtime.quarantined[entry.ruleID] == true
    then
        runtime.lastRequestResult = "provision_pickup_quarantined"
        return true, nil, {
            ruleId = definition.id, ok = false, attempted = false,
            reason = "provision_pickup_quarantined", onHand = evaluation.onHand,
        }
    end
    if evaluation.incoming > 0 then
        Metrics.Increment("provisionRequestsSuppressedByIncoming")
        return false, H.WorldHour() + 0.02, {
            ruleId = definition.id, ok = false, attempted = false,
            reason = "incoming", onHand = evaluation.onHand,
        }
    end
    local request = Evaluator.BuildRequest(record, definition, evaluation)
    if not request then
        return true, nil, {
            ruleId = definition.id, ok = false, attempted = false,
            reason = "request_not_built", onHand = evaluation.onHand,
        }
    end
    runtime = record.runtime.provision
    runtime.incomingProjection = runtime.incomingProjection or {}
    runtime.incoming[entry.ruleID] = evaluation.deficit
    runtime.lastRequest = PNC.Core.DeepCopy(request)
    Metrics.Increment("provisionRequestsCreated")
    local ok, reason, details = PNC.NPCSupplyService.Process(request, {
        acquireOnly = true,
        ignorePersonal = true,
        force = true,
    })
    if reason == "provision_pickup_queued" then
        setIncomingProjection(record, entry.ruleID, request)
        runtime.pending = runtime.pending or {}
        runtime.quarantined = runtime.quarantined or {}
        runtime.quarantined[entry.ruleID] = nil
        runtime.pending[entry.ruleID] = {
            workOrderId = details and details.workOrderId or nil,
        }
        runtime.lastRequestResult = reason
        return false, H.WorldHour() + 0.25, {
            ruleId = definition.id, ok = false, attempted = true,
            reason = reason, onHand = evaluation.onHand,
            workOrderId = details and details.workOrderId or nil,
        }
    end
    runtime.incoming[entry.ruleID] = nil
    runtime.incomingProjection[entry.ruleID] = nil
    if ok then
        runtime.quarantined = runtime.quarantined or {}
        runtime.quarantined[entry.ruleID] = nil
    end
    runtime.lastRequestResult = reason
    if ok then
        Metrics.Increment("provisionRequestsSucceeded")
        return false, H.WorldHour(), {
            ruleId = definition.id, ok = true, attempted = true,
            reason = reason or "acquired", onHand = evaluation.onHand,
        }
    end
    Metrics.Increment("provisionRequestsFailed")
    if reason == "no_supply" then
        Metrics.Increment("provisionStorageShortages")
    end
    local supply = record.runtime and record.runtime.supply
    local lane = supply and supply.byKind
        and supply.byKind[request.resourceKind] or nil
    return false, lane and lane.nextRetry or (H.WorldHour() + 0.25), {
        ruleId = definition.id, ok = false, attempted = true,
        reason = reason or "acquisition_failed", onHand = evaluation.onHand,
    }
end

function H.RemoveQueuedRule(npcID, ruleID)
    local entryKey = H.Key(npcID, ruleID)
    Scheduler.Queued[entryKey] = nil
    for index = #Scheduler.Queue, 1, -1 do
        local entry = Scheduler.Queue[index]
        if H.Key(entry.npcID, entry.ruleID) == entryKey then
            table.remove(Scheduler.Queue, index)
        end
    end
end

function Scheduler.ReconcileRecord(recordOrID)
    local npcID = tostring(type(recordOrID) == "table"
        and recordOrID.id or recordOrID or "")
    local record = PNC.Registry and PNC.Registry.Get(npcID) or nil
    if not record or record.alive == false then return 0, {} end
    local processed = 0
    local results = {}
    for _, definition in ipairs(Registry.List()) do
        H.RemoveQueuedRule(npcID, definition.id)
        local complete, readyAt, result = H.Process({
            npcID = npcID, ruleID = definition.id, readyAt = 0,
        })
        results[#results + 1] = result or {
            ruleId = definition.id, ok = false, reason = "unknown",
        }
        processed = processed + 1
        if not complete then
            Scheduler.MarkDirty(npcID, definition.id, readyAt)
        end
    end
    H.SyncQueueMetric()
    return processed, results
end

function Scheduler.RequestManual(recordOrID)
    local record = type(recordOrID) == "table" and recordOrID
        or PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(tostring(recordOrID or "")) or nil
    if not record or record.alive == false then
        return false, "npc_missing", {}
    end
    for _, kind in ipairs({ "FOOD", "HYDRATION", "MEDICAL" }) do
        if PNC.NPCSupplyService and PNC.NPCSupplyService.ClearRetry then
            PNC.NPCSupplyService.ClearRetry(record, kind)
        end
    end
    local provision = record.runtime and record.runtime.provision
    if provision then provision.quarantined = {} end
    local _, results = Scheduler.ReconcileRecord(record)
    local failed = false
    local attempted = false
    for _, result in ipairs(results or {}) do
        local reason = tostring(result.reason or "")
        local deferred = reason == "provision_pickup_queued"
            or reason == "provision_pickup_in_progress"
            or reason == "incoming"
        attempted = result.attempted == true or attempted
        if result.ok ~= true and not deferred then failed = true end
    end
    local reason = failed and "provision_grab_failed"
        or attempted and "provision_grabbed"
        or "provision_already_satisfied"
    return not failed, reason, results
end
