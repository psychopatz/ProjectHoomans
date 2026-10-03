-- Server-authoritative task request mutation commands.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.TaskRequestService = PNC.TaskRequestService or {}

local Service = PNC.TaskRequestService

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

local function revisionMatches(actual, expected)
    if expected == nil then return true end
    return tonumber(actual) ~= nil
        and tonumber(actual) == tonumber(expected)
end

local function workIdentityMatches(order, options)
    if type(options) ~= "table" then return true end
    if options.sourceRef ~= nil
        and tostring(options.sourceRef) ~= tostring(order.id)
    then return false, "TASK_STALE" end
    if options.taskId ~= nil
        and tostring(options.taskId) ~= tostring(order.id)
    then return false, "TASK_STALE" end
    if order.workerId and (options.npcID or options.npcId)
        and tostring(order.workerId) ~= tostring(options.npcID or options.npcId)
    then return false, "TASK_STALE" end
    if not revisionMatches(order.revision, options.expectedRevision) then
        return false, "TASK_STALE"
    end
    return true
end

function Service.Commands.CancelForPlayer(player, requestId, reason, options)
    local order, denied = authorized(player, requestId)
    if not order then return false, denied end
    local matches, mismatch = workIdentityMatches(order, options)
    if not matches then return false, mismatch end
    return PNC.WorkService.Commands.Cancel(order.id, reason)
end

local function playerKey(player)
    if player and type(player.getUsername) == "function" then
        local username = tostring(player:getUsername() or "")
        if username ~= "" then return username end
    end
    if player and type(player.getOnlineID) == "function" then
        return tostring(player:getOnlineID() or "")
    end
    return "local"
end

local function medicalId(requestId)
    requestId = tostring(requestId or "")
    if string.sub(requestId, 1, 8) == "medical:" then
        return requestId
    end
    return nil
end

local function authorizedMedical(player, requestId)
    local id = medicalId(requestId)
    local medical = PNC.MedicalCareService
    local context
    local reason
    local task
    if not id or not medical or not medical.Get then
        return nil, "TASK_REQUEST_NOT_FOUND"
    end
    context, reason = PNC.ProductionContext.ForPlayer(player)
    if not context then return nil, reason end
    task = medical.Get(id)
    if not task or medical.TERMINAL[task.status] then
        return nil, "TASK_REQUEST_NOT_FOUND"
    end
    if task.communityId
        and tostring(task.communityId) ~= tostring(context.colony.id)
    then
        return nil, "TASK_REQUEST_FORBIDDEN"
    end
    if task.factionId
        and tostring(task.factionId) ~= tostring(context.faction.id)
    then
        return nil, "TASK_REQUEST_FORBIDDEN"
    end
    if not task.communityId and not task.factionId
        and not (task.patientKind == "player"
            and tostring(task.patientId) == playerKey(player))
    then
        return nil, "TASK_REQUEST_FORBIDDEN"
    end
    return task
end

local function medicalIdentityMatches(task, options)
    if type(options) ~= "table" then return true end
    if options.sourceRef ~= nil
        and tostring(options.sourceRef) ~= tostring(task.id)
    then return false, "TASK_STALE" end
    if task.actorId and (options.npcID or options.npcId)
        and tostring(task.actorId) ~= tostring(options.npcID or options.npcId)
    then return false, "TASK_STALE" end
    if not revisionMatches(task.revision, options.expectedRevision) then
        return false, "TASK_STALE"
    end
    return true
end

function Service.Commands.CancelMedicalForPlayer(player, requestId, reason,
        options)
    local task, denied = authorizedMedical(player, requestId)
    if not task then return false, denied end
    local matches, mismatch = medicalIdentityMatches(task, options)
    if not matches then return false, mismatch end
    return PNC.MedicalCareService.Cancel(task.id, reason)
end

local function findLease(requestId)
    requestId = tostring(requestId or "")
    for _, lease in pairs(PNC.TaskLeaseService and PNC.TaskLeaseService.ByID
        or {}) do
        if tostring(lease.taskId or "") == requestId
            or tostring(lease.leaseId or "") == requestId
        then return lease end
    end
    return nil
end

local function ownedActivity(player, record, context)
    if not record or not context then return false, "TASK_REQUEST_FORBIDDEN" end
    local affiliation = record.affiliation or {}
    local recordColony = tostring(affiliation.communityID or "")
    if recordColony ~= ""
        and recordColony ~= tostring(context.colony and context.colony.id or "")
    then return false, "TASK_REQUEST_FORBIDDEN" end
    if not PNC.CompanionCommands
        or not PNC.CompanionCommands.IsOwnedByPlayer
        or not PNC.CompanionCommands.IsOwnedByPlayer(record, player)
    then return false, "TASK_REQUEST_FORBIDDEN" end
    return true
end

local function leaseIdentityMatches(lease, options)
    if type(options) ~= "table" then return true end
    if options.npcID or options.npcId then
        if tostring(options.npcID or options.npcId)
            ~= tostring(lease.npcId)
        then return false, "TASK_STALE" end
    end
    if options.taskId ~= nil
        and tostring(options.taskId) ~= tostring(lease.taskId)
    then return false, "TASK_STALE" end
    if options.sourceDomain ~= nil
        and tostring(options.sourceDomain) ~= tostring(lease.sourceDomain)
    then return false, "TASK_STALE" end
    if options.sourceRef ~= nil
        and tostring(options.sourceRef) ~= tostring(lease.sourceRef)
    then return false, "TASK_STALE" end
    if not revisionMatches(lease.revision, options.expectedRevision) then
        return false, "TASK_STALE"
    end
    return true
end

local function reevaluateAfterCancellation(npcId, reason)
    local tasking = PNC.Tasking
    local commands = tasking and tasking.Commands
    if commands and commands.ReevaluateAfterCancellation then
        return commands.ReevaluateAfterCancellation(npcId, reason)
    end
    return false, "TASKING_REEVALUATION_UNAVAILABLE"
end

function Service.Commands.CancelTransientForPlayer(player, requestId, reason,
        options)
    local context, contextReason = PNC.ProductionContext.ForPlayer(player)
    if not context then return false, contextReason end
    local lease = findLease(requestId)
    local record
    if lease then
        if lease.sourceDomain == "work" then
            return false, "TASK_REQUEST_NOT_FOUND"
        end
        record = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(lease.npcId) or nil
        local allowed, denied = ownedActivity(player, record, context)
        if not allowed then return false, denied end
        local matches, mismatch = leaseIdentityMatches(lease, options)
        if not matches then return false, mismatch end
        if PNC.Tasking and PNC.Tasking.Commands
            and PNC.Tasking.Commands.CancelLease
        then
            local cancelled, state = PNC.Tasking.Commands.CancelLease(
                lease.leaseId, reason or "player_cancelled")
            if cancelled and state ~= "CANCELLATION_DEFERRED" then
                reevaluateAfterCancellation(lease.npcId,
                    reason or "player_cancelled")
            end
            return cancelled, state
        end
        return false, "TASKING_UNAVAILABLE"
    end

    requestId = tostring(requestId or "")
    if string.sub(requestId, 1, 9) ~= "activity:" then
        return false, "TASK_REQUEST_NOT_FOUND"
    end
    local npcId = string.sub(requestId, 10)
    if type(options) == "table" and (options.npcID or options.npcId)
        and tostring(options.npcID or options.npcId) ~= npcId
    then return false, "TASK_STALE" end
    record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcId) or nil
    local allowed, denied = ownedActivity(player, record, context)
    if not allowed then return false, denied end
    local activity = record.runtime and record.runtime.facilityActivity or nil
    if not activity then return false, "TASK_REQUEST_NOT_FOUND" end
    local activityLease = findLease(activity.taskLeaseId)
    if activityLease then
        if PNC.Tasking and PNC.Tasking.Commands
            and PNC.Tasking.Commands.CancelLease
        then
            local cancelled, state = PNC.Tasking.Commands.CancelLease(
                activityLease.leaseId, reason or "player_cancelled")
            if cancelled and state ~= "CANCELLATION_DEFERRED" then
                reevaluateAfterCancellation(activityLease.npcId,
                    reason or "player_cancelled")
            end
            return cancelled, state
        end
        return false, "TASKING_UNAVAILABLE"
    end
    if not PNC.FacilityJobs or not PNC.FacilityJobs.Stop then
        return false, "FACILITY_ACTIVITY_UNAVAILABLE"
    end
    return PNC.FacilityJobs.Stop(record, reason or "player_cancelled")
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

return Service
