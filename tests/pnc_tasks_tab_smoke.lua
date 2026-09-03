local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "client" } })

getText = function(key) return key end
getItemNameFromFullType = function(fullType)
    return fullType == "Base.SpearCrafted" and "Crafted Spear" or fullType
end

local modalOptions
package.preload["PNC/UI/Factions/PNC_FactionMemberModal"] = function()
    return { Open = function(options) modalOptions = options end }
end

local cancelledId
local cancelledTaskId
local cancelledMedicalId
PNC = {
    Client = { RequestColonyAction = function(action, options)
        if action == "work_cancel" then
            cancelledId = options.workOrderId
        elseif action == "task_cancel" then
            T.equal(action, "task_cancel", "transient task action")
            cancelledTaskId = options.taskId
        else
            T.equal(action, "medical_cancel", "medical task action")
            cancelledMedicalId = options.taskId
        end
        return true
    end },
    FacilityDefinitions = {
        Get = function(id)
            return id == "barracks" and {
                displayNameKey = "UI_PNC_Facility_Barracks",
            } or nil
        end,
    },
    RecipeKnowledgeRegistry = {
        Queries = {
            Resolve = function(id)
                return id == 9 and { descriptor = { outputs = {
                    { itemTypes = { "Base.SpearCrafted" } },
                } } } or nil
            end,
        },
    },
}

local Tasks = require(
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_TasksTab"
)
local rows = Tasks.BuildRows({ snapshot = { tasks = {
    {
        id = "build-1", operation = "CONSTRUCT", status = "WORKING",
        percent = 40, workerId = "npc-1", workerName = "Peter",
        executionMode = "ABSTRACT", facilityDefinitionId = "barracks",
    },
    {
        id = "craft-1", operation = "CRAFT", status = "QUEUED",
        percent = 0, recipeId = 9,
    },
} } })

T.contains(rows[1].label, "barracks", "construction target")
T.contains(rows[1].label, "40%", "construction progress")
T.contains(rows[1].detail, "Peter", "assigned worker")
T.contains(rows[1].detail, "ABSTRACT", "abstract execution mode")
T.truthy(rows[1].action == "cancel_work"
    and rows[1].workOrder.id == "build-1",
    "work rows expose their cancellation action")
T.truthy(Tasks.OnRow({}, rows[1]), "cancel row opens confirmation")
T.truthy(modalOptions and modalOptions.onConfirm,
    "cancel confirmation supplies its handler")
modalOptions.onConfirm(modalOptions.context)
T.equal(cancelledId, "build-1", "confirmed row cancels selected work order")
T.contains(rows[2].label, "Crafted Spear", "craft output")
T.contains(rows[2].detail, "UNASSIGNED", "queued task assignment")

local transientRows = Tasks.BuildRows({ snapshot = { tasks = {
    { id = "activity:npc-1", requestId = "activity:npc-1",
        operation = "food.dine", sourceDomain = "facility_activity",
        durable = false, cancellable = true, workerName = "Peter",
        lifecycleState = "WORKING", percent = 0 },
} } })
T.equal(transientRows[1].action, "cancel_task",
    "active facility activity exposes a transient cancellation action")
T.truthy(Tasks.OnRow({}, transientRows[1]),
    "transient task opens confirmation")
modalOptions.onConfirm(modalOptions.context)
T.equal(cancelledTaskId, "activity:npc-1",
    "confirmed transient row cancels the selected activity")

local medicalRows = Tasks.BuildRows({ snapshot = { tasks = {
    { id = "medical:1", requestId = "medical:1",
        sourceDomain = "medical", taskGroup = "medical",
        operation = "MEDICAL_CARE", patientName = "Riley",
        lifecycleState = "WAITING_WORKER", currentPhase = "WAITING_FOR_DOCTOR",
        durable = true, cancellable = true, cancelAction = "cancel_medical",
        percent = 0,
        blocker = "missing_doctor" },
} } })
T.contains(medicalRows[1].label, "MEDICAL CARE Riley",
    "medical task identifies its domain and patient")
T.contains(medicalRows[1].detail, "PHASE WAITING_FOR_DOCTOR",
    "medical task exposes its provider phase")
T.equal(medicalRows[1].action, "cancel_medical",
    "durable medical request exposes its own cancellation action")
T.truthy(Tasks.OnRow({}, medicalRows[1]),
    "medical task opens cancellation confirmation")
modalOptions.onConfirm(modalOptions.context)
T.equal(cancelledMedicalId, "medical:1",
    "confirmed medical row sends the medical request ID")

local filterWindow = {
    taskGroupFilter = "medical", taskStatusFilter = "all",
    taskSort = "priority",
}
local filteredRows = Tasks.BuildRows({ window = filterWindow,
    snapshot = { tasks = {
        { id = "build-filtered", operation = "CONSTRUCT",
            taskGroup = "production", priority = 100 },
        { id = "medical-visible", operation = "MEDICAL_CARE",
            taskGroup = "medical", priority = 1 },
    } } })
T.equal(#filteredRows, 1, "task group filter only shows matching rows")
T.equal(filteredRows[1].workOrder.id, "medical-visible",
    "filtered queue preserves the canonical task row")

local sortedRows = Tasks.BuildRows({ window = { taskSort = "priority" },
    snapshot = { tasks = {
        { id = "low-priority", operation = "CONSTRUCT", priority = 1 },
        { id = "high-priority", operation = "CONSTRUCT", priority = 9 },
    } } })
T.equal(sortedRows[1].workOrder.id, "high-priority",
    "priority sort places urgent work first")

local selectWindow = {
    details = { getWidth = function() return 500 end },
    rebuildDetails = function(self) self.rebuilt = true end,
}
local selectRows = Tasks.BuildRows({ window = selectWindow,
    snapshot = { tasks = {
        { id = "inspect-1", operation = "CONSTRUCT", priority = 1 },
    } } })
T.truthy(Tasks.OnRow(selectWindow, selectRows[1], 20, 10),
    "clicking the task body selects instead of cancelling")
T.equal(selectWindow.selectedTaskId, "inspect-1",
    "selected task keeps its canonical ID")
T.truthy(selectWindow.rebuilt, "selection rebuilds the inspector")

local pendingWindow = {}
local pendingRows = Tasks.BuildRows({ window = pendingWindow,
    snapshot = { tasks = {
        { id = "pending-1", requestId = "pending-1", durable = true,
            cancellable = true, operation = "CONSTRUCT", percent = 10 },
} } })
T.truthy(Tasks.OnRow(pendingWindow, pendingRows[1]),
    "pending cancellation opens confirmation")
modalOptions.onConfirm(modalOptions.context)
local pendingRefresh = Tasks.BuildRows({ window = pendingWindow,
    snapshot = { tasks = {
        { id = "pending-1", requestId = "pending-1", durable = true,
            cancellable = true, operation = "CONSTRUCT", percent = 10 },
} } })
T.falsy(pendingRefresh[1].action, "pending task cannot be cancelled twice")
T.contains(pendingRefresh[1].actionLabel, "CANCELLING",
    "pending cancellation is visible in the task row")
local failedRefresh = Tasks.BuildRows({ window = pendingWindow,
    snapshot = {
        actionResult = { action = "work_cancel", requestId = "pending-1",
            ok = false, reason = "TASK_REQUEST_FORBIDDEN" },
        tasks = {
            { id = "pending-1", requestId = "pending-1", durable = true,
                cancellable = true, operation = "CONSTRUCT", percent = 10 },
        },
    } })
T.contains(failedRefresh[1].label, "CANCELLATION FAILED",
    "server cancellation failures are visible in the task queue")
T.equal(failedRefresh[2].action, "cancel_work",
    "failed cancellation restores the task action")

local empty = Tasks.BuildRows({ snapshot = { tasks = {} } })
T.contains(empty[1].label, "NO AVAILABLE TASKS", "empty task state")

local needs = Tasks.BuildRows({ snapshot = { tasks = {}, people = {
    { id = "npc-2", name = "Riley", activity = "sleeping",
        needs = { hunger = 0.31, thirst = 0.42, fatigue = 0.52 },
        supply = { byKind = {
            FOOD = { phase = "ACQUIRE" },
            HYDRATION = { phase = "FAILED" },
        } } },
} } })
T.equal(#needs, 1, "UI does not synthesize task state from raw needs")
T.contains(needs[1].label, "NO AVAILABLE TASKS",
    "transient tasks must arrive in the server snapshot")

T.finish("pnc_tasks_tab_smoke")
