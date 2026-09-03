local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
local Presentation = require
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_TaskPresentation"

local Tasks = {}

local function cancelDetail(task)
    local detail = Shared.Tr("UI_PNC_Work_CancelTaskDetail",
        "The active worker is released and unfinished work is removed.")
    if task.refundPercent ~= nil then
        detail = detail .. "  " .. tostring(task.refundPercent) .. "% "
            .. Shared.Tr("UI_PNC_Work_Refundable", "RECOVERABLE")
    end
    return detail
end

local function addComboOptions(combo, options, current, default)
    if not combo then return end
    combo:clear()
    local selected = default
    for _, option in ipairs(options) do
        combo:addOptionWithData(Shared.Tr(option[2], option[3]), option[1])
        if option[1] == current then selected = current end
    end
    if combo.selectData then combo:selectData(selected) else combo.selected = 1 end
end

local function syncFilters(window)
    if not window then return end
    local group = Presentation.FilterValue(window, "taskGroupFilter", "all")
    local status = Presentation.FilterValue(window, "taskStatusFilter", "all")
    local sortMode = Presentation.FilterValue(window, "taskSort", "priority")
    window.taskGroupFilter = group
    window.taskStatusFilter = status
    window.taskSort = sortMode
    addComboOptions(window.taskGroupCombo, Presentation.FILTER_GROUPS,
        group, "all")
    addComboOptions(window.taskStatusCombo, Presentation.FILTER_STATUSES,
        status, "all")
    addComboOptions(window.taskSortCombo, Presentation.SORT_OPTIONS,
        sortMode, "priority")
end

function Tasks.Create(window)
    require "ISUI/ISComboBox"
    require "PsychopatzCore/UI/PsychopatzUI"
    local Components = require
        "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Components"
    window.taskGroupFilter = "all"
    window.taskStatusFilter = "all"
    window.taskSort = "priority"
    local function createCombo(width)
        local combo = ISComboBox:new(0, 0, width, 26, window,
            "onTaskFilter")
        combo:initialise()
        combo:instantiate()
        window:addChild(combo)
        return combo
    end
    window.taskGroupCombo = createCombo(140)
    window.taskStatusCombo = createCombo(150)
    window.taskSortCombo = createCombo(150)
    window.taskInspectorPane, window.taskInspector =
        Components.CreateDetailPane(window)
    window.taskInspectorPane:setVisible(false)
    window.taskInspector.onMouseDown = function(list, x, y)
        ISScrollingListBox.onMouseDown(list, x, y)
        local entry = list.items and list.items[list.selected] or nil
        local row = entry and entry.item or nil
        if row and row.action then
            Tasks.OnRow(window, row, x, y, true)
        end
    end
    syncFilters(window)
end

function Tasks.Apply(window, active, Layout)
    local combos = { window.taskGroupCombo, window.taskStatusCombo,
        window.taskSortCombo }
    for _, combo in ipairs(combos) do
        if combo then combo:setVisible(active == true) end
    end
    if not window.taskInspectorPane then return end
    window.taskInspectorPane:setVisible(active == true)
    if not active or not window.layout then return end
    local rect = window.layout.details
    local scale = window.uiScale
    local gap = Layout.Pixels(8, scale)
    local controlHeight = Layout.Pixels(27, scale)
    local bodyY = rect.y + controlHeight + gap
    local bodyHeight = math.max(40, rect.height - controlHeight - gap)
    local queueWidth = math.floor((rect.width - gap) * 0.58)
    local inspectorWidth = math.max(1, rect.width - gap - queueWidth)
    Layout.SetBounds(window.taskGroupCombo, rect.x, rect.y,
        Layout.Pixels(140, scale), controlHeight)
    Layout.SetBounds(window.taskStatusCombo,
        rect.x + Layout.Pixels(146, scale), rect.y,
        Layout.Pixels(150, scale), controlHeight)
    Layout.SetBounds(window.taskSortCombo,
        rect.x + Layout.Pixels(302, scale), rect.y,
        Layout.Pixels(150, scale), controlHeight)
    Layout.SetBounds(window.detailsPane, rect.x, bodyY, queueWidth, bodyHeight)
    window.detailsPane:layoutContent()
    Layout.SetBounds(window.taskInspectorPane, rect.x + queueWidth + gap, bodyY,
        inspectorWidth, bodyHeight)
    window.taskInspectorPane:layoutContent()
    window.taskInspectorPane:setHeader(Shared.Tr("UI_PNC_Tasks_Inspector",
        "TASK DETAILS"))
end

function Tasks.AfterRows(window, _, rows)
    if not window.taskInspector then return end
    local selectedId = window.selectedTaskId
    local selectedIndex
    local selectedTask
    for index, row in ipairs(rows or {}) do
        local task = row.workOrder
        if task then
            local requestId = Presentation.RequestId(task, index)
            if selectedId and tostring(selectedId) == requestId then
                selectedIndex, selectedTask = index, task
            elseif not selectedTask then
                selectedIndex, selectedTask = index, task
            end
        end
    end
    for index, row in ipairs(rows or {}) do
        row.selected = selectedTask ~= nil and index == selectedIndex
    end
    if selectedTask then
        window.selectedTaskId = Presentation.RequestId(selectedTask,
            selectedIndex)
        window.details.selected = selectedIndex
    else
        window.selectedTaskId = nil
        window.details.selected = 0
    end
    local Components = require
        "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Components"
    Components.SetRows(window.taskInspector,
        Presentation.InspectorRows(selectedTask))
end

function Tasks.BuildRows(context)
    local allTasks = context.snapshot and context.snapshot.tasks or {}
    local window = context.window
    syncFilters(window)
    local tasks = Presentation.BuildTaskList(allTasks, window)
    local visiblePending = {}
    if window and window.pendingTaskCancellations then
        for index, task in ipairs(allTasks) do
            visiblePending[Presentation.RequestId(task, index)] = true
        end
    end
    local rows = {}
    local pending = window and window.pendingTaskCancellations or nil
    local result = context.snapshot and context.snapshot.actionResult or nil
    local resultAction = result and tostring(result.action or "") or ""
    local isCancellation = resultAction == "work_cancel"
        or resultAction == "task_cancel"
        or resultAction == "medical_cancel"
    if isCancellation and pending and result.requestId then
        pending[tostring(result.requestId)] = nil
    end
    if isCancellation then
        rows[#rows + 1] = {
            key = "task_result:" .. tostring(result.requestId or resultAction),
            label = result.ok
                and Shared.Tr("UI_PNC_Work_CancelAccepted",
                    "CANCELLATION ACCEPTED")
                or Shared.Tr("UI_PNC_Work_CancelFailed",
                    "CANCELLATION FAILED"),
            detail = result.ok and Shared.Tr(
                "UI_PNC_Work_CancelAcceptedHelp",
                "The task owner is releasing this task.")
                or tostring(result.reason or "TASK_REQUEST_FAILED"),
            colorName = result.ok and "success" or "danger",
        }
    end
    if #tasks <= 0 and #rows <= 0 then
        return {{
            key = "tasks_empty",
            label = #allTasks > 0
                and Shared.Tr("UI_PNC_Tasks_NoMatch", "NO MATCHING TASKS")
                or Shared.Tr("UI_PNC_Tasks_None", "NO AVAILABLE TASKS"),
            detail = #allTasks > 0
                and Shared.Tr("UI_PNC_Tasks_NoMatchHelp",
                    "Change the filters to view the other queued tasks.")
                or Shared.Tr("UI_PNC_Tasks_NoneHelp",
                    "Queue construction, research, crafting, or deconstruction work."),
            colorName = "muted",
        }}
    end
    for index, task in ipairs(tasks) do
        local currentStatus = Presentation.TaskStatus(task)
        local requestId = Presentation.RequestId(task, index)
        local pendingCancellation = pending and pending[requestId] ~= nil
        local cancelling = pendingCancellation or currentStatus == "CANCELLING"
        local action
        if task.cancellable ~= false then
            action = task.cancelAction
                or (task.durable == false and "cancel_task" or "cancel_work")
        end
        local actionLabel = Shared.Tr("UI_PNC_Work_Cancel", "CANCEL")
        if cancelling then
            action = nil
            actionLabel = Shared.Tr("UI_PNC_Work_Cancelling", "CANCELLING...")
        elseif task.cancellable == false then
            actionLabel = nil
        end
        rows[#rows + 1] = {
            key = requestId,
            label = Presentation.TaskLabel(task),
            detail = Presentation.TaskDetail(task),
            colorName = task.stalled and "danger"
                or currentStatus == "BLOCKED" and "warning"
                or task.workerId and "success" or "muted",
            action = action,
            actionLabel = actionLabel,
            actionColorName = "warning",
            workOrder = task,
        }
    end
    if pending then
        for requestId, _ in pairs(pending) do
            if not visiblePending[requestId] then pending[requestId] = nil end
        end
    end
    return rows
end

function Tasks.OnRow(window, row, x, _, forceCancel)
    local task = row and row.workOrder or nil
    if not task or not task.id then return false end
    local canCancel = row.action == "cancel_work"
        or row.action == "cancel_task" or row.action == "cancel_medical"
    local cancelClick = forceCancel or (canCancel and (not x
        or not window.details or x >= window.details:getWidth() - 112))
    if not cancelClick then
        window.selectedTaskId = Presentation.RequestId(task)
        if window.rebuildDetails then window:rebuildDetails() end
        return true
    end
    if not canCancel then return false end
    local ConfirmModal = require "PNC/UI/Factions/PNC_FactionMemberModal"
    ConfirmModal.Open({
        title = Shared.Tr("UI_PNC_Work_CancelTitle", "Cancel Task"),
        message = Shared.Tr("UI_PNC_Work_CancelMessage",
            "Cancel this colony task?"),
        detail = cancelDetail(task),
        confirmLabel = Shared.Tr("UI_PNC_Work_Cancel", "CANCEL"),
        danger = true,
        context = {
            requestId = task.cancelRequestId or task.requestId or task.id,
        },
        onConfirm = function(context)
            local action = row.action == "cancel_work" and "work_cancel"
                or row.action == "cancel_medical" and "medical_cancel"
                or "task_cancel"
            local accepted = PNC.Client.RequestColonyAction(action, {
                requestId = context.requestId,
                workOrderId = context.requestId,
                taskId = context.requestId,
            })
            if accepted ~= false and window then
                window.pendingTaskCancellations =
                    window.pendingTaskCancellations or {}
                window.pendingTaskCancellations[context.requestId] =
                    PNC.Core and PNC.Core.Now and PNC.Core.Now() or true
            end
        end,
    })
    return true
end

return Tasks
