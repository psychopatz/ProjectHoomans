if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.TaskRequestService = PNC.TaskRequestService or {}

local Service = PNC.TaskRequestService
local Definitions = PNC.TaskRequestDefinitions
Service.Commands = Service.Commands or {}
Service.Queries = Service.Queries or {}

local function activityFacilityDefinitionId(activity)
    local repository = PNC.SettlementRepository
    local facility = activity and activity.facilityId and repository
        and repository.GetFacility and repository.GetFacility(activity.facilityId)
        or nil
    return facility and facility.definitionId or nil
end

local MEDICAL_LIFECYCLE = {
    QUEUED = "QUEUED",
    WAITING_FOR_DOCTOR = "WAITING_WORKER",
    WAITING_FOR_SUPPLY = "WAITING_RESOURCE",
    CLAIMED = "CLAIMED",
    TRAVELING = "TRAVEL",
    AT_PATIENT = "WORKING",
    TREATING = "WORKING",
    COMPLETED = "COMPLETED",
    CANCELLED = "CANCELLED",
    FAILED = "FAILED",
    QUARANTINED = "FAILED",
}

local function taskGroup(sourceDomain, operation)
    sourceDomain = tostring(sourceDomain or "")
    operation = tostring(operation or "")
    if sourceDomain == "medical" then return "medical" end
    if sourceDomain == "NeedFacility" then return "needs" end
    if operation == "CORPSE_HAUL" then return "cleanup" end
    if operation == "PROVISION_PICKUP" then return "provision" end
    if sourceDomain == "fishing" or sourceDomain == "lumber"
        or sourceDomain == "farming" or sourceDomain == "scavenge"
    then
        return "zone"
    end
    return "production"
end

local function medicalLifecycleState(status)
    return MEDICAL_LIFECYCLE[tostring(status or "")] or "BLOCKED"
end

local function medicalWorker(task)
    local actorId = task and task.actorId
    return actorId and PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(actorId) or nil
end

local function medicalTaskSnapshot(task, at)
    local patient = task.patientKind == "npc" and PNC.Registry
        and PNC.Registry.Get and PNC.Registry.Get(task.patientId) or nil
    local worker = medicalWorker(task)
    local woundParts = task.woundParts or {}
    local woundCount = #woundParts
    local woundIndex = math.max(1, tonumber(task.currentWoundIndex) or 1)
    local completedWounds = math.max(0, math.min(woundCount, woundIndex - 1))
    local state = medicalLifecycleState(task.status)
    local lastProgressAt = tonumber(task.lastProgressAt)
    return {
        id = task.id,
        requestId = task.id,
        sourceDomain = "medical",
        taskGroup = "medical",
        operation = task.operation,
        status = task.status,
        lifecycleState = state,
        currentPhase = task.phase or task.status,
        workerId = task.actorId,
        actorId = task.actorId,
        workerName = worker and tostring(worker.name or worker.id) or nil,
        patientKind = task.patientKind,
        patientId = task.patientId,
        patientName = patient and tostring(patient.name or patient.id)
            or tostring(task.patientId or task.patientKind or "patient"),
        woundPart = woundParts[woundIndex],
        woundCount = woundCount,
        completedWounds = completedWounds,
        severity = task.severity,
        priority = task.priority,
        source = task.source,
        sourceRef = task.sourceRef,
        communityId = task.communityId,
        factionId = task.factionId,
        blockedReason = task.blockedReason,
        blocker = task.blockedReason,
        failureReason = task.failureReason,
        createdAt = task.createdAt,
        updatedAt = task.updatedAt,
        lastProgressAt = lastProgressAt,
        retryAt = task.retryAt,
        retryCount = task.retryCount,
        revision = task.revision,
        ageMs = math.max(0, at - (tonumber(task.createdAt) or at)),
        percent = woundCount > 0
            and math.floor((completedWounds / woundCount) * 100 + 0.5)
            or 0,
        progress = completedWounds,
        requiredWork = math.max(1, woundCount),
        stalled = lastProgressAt ~= nil
            and not Definitions.IsTerminal(state)
            and state ~= Definitions.STATE.QUEUED
            and state ~= Definitions.STATE.WAITING_WORKER
            and state ~= Definitions.STATE.WAITING_RESOURCE
            and state ~= Definitions.STATE.BLOCKED
            and state ~= Definitions.STATE.CANCELLING
            and at - lastProgressAt >= 60000,
        durable = true,
        cancellable = (PNC.MedicalCareService.TERMINAL or {})
            [task.status] ~= true,
        cancelAction = "cancel_medical",
        cancelRequestId = task.id,
    }
end

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

function Service.Queries.BuildSnapshot(colonyId, at)
    at = tonumber(at) or (PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0)
    local output = {}
    for _, task in ipairs(PNC.WorkService.Queries.BuildTaskSnapshot(colonyId)) do
        task.requestId = task.id
        task.sourceDomain = "production"
        task.lifecycleState = Definitions.FromWorkStatus(task.status)
        task.currentPhase = task.phase or task.lifecycleState
        task.taskGroup = taskGroup("production", task.operation)
        task.cancelAction = "cancel_work"
        task.cancelRequestId = task.requestId
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
    local medicalById = {}
    local medical = PNC.MedicalCareService
    if medical and medical.List then
        for _, task in ipairs(medical.List(false)) do
            if (not colonyId or not task.communityId
                or tostring(task.communityId) == tostring(colonyId))
            then
                local row = medicalTaskSnapshot(task, at)
                medicalById[tostring(task.id)] = row
                output[#output + 1] = row
            end
        end
    end
    local seenActivities = {}
    for _, lease in pairs(PNC.TaskLeaseService and PNC.TaskLeaseService.ByID or {}) do
        local record = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(lease.npcId) or nil
        local activity = record and record.runtime
            and record.runtime.facilityActivity or nil
        if activity and tostring(activity.taskLeaseId or "")
            == tostring(lease.leaseId or "")
        then
            seenActivities[tostring(record.id)] = true
        end
        if lease.sourceDomain ~= "work" then
            local affiliation = record and record.affiliation or {}
            local recordColony = tostring(affiliation.communityID or "")
            if not colonyId or recordColony == tostring(colonyId) then
                local state = lease.phase == "TRAVEL" and Definitions.STATE.TRAVEL
                    or lease.phase == "WORKING" and Definitions.STATE.WORKING
                    or lease.phase == "CANCELLING"
                        and Definitions.STATE.CANCELLING
                    or Definitions.STATE.CLAIMED
                local medicalRow = lease.sourceDomain == "medical"
                    and medicalById[tostring(lease.sourceRef or "")] or nil
                if medicalRow then
                    medicalRow.status = state
                    medicalRow.lifecycleState = state
                    medicalRow.currentPhase = record and record.runtime
                        and record.runtime.medicalCare
                        and record.runtime.medicalCare.phase or lease.phase
                    medicalRow.workerId = lease.npcId
                    medicalRow.actorId = lease.npcId
                    medicalRow.workerName = record
                        and tostring(record.name or record.id) or nil
                    medicalRow.taskLeaseId = lease.leaseId
                    medicalRow.leaseTaskId = lease.taskId
                    medicalRow.executionMode = lease.executionMode
                    medicalRow.lastProgressAt = lease.lastProgressAt
                        or medicalRow.lastProgressAt
                    medicalRow.cancellable = lease.phase ~= "CANCELLING"
                    medicalRow.cancelAction = "cancel_task"
                    medicalRow.cancelRequestId = lease.taskId
                else
                    output[#output + 1] = {
                        id = lease.taskId, requestId = lease.taskId,
                        sourceDomain = lease.sourceDomain,
                        taskGroup = taskGroup(lease.sourceDomain,
                            activity and activity.capability or lease.kind),
                        operation = activity and activity.capability
                            or lease.kind,
                        status = state, lifecycleState = state,
                        currentPhase = activity and activity.phase
                            or lease.phase,
                        workerId = lease.npcId, npcId = lease.npcId,
                        workerName = record
                            and tostring(record.name or record.id),
                        createdAt = lease.startedAt,
                        lastProgressAt = lease.lastProgressAt,
                        ageMs = math.max(0, at
                            - (tonumber(lease.startedAt) or at)),
                        facilityId = activity and activity.facilityId
                            or lease.facilityId,
                        facilityDefinitionId =
                            activityFacilityDefinitionId(activity),
                        stationId = lease.facilitySlotId,
                        activityItemFullType = activity
                            and activity.activityItemFullType or nil,
                        taskLeaseId = lease.leaseId,
                        progress = 0, requiredWork = 1, percent = 0,
                        durable = false, cancellable = true,
                        cancelAction = "cancel_task",
                        cancelRequestId = lease.taskId,
                        sourceRef = lease.sourceRef,
                        executionMode = lease.executionMode,
                    }
                end
            end
        end
    end
    if PNC.Registry and PNC.Registry.ForEach then
        PNC.Registry.ForEach(function(record)
            local activity = record and record.runtime
                and record.runtime.facilityActivity or nil
            if not activity or seenActivities[tostring(record.id)] then return end
            local affiliation = record.affiliation or {}
            local recordColony = tostring(affiliation.communityID or "")
            if colonyId and recordColony ~= tostring(colonyId) then return end
            local activityId = "activity:" .. tostring(record.id)
            local facility = activity.facilityId and PNC.SettlementRepository
                and PNC.SettlementRepository.GetFacility(activity.facilityId)
                or nil
            local state = activity.phase == "TRAVEL" and Definitions.STATE.TRAVEL
                or activity.phase == "WORKING" and Definitions.STATE.WORKING
                or Definitions.STATE.CLAIMED
            output[#output + 1] = {
                id = activityId, requestId = activityId,
                sourceDomain = "facility_activity",
                taskGroup = "needs",
                operation = activity.capability or "facility_activity",
                status = state, lifecycleState = state,
                currentPhase = activity.phase, workerId = record.id,
                npcId = record.id,
                workerName = tostring(record.name or record.id),
                createdAt = activity.startedAt,
                lastProgressAt = activity.lastProgressAt,
                ageMs = math.max(0, at - (tonumber(activity.startedAt) or at)),
                facilityId = activity.facilityId,
                facilityDefinitionId = facility and facility.definitionId or nil,
                activityItemFullType = activity.activityItemFullType,
                taskLeaseId = activity.taskLeaseId,
                progress = 0, requiredWork = 1, percent = 0,
                durable = false, cancellable = true,
                cancelAction = "cancel_task",
                cancelRequestId = activityId,
                manual = activity.manual == true,
            }
        end)
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
