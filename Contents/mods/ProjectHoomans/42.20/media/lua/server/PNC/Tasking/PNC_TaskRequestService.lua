if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.TaskRequestService = PNC.TaskRequestService or {}

local Service = PNC.TaskRequestService
local Definitions = PNC.TaskRequestDefinitions
Service.Commands = Service.Commands or {}
Service.Queries = Service.Queries or {}

local function workId(requestId)
    requestId = tostring(requestId or "")
    if string.sub(requestId, 1, 5) == "work:" then return requestId end
    return nil
end

local function authorized(player, requestId)
    local id = workId(requestId)
    if not id then return nil, "TASK_REQUEST_NOT_FOUND" end
    local context, reason = PNC.ProductionContext.ForPlayer(player)
    local order = PNC.WorkService.Queries.Get(id)
    if not context then return nil, reason end
    if not order or order.colonyId ~= tostring(context.colony.id)
        or order.factionId ~= tostring(context.faction.id)
    then return nil, "TASK_REQUEST_FORBIDDEN" end
    return order
end

function Service.Commands.CancelForPlayer(player, requestId, reason)
    local order, denied = authorized(player, requestId)
    if not order then return false, denied end
    return PNC.WorkService.Commands.Cancel(order.id, reason)
end

function Service.Commands.PauseForPlayer(player, requestId, paused)
    local order, denied = authorized(player, requestId)
    if not order then return false, denied end
    return PNC.WorkService.Commands.Pause(order.id, paused)
end

function Service.Commands.ResumeForPlayer(player, requestId)
    local order, denied = authorized(player, requestId)
    if not order then return false, denied end
    return PNC.WorkService.Commands.Resume(order.id)
end

function Service.Commands.RetryForPlayer(player, requestId)
    local order, denied = authorized(player, requestId)
    if not order then return false, denied end
    if order.status ~= PNC.WorkDefinitions.STATUS.BLOCKED
        and order.status ~= PNC.WorkDefinitions.STATUS.WAITING_RESOURCE
        and order.status ~= PNC.WorkDefinitions.STATUS.FAILED
    then return false, "TASK_REQUEST_NOT_RETRYABLE" end
    return PNC.WorkService.Commands.Resume(order.id)
end

function Service.Queries.BuildSnapshot(colonyId, at)
    at = tonumber(at) or (PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0)
    local output = {}
    for _, task in ipairs(PNC.WorkService.Queries.BuildTaskSnapshot(colonyId)) do
        task.requestId = task.id
        task.sourceDomain = "production"
        task.lifecycleState = Definitions.FromWorkStatus(task.status)
        task.currentPhase = task.phase or task.lifecycleState
        task.blocker = task.blockedReason
        task.ageMs = math.max(0, at - (tonumber(task.createdAt) or at))
        task.lastProgressAt = tonumber(task.lastProgressAt)
        task.stalled = task.lastProgressAt ~= nil
            and not Definitions.IsTerminal(task.lifecycleState)
            and task.lifecycleState ~= Definitions.STATE.QUEUED
            and task.lifecycleState ~= Definitions.STATE.WAITING_WORKER
            and task.lifecycleState ~= Definitions.STATE.BLOCKED
            and task.lifecycleState ~= Definitions.STATE.WAITING_RESOURCE
            and task.lifecycleState ~= Definitions.STATE.PAUSED
            and task.lifecycleState ~= Definitions.STATE.CANCELLING
            and at - task.lastProgressAt >= 60000
        task.durable = true
        task.cancellable = task.lifecycleState ~= Definitions.STATE.CANCELLING
        output[#output + 1] = task
    end
    for _, lease in pairs(PNC.TaskLeaseService and PNC.TaskLeaseService.ByID or {}) do
        if lease.sourceDomain ~= "work" then
            local record = PNC.Registry and PNC.Registry.Get
                and PNC.Registry.Get(lease.npcId) or nil
            local affiliation = record and record.affiliation or {}
            local recordColony = tostring(affiliation.communityID or "")
            if not colonyId or recordColony == tostring(colonyId) then
                local state = lease.phase == "TRAVEL" and Definitions.STATE.TRAVEL
                    or lease.phase == "WORKING" and Definitions.STATE.WORKING
                    or lease.phase == "CANCELLING"
                        and Definitions.STATE.CANCELLING
                    or Definitions.STATE.CLAIMED
                output[#output + 1] = {
                    id = lease.taskId, requestId = lease.taskId,
                    sourceDomain = lease.sourceDomain, operation = lease.kind,
                    status = state, lifecycleState = state,
                    currentPhase = lease.phase, workerId = lease.npcId,
                    workerName = record and tostring(record.name or record.id),
                    createdAt = lease.startedAt, lastProgressAt = lease.lastProgressAt,
                    ageMs = math.max(0, at - (tonumber(lease.startedAt) or at)),
                    facilityId = lease.facilityId, stationId = lease.facilitySlotId,
                    progress = 0, requiredWork = 1, percent = 0,
                    durable = false, cancellable = false,
                }
            end
        end
    end
    table.sort(output, function(a, b)
        local first = tonumber(a.createdAt) or math.huge
        local second = tonumber(b.createdAt) or math.huge
        if first ~= second then return first < second end
        return tostring(a.requestId) < tostring(b.requestId)
    end)
    return output
end

return Service
