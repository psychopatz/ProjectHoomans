local Shared = require
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"

local Task = {}

local DOMAIN_LABELS = {
    work = "WORK",
    medical = "MEDICAL",
    NeedFacility = "NEEDS",
    facility_activity = "FACILITY",
    farming = "FARMING",
    fishing = "FISHING",
    lumber = "LUMBER",
    scavenge = "SCAVENGE",
}

local OPERATION_LABELS = {
    CONSTRUCT = "BUILD",
    RECONSTRUCT = "RECONSTRUCT",
    DECONSTRUCT = "DECONSTRUCT",
    BUILD_OBJECT = "BUILD",
    CRAFT = "CRAFT",
    DISASSEMBLE = "DISASSEMBLE",
    RESEARCH = "RESEARCH",
    CORPSE_HAUL = "CORPSE HAUL",
    PROVISION_PICKUP = "PROVISION",
    LUMBER = "LUMBER",
    FISHING = "FISHING",
    FARMING = "FARMING",
    SCAVENGE = "SCAVENGE",
    MEDICAL_CARE = "MEDICAL CARE",
}

local function text(value, fallback)
    return Shared.Text(value, fallback)
end

local function display(value, fallback)
    local result = text(value, fallback)
    result = string.gsub(result, "_", " ")
    return string.upper(result)
end

local function domain(value)
    local key = tostring(value or "")
    return DOMAIN_LABELS[key] or display(key, "UNKNOWN")
end

local function operation(task)
    task = task or {}
    local value = task.operation or task.kind
    local key = tostring(value or "")
    return OPERATION_LABELS[key] or display(key, "TASK")
end

local function requestId(task)
    task = task or {}
    return tostring(task.cancelRequestId or task.sourceRef
        or task.taskId or task.leaseId or "")
end

local function priorityDetail(task, rank)
    task = task or {}
    local rankValue = rank or task.rank
    local precedence = display(task.precedence, "IDLE")
    local workPriority = task.workPriority == nil
        and "-" or tostring(task.workPriority)
    local urgency = tonumber(task.urgency)
    local urgencyLabel = urgency and string.format("%.2f", urgency) or "-"
    local prefix = rankValue and "RANK " .. tostring(rankValue) .. " | " or ""
    return prefix .. precedence .. " | WORK PRIORITY " .. workPriority
        .. " | URGENCY " .. urgencyLabel
end

local function taskDetail(task, rank)
    task = task or {}
    local phase = display(task.phase, "UNASSIGNED")
    local reference = text(task.sourceRef or task.taskId or task.leaseId, "-")
    return priorityDetail(task, rank) .. " | DOMAIN "
        .. domain(task.sourceDomain) .. " | PHASE " .. phase
        .. " | REF " .. reference
end

local function taskRow(task, label, rank, pending)
    local row = {
        key = tostring(label or "TASK") .. ":" .. requestId(task),
        label = tostring(label or "TASK") .. "  " .. operation(task),
        detail = taskDetail(task, rank),
        colorName = label == "CURRENT TASK" and "accent"
            or rank == 1 and "success" or "muted",
        task = task,
    }
    if task and task.cancellable then
        if pending or task.cancellationRequested == true
            or tostring(task.phase or "") == "CANCELLING"
        then
            row.actionLabel = Shared.Tr("UI_PNC_TaskBrain_Cancelling",
                "CANCELLING...")
        elseif task.cancelAction then
            row.action = task.cancelAction
            row.actionLabel = Shared.Tr("UI_PNC_TaskBrain_Cancel", "CANCEL")
            row.actionColorName = "warning"
        end
    end
    return row
end

local function isCancellationResult(result)
    local action = result and tostring(result.action or "") or ""
    return action == "work_cancel" or action == "medical_cancel"
        or action == "task_cancel"
end

local function clearCompletedPending(window, result)
    if not window or not isCancellationResult(result)
        or not result.requestId
        or not window.pendingTaskBrainCancellations
    then
        return
    end
    window.pendingTaskBrainCancellations[tostring(result.requestId)] = nil
end

local function addResultRow(rows, window, result)
    if not isCancellationResult(result)
        or tostring(result.requestId or "")
            ~= tostring(window and window.lastTaskBrainRequestId or "")
    then
        return
    end
    rows[#rows + 1] = {
        key = "task_brain_result:" .. tostring(result.requestId),
        label = result.ok
            and Shared.Tr("UI_PNC_TaskBrain_CancelAccepted",
                "CANCELLATION ACCEPTED")
            or Shared.Tr("UI_PNC_TaskBrain_CancelFailed",
                "CANCELLATION FAILED"),
        detail = text(result.reason, result.ok and "TASK IS RELEASING"
            or "TASK WAS NOT CANCELLED"),
        colorName = result.ok and "success" or "danger",
    }
end

function Task.BuildRows(context)
    local person = context and context.selectedPerson or nil
    if not person then
        return {{
            key = "task_brain_empty",
            label = Shared.Tr("UI_PNC_TaskBrain_Select", "SELECT A COLONIST"),
            detail = Shared.Tr("UI_PNC_TaskBrain_SelectHelp",
                "Choose a colonist to inspect their task priorities."),
        }}
    end

    person = person.value or person
    local brain = person.taskBrain
    if not brain then
        return {{
            key = "task_brain_unavailable",
            label = Shared.Tr("UI_PNC_TaskBrain_Unavailable",
                "TASK BRAIN UNAVAILABLE"),
            detail = Shared.Tr("UI_PNC_TaskBrain_UnavailableHelp",
                "Open the Task tab again after the selected colonist is evaluated."),
            colorName = "warning",
        }}
    end

    local window = context.window
    local result = window and window.snapshot
        and window.snapshot.actionResult or nil
    clearCompletedPending(window, result)
    local pending = window and window.pendingTaskBrainCancellations or {}
    local rows = {
        {
            key = "task_brain_header",
            label = text(person.name, person.id),
            detail = display(person.role, "COMPANION") .. " | BRAIN "
                .. display(brain.freshness, "UNKNOWN"),
            colorName = "accent",
        },
        {
            key = "task_brain_decision",
            label = Shared.Tr("UI_PNC_TaskBrain_Decision", "DECISION") .. "  "
                .. display(brain.decision, "NO DECISION"),
            detail = Shared.Tr("UI_PNC_TaskBrain_Cause", "LAST CAUSE") .. " "
                .. display(brain.lastCause, "-")
                .. " | EVENT " .. display(brain.eventType, "-"),
            colorName = brain.freshness == "FRESH" and "success" or "warning",
        },
    }

    local current = brain.current
    if current then
        rows[#rows + 1] = taskRow(current, "CURRENT TASK", nil,
            pending[requestId(current)] ~= nil)
    else
        rows[#rows + 1] = {
            key = "task_brain_current_none",
            label = Shared.Tr("UI_PNC_TaskBrain_NoCurrent",
                "CURRENT TASK  NONE"),
            detail = Shared.Tr("UI_PNC_TaskBrain_NoCurrentHelp",
                "The arbiter currently holds no task lease for this colonist."),
            colorName = "muted",
        }
    end

    rows[#rows + 1] = {
        key = "task_brain_candidates",
        label = Shared.Tr("UI_PNC_TaskBrain_Candidates",
            "POSSIBLE TASK ORDER"),
        detail = tostring(brain.candidateCount
            or #(brain.candidates or {}))
            .. (brain.hasMore and "+" or "") .. " "
            .. Shared.Tr("UI_PNC_TaskBrain_CandidatesHelp",
                "Ranked by the same comparator used by the task arbiter."),
        colorName = "accent",
    }

    local candidates = brain.candidates or {}
    for index, candidate in ipairs(candidates) do
        local rank = tonumber(candidate.rank) or index
        local row = taskRow(candidate, "RANK " .. tostring(rank), rank,
            pending[requestId(candidate)] ~= nil)
        if not candidate.cancellable then
            row.detail = row.detail .. " | "
                .. Shared.Tr("UI_PNC_TaskBrain_Derived",
                    "DERIVED / NOT QUEUED")
        end
        rows[#rows + 1] = row
    end

    for index, failure in ipairs(brain.providerFailures or {}) do
        rows[#rows + 1] = {
            key = "task_brain_failure:" .. tostring(index),
            label = Shared.Tr("UI_PNC_TaskBrain_ProviderFailure",
                "PROVIDER FAILURE") .. "  "
                .. domain(failure.domain),
            detail = text(failure.error, "CALLBACK FAILED"),
            colorName = "danger",
        }
    end

    addResultRow(rows, window, result)
    return rows
end

function Task.OnRow(window, row)
    local task = row and row.task or nil
    if not task or not row.action then return false end

    local ConfirmModal = require "PNC/UI/Factions/PNC_FactionMemberModal"
    local id = requestId(task)
    if id == "" then return false end
    ConfirmModal.Open({
        title = Shared.Tr("UI_PNC_TaskBrain_CancelTitle", "Cancel Task"),
        message = Shared.Tr("UI_PNC_TaskBrain_CancelMessage",
            "Cancel this task for the selected colonist?"),
        detail = taskDetail(task),
        confirmLabel = Shared.Tr("UI_PNC_TaskBrain_Cancel", "CANCEL"),
        danger = true,
        context = {
            action = row.action,
            requestId = id,
            taskId = task.taskId,
            leaseId = task.leaseId,
            npcID = task.npcId,
            sourceDomain = task.sourceDomain,
            sourceRef = task.sourceRef,
            expectedRevision = task.cancelRevision,
        },
        onConfirm = function(confirmContext)
            local client = PNC.Client
            local request = client and client.RequestColonyAction
            local accepted = request and request(confirmContext.action, {
                requestId = confirmContext.requestId,
                workOrderId = confirmContext.requestId,
                taskId = confirmContext.taskId,
                leaseId = confirmContext.leaseId,
                npcID = confirmContext.npcID,
                taskBrainNpcID = confirmContext.npcID,
                sourceDomain = confirmContext.sourceDomain,
                sourceRef = confirmContext.sourceRef,
                expectedRevision = confirmContext.expectedRevision,
            }) or false
            if accepted ~= false and window then
                window.pendingTaskBrainCancellations =
                    window.pendingTaskBrainCancellations or {}
                window.pendingTaskBrainCancellations[id] =
                    PNC.Core and PNC.Core.Now and PNC.Core.Now() or true
                window.lastTaskBrainRequestId = id
            end
        end,
    })
    return true
end

return Task
