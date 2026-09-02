if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.CorpseHaulService
local Internal = Service.Internal
local Core = PNC.Core
local Registry = PNC.Registry
local Work = PNC.WorkService
local WorkRepository = PNC.WorkRepository
local Status = PNC.WorkDefinitions and PNC.WorkDefinitions.STATUS or {}

local function findBaseAssignment(base)
    local configuration = Internal.configurationFor(base)
    local destinationRegion = configuration and configuration.destinationRegion
    local facilities = destinationRegion and {} or Internal.stockpileFacilities(base)
    local corpses = Internal.scanBaseCorpses(base)
    for _, candidate in ipairs(corpses) do
        local data = candidate.corpse:getModData()
        local token = candidate.token
        local active = token and (Internal.workOrderForToken(token)
            or Service.Runtime.byToken[token]) or nil
        local stale = data and data.PNC_CorpseHaulTaskId
        if not active and (not stale or not Service.IsLifecycleProtected(stale)) then
            if stale then
                data.PNC_CorpseHaulTaskId = nil
                Internal.transmit(candidate.corpse)
                stale = nil
            end
            if not stale then
                local destinations = destinationRegion and { {} } or facilities
                for _, facility in ipairs(destinations) do
                    local facilityId = facility and facility.id or nil
                    local drop = Internal.findDropPoint(facilityId, candidate.x,
                        candidate.y, candidate.z, destinationRegion)
                    if drop then
                        token = Service.GetCorpseToken(candidate.corpse, true)
                        if not token then return nil end
                        return {
                            haulToken = token,
                            baseId = base.id, facilityId = facilityId,
                            sourceX = candidate.x, sourceY = candidate.y,
                            sourceZ = candidate.z,
                            interactionX = candidate.x,
                            interactionY = candidate.y,
                            interactionZ = candidate.z,
                            dropX = drop.x, dropY = drop.y, dropZ = drop.z,
                            destinationRegion = destinationRegion
                                and (Core.DeepCopy
                                    and Core.DeepCopy(destinationRegion)
                                    or destinationRegion) or nil,
                        }
                    end
                end
            end
        end
    end
    return nil
end

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

local function manualResult(record, ok, reason, order, details)
    if Core and Core.Log then
        local message = "manual_corpse_haul npc="
            .. tostring(record and record.id or "unknown")
            .. " result=" .. tostring(ok == true)
            .. " reason=" .. tostring(reason or "unknown")
        if order and order.id then
            message = message .. " order=" .. tostring(order.id)
        end
        if type(details) == "table" then
            for _, key in ipairs({ "corpses", "eligible", "dispatch",
                "dispatchReason", "assigned", "status", "workerId",
                "leaseId" }) do
                if details[key] ~= nil then
                    message = message .. " " .. key .. "="
                        .. tostring(details[key])
                end
            end
        end
        Core.Log(ok == true and "INFO" or "WARN", message)
    end
    return ok, reason, order
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
                assignment.sourceZ, assignment.haulToken)
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
        local ok, result = tasking.ReevaluateNow({
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
            or tostring(result or (ok and "OK" or "UNKNOWN"))
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
    }
end

local function pruneTerminalCorpseOrders()
    local remove = {}
    if not WorkRepository or not WorkRepository.Load
        or not WorkRepository.Remove
    then return 0 end
    WorkRepository.Load()
    for id, order in pairs(WorkRepository.State.byId or {}) do
        if order and order.operation == "CORPSE_HAUL"
            and Internal.terminalWorkOrder(order)
        then
            remove[#remove + 1] = tostring(id)
        end
    end
    for _, id in ipairs(remove) do
        local order = WorkRepository.State.byId[id]
        if order then
            -- Terminal orders normally pass through WorkService.releaseClaim,
            -- but pruning is also a recovery path. Clear live state while the
            -- order still identifies its worker, then release the persisted
            -- projection so the NPC cannot retain a production_work spec or
            -- native movement ownership.
            Internal.clearWorkRuntime(order, "terminal_corpse_order_pruned")
            if Work and Work.Internal and Work.Internal.releaseClaim then
                Work.Internal.releaseClaim(
                    order,
                    "terminal_corpse_order_pruned",
                    false,
                    false
                )
            end
            WorkRepository.Remove(id)
        end
    end
    return #remove
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
    local currentOrder
    local runtime = record and record.runtime or nil
    local now = Core.Now()
    if not record or record.alive == false then
        return manualResult(record, false, "NPC_UNAVAILABLE")
    end
    if record.health and record.health.state == "incapacitated" then
        return manualResult(record, false, "NPC_INCAPACITATED")
    end
    if runtime and (runtime.attackAction or runtime.target
        or now < (tonumber(runtime.inCombatUntil) or 0))
    then
        return manualResult(record, false, "NPC_BUSY")
    end
    current = currentWorkOrderFor(record)
    if current and current.operation ~= "CORPSE_HAUL" then
        return manualResult(record, false, "NPC_BUSY")
    end
    base = homeBaseForRecord(record)
    if not base then return manualResult(record, false, "BASE_NOT_FOUND") end
    configuration = Internal.configurationFor(base)
    if not PNC.HomeDutyService or not PNC.HomeDutyService.IsAtHome then
        return manualResult(record, false, "HOME_SERVICE_UNAVAILABLE")
    end
    if not PNC.HomeDutyService.IsAtHome(record, base.id) then
        return manualResult(record, false, "NPC_NOT_AT_HOME")
    end
    if not Registry or not Registry.GetLiveZombie
        or not Registry.GetLiveZombie(record.id)
    then
        return manualResult(record, false, "LIVE_WORKER_REQUIRED")
    end
    if current then
        local accepted = markManualOrder(current, record)
        if accepted then
            currentOrder, dispatchDetails = reevaluateManualOrder(record,
                current)
        end
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
        return manualResult(record, accepted,
            accepted and "CORPSE_HAUL_ORDER_FORCED" or acceptedReason,
            accepted and (currentOrder or existing) or nil, dispatchDetails)
    end
    assignment = findBaseAssignment(base)
    if not assignment then
        sourceCorpses, eligibleCorpses = Service.GetSourceCorpseCounts(base)
        return manualResult(record, false, "NO_CORPSE_HAUL_AVAILABLE", nil, {
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
            reason or "CORPSE_HAUL_ORDER_FAILED")
    end
    currentOrder, dispatchDetails = reevaluateManualOrder(record, order)
    return manualResult(record, true, "CORPSE_HAUL_ORDER_FORCED",
        currentOrder or order, dispatchDetails)
end

local function queuePendingOrders()
    local settlements = PNC.SettlementRepository
    local queued = 0
    if not Work or not Work.Commands or not Work.Commands.Queue
        or not settlements or not settlements.Load
    then return queued end
    settlements.Load()
    for _, base in pairs(settlements.State and settlements.State.bases or {}) do
        if Internal.pendingCorpseOrderCount(base.id)
            < Service.MAX_PENDING_CORPSE_ORDERS_PER_BASE
        then
            local assignment = findBaseAssignment(base)
            if assignment then
                local configuration = Internal.configurationFor(base)
                local order = Work.Commands.Queue({
                    operation = "CORPSE_HAUL", colonyId = base.colonyId,
                    factionId = base.factionId, baseId = base.id,
                    quantity = 1, requiredWork = 1, priority = 10,
                    locationPolicy = { start = "HOME", execution = "REMOTE",
                        returnHome = "HOME" },
                    phase = "SOURCE_APPROACH",
                    payload = {
                        haulToken = assignment.haulToken,
                        sourceX = assignment.sourceX,
                        sourceY = assignment.sourceY,
                        sourceZ = assignment.sourceZ,
                        interactionX = assignment.interactionX,
                        interactionY = assignment.interactionY,
                        interactionZ = assignment.interactionZ,
                        dropX = assignment.dropX, dropY = assignment.dropY,
                        dropZ = assignment.dropZ,
                        facilityId = assignment.facilityId,
                        destinationRegion = assignment.destinationRegion,
                        configurationRevision = configuration
                            and configuration.revision or 0,
                    },
                })
                if order then queued = queued + 1 end
            end
        end
    end
    return queued
end

Internal.findBaseAssignment = findBaseAssignment
Internal.pruneTerminalCorpseOrders = pruneTerminalCorpseOrders
Internal.queuePendingOrders = queuePendingOrders

return Service
