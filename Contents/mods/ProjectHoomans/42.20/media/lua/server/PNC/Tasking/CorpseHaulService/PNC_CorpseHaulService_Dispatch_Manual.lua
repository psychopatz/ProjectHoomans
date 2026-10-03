-- Corpse haul manual request dispatch.
--
-- This provider owns request validation, manual-order selection, immediate
-- reevaluation, and bounded request diagnostics.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.CorpseHaulService
local Internal = Service.Internal
local Core = PNC.Core
local Registry = PNC.Registry
local Work = PNC.WorkService
local WorkRepository = PNC.WorkRepository
local Status = PNC.WorkDefinitions and PNC.WorkDefinitions.STATUS or {}
local findBaseAssignment = Internal.findBaseAssignment

local function homeBaseForRecord(record)
    local home = PNC.HomeDutyService
    local affiliation = record and record.affiliation or {}
    local colonyId = tostring(affiliation.communityID or "")
    if home and home.GetBase then
        local base = home.GetBase(record)
        if base then return base end
    end
    if colonyId ~= "" and PNC.BaseService
        and PNC.BaseService.GetForColony
    then
        local base = PNC.BaseService.GetForColony(colonyId)
        if base then return base end
    end
    return nil
end

local function currentWorkOrderFor(record)
    local runtime = record and record.runtime or nil
    local orderId = runtime and runtime.workOrderId or nil
    local order = orderId and WorkRepository and WorkRepository.Get(orderId)
        or nil
    return order and not Internal.terminalWorkOrder(order) and order or nil
end

local function markManualOrder(order, record)
    if not order or not record then return false, "CORPSE_HAUL_ORDER_INVALID" end
    if order.workerId and tostring(order.workerId) ~= tostring(record.id) then
        return false, "CORPSE_HAUL_ALREADY_ASSIGNED"
    end
    if order.requiredWorkerId
        and tostring(order.requiredWorkerId) ~= tostring(record.id)
    then
        return false, "CORPSE_HAUL_ALREADY_ASSIGNED"
    end
    order.requiredWorkerId = tostring(record.id)
    order.priority = 100
    order.manual = true
    if order.status == Status.PAUSED then
        order.status = Status.WAITING_FOR_WORKER
    end
    order.blockedReason = nil
    order.updatedAt = Core.Now()
    order.revision = (tonumber(order.revision) or 0) + 1
    if WorkRepository and WorkRepository.MarkDirty then
        WorkRepository.MarkDirty()
    end
    if Work and Work.Internal and Work.Internal.markAssignmentDirty then
        Work.Internal.markAssignmentDirty(order,
            "MANUAL_CORPSE_HAUL_REQUESTED")
    end
    return true, order
end

local function manualDiagnostic(record, ok, reason, order, details)
    local runtime = record and record.runtime or nil
    local current = order
    local now = Core.Now()
    local revision = tonumber(runtime and runtime.corpseHaulManualRevision)
        or 0
    local diagnostic = {
        revision = revision + 1,
        at = now,
        result = ok == true,
        reason = tostring(reason or "unknown"),
        orderId = current and current.id or nil,
        orderStatus = current and current.status or nil,
        orderPhase = current and (current.phase or current.livePhase) or nil,
        workerId = current and current.workerId or nil,
        x = tonumber(record and record.x),
        y = tonumber(record and record.y),
        z = tonumber(record and record.z),
        runtimeWorkOrderId = runtime and runtime.workOrderId or nil,
        activeBehavior = record and record.activeBehavior or nil,
        details = type(details) == "table"
            and (Core.DeepCopy and Core.DeepCopy(details) or details) or nil,
    }
    if record then
        record.runtime = runtime or {}
        record.runtime.corpseHaulManualRevision = diagnostic.revision
        record.runtime.corpseHaulManualDiagnostic = diagnostic
        if PNC.Registry and PNC.Registry.MarkDirty then
            PNC.Registry.MarkDirty(record, "corpse_haul_manual")
        end
        if ok ~= true and PNC.Network and PNC.Network.BroadcastRecord then
            PNC.Network.BroadcastRecord(record, "manual_corpse_haul_result")
        end
    end
    return diagnostic
end

local function manualResult(record, ok, reason, order, details)
    local diagnostic = manualDiagnostic(record, ok, reason, order, details)
    if Core and Core.Log then
        local message = "manual_corpse_haul npc="
            .. tostring(record and record.id or "unknown")
            .. " result=" .. tostring(ok == true)
            .. " reason=" .. tostring(reason or "unknown")
            .. " at=" .. tostring(diagnostic.at)
            .. " pos=" .. tostring(diagnostic.x or "?") .. ","
            .. tostring(diagnostic.y or "?") .. ","
            .. tostring(diagnostic.z or "?")
        if order and order.id then
            message = message .. " order=" .. tostring(order.id)
        end
        if type(details) == "table" then
            for _, key in ipairs({ "corpses", "eligible", "dispatch",
                "dispatchReason", "assigned", "status", "workerId",
                "leaseId", "stage", "baseId", "atHome",
                "assignmentReason", "hasTarget", "attackAction",
                "currentOperation", "currentStatus", "currentPhase" }) do
                if details[key] ~= nil then
                    message = message .. " " .. key .. "="
                        .. tostring(details[key])
                end
            end
        end
        Core.Log(ok == true and "INFO" or "WARN", message)
    end
    return ok, reason, order, diagnostic
end

local function findManualOrder(base, record)
    if not WorkRepository or not WorkRepository.Load then return nil end
    WorkRepository.Load()
    local orders = {}
    for _, order in pairs(WorkRepository.State.byId or {}) do
        local assignment = Internal.assignmentForWorkOrder(order)
        local status = order and order.status
        local eligibleStatus = status == Status.QUEUED
            or status == Status.WAITING_FOR_WORKER
            or status == Status.PAUSED
        if order and order.operation == "CORPSE_HAUL"
            and tostring(order.baseId or "") == tostring(base.id or "")
            and eligibleStatus and assignment
            and (not order.workerId
                or tostring(order.workerId) == tostring(record.id))
            and (not order.requiredWorkerId
                or tostring(order.requiredWorkerId) == tostring(record.id))
            and Service.GetCorpseAt(assignment.sourceX, assignment.sourceY,
                assignment.sourceZ, assignment.haulToken,
                assignment.deathMarkerId)
        then
            orders[#orders + 1] = order
        end
    end
    table.sort(orders, function(left, right)
        local leftCreated = tonumber(left.createdAt) or 0
        local rightCreated = tonumber(right.createdAt) or 0
        if leftCreated ~= rightCreated then return leftCreated < rightCreated end
        return tostring(left.id or "") < tostring(right.id or "")
    end)
    return orders[1]
end

local function currentOrderSnapshot(order)
    if not order or not order.id then return order end
    if WorkRepository and WorkRepository.Load then WorkRepository.Load() end
    if WorkRepository and WorkRepository.Get then
        return WorkRepository.Get(order.id) or order
    end
    return order
end

local function requeueManualOrder(order, record)
    if not order or Internal.terminalWorkOrder(order) then return false end
    local tasking = PNC.Tasking
    if record and tasking and tasking.Events and tasking.Events.Emit then
        tasking.Events.Emit("WORK_REQUEST_CHANGED", {
            npcId = tostring(record.id), source = "CorpseHaulService",
            entityId = order.id, cause = "manual_corpse_haul_retry",
        })
        return true
    end
    if Work and Work.Internal and Work.Internal.markAssignmentDirty then
        Work.Internal.markAssignmentDirty(order,
            "MANUAL_CORPSE_HAUL_RETRY")
        return true
    end
    return false
end

local function reevaluateManualOrder(record, order)
    local tasking = PNC.Tasking and PNC.Tasking.Commands
    if tasking and tasking.ReevaluateNow then
        local ok, result, reevaluateReason = tasking.ReevaluateNow({
            npcId = tostring(record.id), source = "CorpseHaulService",
            cause = "manual_corpse_haul_requested",
        })
        local current = currentOrderSnapshot(order)
        local lease = PNC.TaskLeaseService
            and PNC.TaskLeaseService.ForNPC
            and PNC.TaskLeaseService.ForNPC(record.id) or nil
        local assigned = current and current.workerId
            and tostring(current.workerId) == tostring(record.id)
        if not assigned then
            requeueManualOrder(current, record)
        end
        local dispatchReason = type(result) == "table" and "ASSIGNED"
            or tostring(reevaluateReason or result
                or (ok and "OK" or "UNKNOWN"))
        return current, {
            dispatch = ok == true,
            dispatchReason = dispatchReason,
            assigned = assigned == true,
            status = current and current.status or nil,
            workerId = current and current.workerId or nil,
            leaseId = lease and lease.leaseId or nil,
        }
    end
    return currentOrderSnapshot(order), {
        dispatch = false,
        dispatchReason = "TASKING_UNAVAILABLE",
        assigned = false,
    }
end


function Service.RequestManual(record)
    local base
    local configuration
    local current
    local existing
    local assignment
    local order
    local reason
    local sourceCorpses
    local eligibleCorpses
    local dispatchDetails
    local assignmentReason
    local currentOrder
    local runtime = record and record.runtime or nil
    local now = Core.Now()
    if not record or record.alive == false then
        return manualResult(record, false, "NPC_UNAVAILABLE", nil, {
            stage = "validate",
        })
    end
    if record.health and record.health.state == "incapacitated" then
        return manualResult(record, false, "NPC_INCAPACITATED", nil, {
            stage = "validate",
        })
    end
    if runtime and (runtime.attackAction or runtime.target
        or now < (tonumber(runtime.inCombatUntil) or 0))
    then
        return manualResult(record, false, "NPC_BUSY", nil, {
            stage = "validate",
            hasTarget = runtime.target ~= nil,
            attackAction = runtime.attackAction ~= nil,
        })
    end
    if Internal.reconcileActiveOrders then
        Internal.reconcileActiveOrders(now, true)
    end
    current = currentWorkOrderFor(record)
    if current and current.operation ~= "CORPSE_HAUL" then
        return manualResult(record, false, "NPC_BUSY", current, {
            stage = "validate",
            currentOperation = current.operation,
            currentStatus = current.status,
            currentPhase = current.phase,
        })
    end
    base = homeBaseForRecord(record)
    if not base then
        return manualResult(record, false, "BASE_NOT_FOUND", nil, {
            stage = "authorize",
        })
    end
    configuration = Internal.configurationFor(base)
    if not PNC.HomeDutyService or not PNC.HomeDutyService.IsAtHome then
        return manualResult(record, false, "HOME_SERVICE_UNAVAILABLE", nil, {
            stage = "authorize", baseId = base.id,
        })
    end
    local atHome = PNC.HomeDutyService.IsAtHome(record, base.id)
    if not atHome then
        return manualResult(record, false, "NPC_NOT_AT_HOME", nil, {
            stage = "authorize", baseId = base.id, atHome = false,
        })
    end
    if not Registry or not Registry.GetLiveZombie
        or not Registry.GetLiveZombie(record.id)
    then
        return manualResult(record, false, "LIVE_WORKER_REQUIRED", nil, {
            stage = "authorize", baseId = base.id, atHome = true,
        })
    end
    if current then
        local accepted = markManualOrder(current, record)
        if accepted then
            currentOrder, dispatchDetails = reevaluateManualOrder(record,
                current)
        end
        dispatchDetails = dispatchDetails or {}
        dispatchDetails.stage = "dispatch"
        dispatchDetails.baseId = base.id
        dispatchDetails.atHome = true
        return manualResult(record, accepted,
            accepted and "CORPSE_HAUL_ORDER_FORCED"
                or "CORPSE_HAUL_ORDER_INVALID", accepted
                and (currentOrder or current) or nil, dispatchDetails)
    end
    existing = findManualOrder(base, record)
    if existing then
        local accepted, acceptedReason = markManualOrder(existing, record)
        if accepted then
            currentOrder, dispatchDetails = reevaluateManualOrder(record,
                existing)
        end
        dispatchDetails = dispatchDetails or {}
        dispatchDetails.stage = "dispatch"
        dispatchDetails.baseId = base.id
        dispatchDetails.atHome = true
        return manualResult(record, accepted,
            accepted and "CORPSE_HAUL_ORDER_FORCED" or acceptedReason,
            accepted and (currentOrder or existing) or nil, dispatchDetails)
    end
    assignment, assignmentReason = findBaseAssignment(base)
    if not assignment then
        sourceCorpses, eligibleCorpses = Service.GetSourceCorpseCounts(base)
        return manualResult(record, false, "NO_CORPSE_HAUL_AVAILABLE", nil, {
            stage = "dispatch", baseId = base.id, atHome = true,
            assignmentReason = assignmentReason,
            corpses = sourceCorpses, eligible = eligibleCorpses,
        })
    end
    order, reason = Work.Commands.Queue({
        operation = "CORPSE_HAUL", colonyId = base.colonyId,
        factionId = base.factionId, baseId = base.id,
        quantity = 1, requiredWork = 1, priority = 100,
        requiredWorkerId = record.id, manual = true,
        locationPolicy = { start = "HOME", execution = "REMOTE",
            returnHome = "HOME" },
        phase = "SOURCE_APPROACH",
        payload = {
            haulToken = assignment.haulToken,
            deathMarkerId = assignment.deathMarkerId,
            sourceX = assignment.sourceX, sourceY = assignment.sourceY,
            sourceZ = assignment.sourceZ,
            interactionX = assignment.interactionX,
            interactionY = assignment.interactionY,
            interactionZ = assignment.interactionZ,
            dropX = assignment.dropX, dropY = assignment.dropY,
            dropZ = assignment.dropZ,
            facilityId = assignment.facilityId,
            destinationRegion = assignment.destinationRegion,
            configurationRevision = configuration and configuration.revision or 0,
        },
    })
    if not order then
        return manualResult(record, false,
            reason or "CORPSE_HAUL_ORDER_FAILED", nil, {
                stage = "queue", baseId = base.id, atHome = true,
                assignmentReason = assignmentReason,
            })
    end
    currentOrder, dispatchDetails = reevaluateManualOrder(record, order)
    dispatchDetails = dispatchDetails or {}
    dispatchDetails.stage = "dispatch"
    dispatchDetails.baseId = base.id
    dispatchDetails.atHome = true
    return manualResult(record, true, "CORPSE_HAUL_ORDER_FORCED",
        currentOrder or order, dispatchDetails)
end

return Service
