local Shared = require
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"

local Brain = {}

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

local function priority(task, rank)
    local precedence = display(task and task.precedence, "IDLE")
    local work = task and task.workPriority
    local workLabel = work == nil and "-" or tostring(work)
    local urgency = tonumber(task and task.urgency)
    local urgencyLabel = urgency and string.format("%.2f", urgency) or "-"
    return (rank and ("RANK " .. tostring(rank) .. " | ") or "")
        .. precedence .. " | WORK P" .. workLabel
        .. " | URGENCY " .. urgencyLabel
end

local function taskName(task, fallback)
    task = task or {}
    return display(task.kind or task.operation, fallback or "TASK")
end

local function taskDetail(task, rank)
    task = task or {}
    local source = domain(task.sourceDomain)
    local phase = task.phase and display(task.phase, "") or "UNASSIGNED"
    local sourceRef = task.sourceRef and tostring(task.sourceRef) or "-"
    return priority(task, rank) .. " | " .. source
        .. " | PHASE " .. phase .. " | REF " .. sourceRef
end

local function taskRow(task, label, rank, pending)
    local row = {
        key = tostring(label or "TASK") .. ":" .. tostring(
            task and (task.taskId or task.leaseId) or "none"),
        label = tostring(label or "TASK") .. "  " .. taskName(task),
        detail = taskDetail(task, rank),
        colorName = label == "CURRENT TASK" and "accent"
            or rank == 1 and "success" or "muted",
        task = task,
    }
    if task and task.cancellable then
        if pending or task.phase == "CANCELLING" then
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

local function cancellationResult(result)
    local action = result and tostring(result.action or "") or ""
    return action == "work_cancel" or action == "medical_cancel"
        or action == "task_cancel"
end

local function requestId(task)
    return task and tostring(task.cancelRequestId or task.taskId or "") or ""
end

function Brain.BuildRows(person, window)
    if not person then
        return {{ key = "task_brain_empty",
            label = Shared.Tr("UI_PNC_TaskBrain_Select", "SELECT A COLONIST"),
            detail = Shared.Tr("UI_PNC_TaskBrain_SelectHelp",
                "Choose a colonist to inspect their task priorities.") }}
    end
    person = person.value or person
    local brain = person.taskBrain
    if not brain then
        return {{ key = "task_brain_unavailable",
            label = Shared.Tr("UI_PNC_TaskBrain_Unavailable",
                "TASK BRAIN UNAVAILABLE"),
            detail = Shared.Tr("UI_PNC_TaskBrain_UnavailableHelp",
                "This colonist has not produced a tasking diagnostic yet."),
            colorName = "warning" }}
    end

    local rows = {}
    rows[#rows + 1] = {
        key = "task_brain_header",
        label = text(person.name, person.id),
        detail = display(person.role, "COMPANION") .. " | "
            .. Shared.Tr("UI_PNC_TaskBrain_Freshness", "BRAIN") .. " "
            .. display(brain.freshness, "UNKNOWN"),
        colorName = "accent",
    }
    rows[#rows + 1] = {
        key = "task_brain_decision",
        label = Shared.Tr("UI_PNC_TaskBrain_Decision", "DECISION") .. "  "
            .. display(brain.decision, "NO DECISION"),
        detail = Shared.Tr("UI_PNC_TaskBrain_Cause", "LAST CAUSE") .. " "
            .. display(brain.lastCause, "-"),
        colorName = brain.freshness == "FRESH" and "success" or "warning",
    }

    local pending = window and window.pendingTaskBrainCancellations or {}
    local result = window and window.snapshot and window.snapshot.actionResult
    if cancellationResult(result) and not result.ok and result.requestId then
        pending[tostring(result.requestId)] = nil
    end
    local current = brain.current
    if current then
        rows[#rows + 1] = taskRow(current, "CURRENT TASK", nil,
            pending[requestId(current)] ~= nil)
    else
        rows[#rows + 1] = {
            key = "task_brain_current_none",
            label = Shared.Tr("UI_PNC_TaskBrain_NoCurrent", "CURRENT TASK  NONE"),
            detail = Shared.Tr("UI_PNC_TaskBrain_NoCurrentHelp",
                "The arbiter currently holds no task lease for this colonist."),
            colorName = "muted",
        }
    end

    local winner = brain.winner
    if winner then
        rows[#rows + 1] = {
            key = "task_brain_winner",
            label = Shared.Tr("UI_PNC_TaskBrain_Next", "PRIORITY 1") .. "  "
                .. taskName(winner),
            detail = taskDetail(winner, 1) .. " | "
                .. Shared.Tr("UI_PNC_TaskBrain_NextHelp",
                    "Highest eligible candidate returned by the arbiter."),
            colorName = "success",
        }
    else
        rows[#rows + 1] = {
            key = "task_brain_no_candidate",
            label = Shared.Tr("UI_PNC_TaskBrain_NoCandidate",
                "NO ELIGIBLE TASKS"),
            detail = display(brain.decision, "NO CANDIDATE"),
            colorName = "muted",
        }
    end

    local candidates = brain.candidates or {}
    rows[#rows + 1] = {
        key = "task_brain_candidates",
        label = Shared.Tr("UI_PNC_TaskBrain_Candidates", "POSSIBLE TASKS"),
        detail = tostring(brain.candidateCount or #candidates)
            .. (brain.hasMore and "+" or "") .. " "
            .. Shared.Tr("UI_PNC_TaskBrain_CandidatesHelp",
                "Ordered by the same priority comparator used by the arbiter."),
        colorName = "accent",
    }
    for index, candidate in ipairs(candidates) do
        local pendingTask = pending[requestId(candidate)] ~= nil
        local row = taskRow(candidate, "P" .. tostring(index), index, pendingTask)
        if not candidate.cancellable then
            row.detail = row.detail .. " | "
                .. Shared.Tr("UI_PNC_TaskBrain_Derived",
                    "DERIVED CANDIDATE - NOT A QUEUED REQUEST")
        end
        rows[#rows + 1] = row
    end

    local visible = {}
    if current then visible[requestId(current)] = true end
    for _, candidate in ipairs(candidates) do
        visible[requestId(candidate)] = true
    end
    for pendingId in pairs(pending) do
        if not visible[pendingId] then pending[pendingId] = nil end
    end

    for index, failure in ipairs(brain.providerFailures or {}) do
        rows[#rows + 1] = {
            key = "task_brain_failure:" .. tostring(index),
            label = Shared.Tr("UI_PNC_TaskBrain_ProviderFailure",
                "PROVIDER FAILURE") .. "  " .. display(failure.domain, "UNKNOWN"),
            detail = text(failure.error, "CALLBACK FAILED"),
            colorName = "danger",
        }
    end

    if cancellationResult(result)
        and tostring(result.requestId or "") == tostring(
            window.lastTaskBrainRequestId or "")
    then
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
    return rows
end

function Brain.OnRow(window, row)
    local task = row and row.task or nil
    if not task or not row.action then return false end
    local ConfirmModal = require "PNC/UI/Factions/PNC_FactionMemberModal"
    local requestId = task.cancelRequestId or task.taskId
    ConfirmModal.Open({
        title = Shared.Tr("UI_PNC_TaskBrain_CancelTitle", "Cancel Task"),
        message = Shared.Tr("UI_PNC_TaskBrain_CancelMessage",
            "Cancel this task for the selected colonist?"),
        detail = taskDetail(task),
        confirmLabel = Shared.Tr("UI_PNC_TaskBrain_Cancel", "CANCEL"),
        danger = true,
        context = {
            action = row.action,
            requestId = requestId,
            taskId = task.taskId,
            leaseId = task.leaseId,
            npcID = task.npcId,
            sourceDomain = task.sourceDomain,
            sourceRef = task.sourceRef,
            expectedRevision = task.cancelRevision,
        },
        onConfirm = function(context)
            local accepted = PNC.Client.RequestColonyAction(context.action, {
                requestId = context.requestId,
                workOrderId = context.requestId,
                taskId = context.taskId,
                leaseId = context.leaseId,
                npcID = context.npcID,
                taskBrainNpcID = context.npcID,
                sourceDomain = context.sourceDomain,
                sourceRef = context.sourceRef,
                expectedRevision = context.expectedRevision,
            })
            if accepted ~= false and window then
                window.pendingTaskBrainCancellations =
                    window.pendingTaskBrainCancellations or {}
                window.pendingTaskBrainCancellations[tostring(requestId)] =
                    PNC.Core and PNC.Core.Now and PNC.Core.Now() or true
                window.lastTaskBrainRequestId = tostring(requestId)
            end
        end,
    })
    return true
end

return Brain
