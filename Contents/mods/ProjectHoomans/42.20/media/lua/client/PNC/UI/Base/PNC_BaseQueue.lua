require "PsychopatzCore/UI/PsychopatzUI"

local Components = require
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Components"
local QueueRows = require "PNC/UI/Base/PNC_BaseQueueRows"
local FacilityActions = require
    "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_Actions"

local Queue = {}
local UI = PsychopatzCore.UI
local Layout = UI.Layout

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    if not value or value == key then return fallback end
    return value
end

local function createPane(window)
    return Components.CreatePane(window, 46, QueueRows.Draw)
end

function Queue.Create(window)
    window.baseQueuePane, window.baseQueueList = createPane(window)
    window.baseQueuePane:setHeader(
        tr("UI_PNC_Base_ConstructionQueue", "CONSTRUCTION QUEUE"), "0")
    window.baseQueueList.onMouseDown = function(list, x, y)
        if ISScrollingListBox and ISScrollingListBox.onMouseDown then
            ISScrollingListBox.onMouseDown(list, x, y)
        end
        local rowIndex = list:rowAt(x, y)
        local entry = rowIndex > 0 and list.items[rowIndex] or nil
        local row = entry and entry.item or nil
        if not row then return true end
        list.selected = rowIndex
        window.baseQueueSelectedID = row.id
        local right = list:getWidth() - 12
        local actionWidth = QueueRows.ActionWidth(row)
        local actionX = right - actionWidth
        if x >= actionX and x <= right then
            if row.kind == "native" then
                if PNC.Client and PNC.Client.RequestColonyAction then
                    PNC.Client.RequestColonyAction("work_cancel", {
                        workOrderId = row.id,
                    })
                end
            elseif row.task then
                FacilityActions.HandleComponent(window, {
                    kind = "cancel_work", workOrderId = row.id,
                    refundPercent = row.task.refundPercent,
                }, row.facility)
            end
            return true
        end
        if row.kind ~= "native" and row.task then
            local resumable = row.task.status == "BLOCKED"
                or row.task.status == "PAUSED"
                or row.task.status == "WAITING_FOR_WORKER"
            local resumeWidth = 98
            local resumeX = right - 105 - resumeWidth
            if resumable and x >= resumeX and x <= resumeX + resumeWidth then
                FacilityActions.HandleComponent(window, {
                    kind = "resume_work", workOrderId = row.id,
                }, row.facility)
                return true
            end
        end
        return true
    end
end

function Queue.Layout(window, content, top, bottom)
    if not window.baseQueuePane then return end
    local height = math.max(1, bottom - top)
    Layout.SetBounds(window.baseQueuePane, content.x, top,
        content.width, height)
end

function Queue.Apply(window, active)
    if window.baseQueuePane then window.baseQueuePane:setVisible(active) end
end

function Queue.Rebuild(window, snapshot)
    local list = window.baseQueueList
    if not list then return end
    local previous = window.baseQueueSelectedID
    local rows = {}
    local facilities = snapshot.settlement
        and snapshot.settlement.facilities or {}
    for _, facility in ipairs(facilities) do
        local task = facility.activeTask
        if task and task.id then
            rows[#rows + 1] = {
                id = task.id,
                kind = "facility",
                facility = facility,
                task = task,
                title = facility.displayName or facility.definitionId
                    or tr("UI_PNC_Base_BuildingProject", "BUILDING PROJECT"),
                worker = task.workerName
                    or tr("UI_PNC_Tasks_Unassigned", "UNASSIGNED"),
            }
        end
    end
    -- Keep the native blueprint queue visible during the migration. It is a
    -- different protocol from facility construction but is still useful to
    -- the player and must remain cancellable.
    for _, order in ipairs(snapshot.building
        and snapshot.building.queue or {}) do
        if order.id then
            rows[#rows + 1] = {
                id = order.id,
                kind = "native",
                order = order,
                title = order.displayName or order.objectInfoName
                    or tr("UI_PNC_Base_BlueprintQueue", "BLUEPRINT QUEUE"),
                worker = order.workerName or "UNASSIGNED",
            }
        end
    end
    table.sort(rows, function(left, right)
        return tostring(left.title) < tostring(right.title)
    end)
    Components.SetRowsStable(list, rows)
    local selected = 0
    for index, row in ipairs(rows) do
        if tostring(row.id) == tostring(previous) then selected = index end
    end
    list.selected = selected > 0 and selected or (#rows > 0 and 1 or 0)
    local count = #rows
    window.baseQueuePane:setHeader(
        tr("UI_PNC_Base_ConstructionQueue", "CONSTRUCTION QUEUE"),
        tostring(count))
end

return Queue
