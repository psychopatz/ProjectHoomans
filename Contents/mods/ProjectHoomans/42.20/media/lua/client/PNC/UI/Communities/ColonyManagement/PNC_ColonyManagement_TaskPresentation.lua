local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"

local Presentation = {}

local OPERATION_KEYS = {
    CONSTRUCT = { "UI_PNC_Task_Construct", "BUILD" },
    RECONSTRUCT = { "UI_PNC_Task_Reconstruct", "RECONSTRUCT" },
    DECONSTRUCT = { "UI_PNC_Task_Deconstruct", "DECONSTRUCT" },
    BUILD_OBJECT = { "UI_PNC_Task_Construct", "BUILD" },
    CRAFT = { "UI_PNC_Task_Craft", "CRAFT" },
    DISASSEMBLE = { "UI_PNC_Task_Disassemble", "DISASSEMBLE" },
    RESEARCH = { "UI_PNC_Task_Research", "RESEARCH" },
    CORPSE_HAUL = { "UI_PNC_Task_CorpseHaul", "HAUL CORPSES" },
    PROVISION_PICKUP = { "UI_PNC_Task_Provision", "PROVISION" },
    LUMBER = { "UI_PNC_Task_Lumber", "LUMBER" },
    FISHING = { "UI_PNC_Task_Fishing", "FISHING" },
    FARMING = { "UI_PNC_Task_Farming", "FARMING" },
    SCAVENGE = { "UI_PNC_Task_Scavenge", "SCAVENGE" },
    MEDICAL_CARE = { "UI_PNC_Task_MedicalCare", "MEDICAL CARE" },
}

local GROUP_KEYS = {
    production = { "UI_PNC_Task_Group_Production", "PRODUCTION" },
    medical = { "UI_PNC_Task_Group_Medical", "MEDICAL" },
    needs = { "UI_PNC_Task_Group_Needs", "NEEDS" },
    zone = { "UI_PNC_Task_Group_Zone", "ZONE" },
    cleanup = { "UI_PNC_Task_Group_Cleanup", "CLEANUP" },
    provision = { "UI_PNC_Task_Group_Provision", "PROVISION" },
}

Presentation.FILTER_GROUPS = {
    { "all", "UI_PNC_Tasks_Filter_AllGroups", "ALL GROUPS" },
    { "production", "UI_PNC_Task_Group_Production", "PRODUCTION" },
    { "needs", "UI_PNC_Task_Group_Needs", "NEEDS" },
    { "zone", "UI_PNC_Task_Group_Zone", "ZONE" },
    { "cleanup", "UI_PNC_Task_Group_Cleanup", "CLEANUP" },
    { "provision", "UI_PNC_Task_Group_Provision", "PROVISION" },
    { "medical", "UI_PNC_Task_Group_Medical", "MEDICAL" },
}

Presentation.FILTER_STATUSES = {
    { "all", "UI_PNC_Tasks_Filter_AllStatuses", "ALL STATUS" },
    { "QUEUED", "UI_PNC_Task_Status_Queued", "QUEUED" },
    { "WAITING_WORKER", "UI_PNC_Task_Status_WaitingWorker", "WAITING WORKER" },
    { "WAITING_RESOURCE", "UI_PNC_Task_Status_WaitingResource", "WAITING RESOURCE" },
    { "TRAVEL", "UI_PNC_Task_Status_Travel", "TRAVEL" },
    { "CLAIMED", "UI_PNC_Task_Status_Claimed", "CLAIMED" },
    { "WORKING", "UI_PNC_Task_Status_Working", "WORKING" },
    { "BLOCKED", "UI_PNC_Task_Status_Blocked", "BLOCKED" },
    { "STALLED", "UI_PNC_Task_Status_Stalled", "STALLED" },
    { "CANCELLING", "UI_PNC_Task_Status_Cancelling", "CANCELLING" },
    { "FAILED", "UI_PNC_Task_Status_Failed", "FAILED" },
}

Presentation.SORT_OPTIONS = {
    { "priority", "UI_PNC_Tasks_Sort_Priority", "PRIORITY" },
    { "oldest", "UI_PNC_Tasks_Sort_Oldest", "OLDEST FIRST" },
    { "recent", "UI_PNC_Tasks_Sort_Recent", "MOST RECENT" },
    { "stalled", "UI_PNC_Tasks_Sort_Stalled", "STALLED FIRST" },
}

function Presentation.GroupFor(task)
    local group = tostring(task.taskGroup or "")
    if group == "" then
        local domain = tostring(task.sourceDomain or "")
        local operation = tostring(task.operation or "")
        if domain == "medical" or operation == "MEDICAL_CARE" then
            group = "medical"
        elseif domain == "NeedFacility" then
            group = "needs"
        elseif operation == "CORPSE_HAUL" then
            group = "cleanup"
        elseif operation == "PROVISION_PICKUP" then
            group = "provision"
        elseif domain == "fishing" or domain == "lumber"
            or domain == "farming" or domain == "scavenge"
        then
            group = "zone"
        else
            group = "production"
        end
    end
    return group
end

function Presentation.GroupLabel(task)
    local definition = GROUP_KEYS[Presentation.GroupFor(task)]
    return definition and Shared.Tr(definition[1], definition[2])
        or string.upper(Presentation.GroupFor(task))
end

function Presentation.TaskStatus(task)
    return tostring(task.lifecycleState or task.status or "QUEUED")
end

function Presentation.RequestId(task, index)
    return tostring(task.cancelRequestId or task.requestId or task.id or index)
end

local function filterValue(window, field, fallback)
    local value = window and window[field]
    return value and tostring(value) ~= "" and tostring(value) or fallback
end

function Presentation.FilterValue(window, field, fallback)
    return filterValue(window, field, fallback)
end

local function matchesFilter(task, group, status)
    if group ~= "all" and Presentation.GroupFor(task) ~= group then
        return false
    end
    if status == "STALLED" then return task.stalled == true end
    return status == "all" or Presentation.TaskStatus(task) == status
end

local function sortTasks(tasks, sortMode)
    table.sort(tasks, function(a, b)
        local aCreated = tonumber(a.createdAt) or math.huge
        local bCreated = tonumber(b.createdAt) or math.huge
        if sortMode == "oldest" then
            if aCreated ~= bCreated then return aCreated < bCreated end
        elseif sortMode == "recent" then
            if aCreated ~= bCreated then return aCreated > bCreated end
        elseif sortMode == "stalled" then
            if (a.stalled == true) ~= (b.stalled == true) then
                return a.stalled == true
            end
            local aProgress = tonumber(a.lastProgressAt) or aCreated
            local bProgress = tonumber(b.lastProgressAt) or bCreated
            if aProgress ~= bProgress then return aProgress < bProgress end
        else
            local aPriority = tonumber(a.priority) or 0
            local bPriority = tonumber(b.priority) or 0
            if aPriority ~= bPriority then return aPriority > bPriority end
            if (a.stalled == true) ~= (b.stalled == true) then
                return a.stalled == true
            end
            if aCreated ~= bCreated then return aCreated < bCreated end
        end
        return tostring(a.requestId or a.id or "")
            < tostring(b.requestId or b.id or "")
    end)
end

function Presentation.BuildTaskList(allTasks, window)
    local group = filterValue(window, "taskGroupFilter", "all")
    local status = filterValue(window, "taskStatusFilter", "all")
    local sortMode = filterValue(window, "taskSort", "priority")
    local tasks = {}
    for _, task in ipairs(allTasks or {}) do
        if matchesFilter(task, group, status) then tasks[#tasks + 1] = task end
    end
    sortTasks(tasks, sortMode)
    return tasks, group, status, sortMode
end

local function facilityName(task)
    local definition = task.facilityDefinitionId
        and PNC.FacilityDefinitions
        and PNC.FacilityDefinitions.Get(task.facilityDefinitionId) or nil
    if definition then
        return Shared.Tr(definition.displayNameKey,
            tostring(task.facilityDefinitionId))
    end
    return task.facilityDefinitionId and tostring(task.facilityDefinitionId)
        or nil
end

local function recipeName(task)
    local resolved = task.recipeId and PNC.RecipeKnowledgeRegistry
        and PNC.RecipeKnowledgeRegistry.Queries
        and PNC.RecipeKnowledgeRegistry.Queries.Resolve(task.recipeId) or nil
    local output = resolved and resolved.descriptor
        and resolved.descriptor.outputs and resolved.descriptor.outputs[1] or nil
    local fullType = output and output.itemTypes and output.itemTypes[1] or nil
    if fullType and getItemNameFromFullType then
        return getItemNameFromFullType(fullType)
    end
    return nil
end

local function targetName(task)
    local operation = tostring(task.operation or "")
    if operation == "MEDICAL_CARE" then
        return task.patientName or task.patientId or "PATIENT"
    end
    if operation == "CORPSE_HAUL" then return "CORPSE" end
    if operation == "PROVISION_PICKUP" then
        if task.activityItemFullType and getItemNameFromFullType then
            return getItemNameFromFullType(task.activityItemFullType)
        end
        return "SUPPLIES"
    end
    if operation == "CRAFT" then return recipeName(task) end
    if operation == "DISASSEMBLE" and task.specimenFullType
        and getItemNameFromFullType
    then
        return getItemNameFromFullType(task.specimenFullType)
    end
    if operation == "RESEARCH" and task.technologyId then
        local definition = PNC.ColonyResearchDefinitions
            and PNC.ColonyResearchDefinitions.Get(task.technologyId) or nil
        return definition and Shared.Tr(definition.labelKey,
            tostring(task.technologyId)) or tostring(task.technologyId)
    end
    if operation == "BUILD_OBJECT" then
        return task.buildDisplayName or task.objectInfoName
            or Shared.Tr("UI_PNC_Task_BaseArea", "BASE AREA")
    end
    return facilityName(task)
end

function Presentation.TaskLabel(task)
    local operation = tostring(task.operation or "")
    local activityVerb = {
        ["food.dine"] = "EAT",
        ["survival.eat.inventory"] = "EAT",
        ["water.drink"] = "DRINK",
        ["water.nearby"] = "DRINK",
        ["sleep"] = "SLEEP",
    }
    local definition = OPERATION_KEYS[operation]
    local verb = definition and Shared.Tr(definition[1], definition[2])
        or activityVerb[operation] or operation
    local target = targetName(task)
    if verb == "" then verb = "TASK" end
    return Presentation.GroupLabel(task) .. "  |  " .. verb
        .. (target and " " .. target or "") .. "  "
        .. tostring(math.max(0, math.min(100,
            math.floor(tonumber(task.percent) or 0)))) .. "%"
end

function Presentation.TaskDetail(task)
    local worker = task.workerName
        or Shared.Tr("UI_PNC_Task_Unassigned", "UNASSIGNED")
    local status = Presentation.TaskStatus(task)
    local phase = tostring(task.currentPhase or "")
    local mode = tostring(task.executionMode or "")
    local location = tostring(task.locationState or "")
    local area = facilityName(task)
        or task.stationId and tostring(task.stationId)
        or Shared.Tr("UI_PNC_Task_BaseArea", "BASE AREA")
    local details = Presentation.GroupLabel(task) .. "  |  " .. worker
        .. "  |  " .. status
    if phase ~= "" and phase ~= status then
        details = details .. "  |  PHASE " .. phase
    end
    if mode ~= "" then details = details .. "  |  " .. mode end
    if location == "AWAY_FOR_WORK" then
        details = details .. "  |  "
            .. Shared.Tr("UI_PNC_Task_AwayForWork", "AWAY FOR WORK")
    end
    details = details .. "  |  " .. area
    local target = targetName(task)
    if target and Presentation.GroupFor(task) ~= "production" then
        details = details .. "  |  TARGET " .. tostring(target)
    end
    local blocker = task.blocker or task.blockedReason
    if blocker and blocker ~= "" then
        details = details .. "  |  BLOCKED: " .. tostring(blocker)
    end
    if task.stalled then details = details .. "  |  STALLED" end
    if task.lastDiagnosticReason and task.lastDiagnosticReason ~= "" then
        details = details .. "  |  LAST "
            .. tostring(task.lastDiagnosticStage or "TASK") .. "="
            .. tostring(task.lastDiagnosticReason)
    end
    return details
end

function Presentation.InspectorRows(task)
    if not task then
        return {{
            key = "task_inspector_empty",
            label = Shared.Tr("UI_PNC_Tasks_Select", "SELECT A TASK"),
            detail = Shared.Tr("UI_PNC_Tasks_SelectHelp",
                "Choose a queue row to inspect its owner, phase, and blocker."),
            colorName = "muted",
        }}
    end
    local requestId = Presentation.RequestId(task)
    local status = Presentation.TaskStatus(task)
    local progress = tostring(math.max(0, math.min(100,
        math.floor(tonumber(task.percent) or 0)))) .. "%"
    if task.progress ~= nil and task.requiredWork ~= nil then
        progress = progress .. "  (" .. tostring(task.progress) .. "/"
            .. tostring(task.requiredWork) .. ")"
    end
    local rows = {
        { key = "summary", label = Shared.Tr("UI_PNC_Tasks_Summary", "SUMMARY"),
            detail = Presentation.TaskLabel(task), colorName = "accent" },
        { key = "request", label = Shared.Tr("UI_PNC_Tasks_Request", "REQUEST ID"),
            detail = requestId },
        { key = "group", label = Shared.Tr("UI_PNC_Tasks_Group", "GROUP"),
            detail = Presentation.GroupLabel(task) },
        { key = "status", label = Shared.Tr("UI_PNC_Tasks_Status", "LIFECYCLE"),
            detail = status },
        { key = "phase", label = Shared.Tr("UI_PNC_Tasks_Phase", "PHASE"),
            detail = tostring(task.currentPhase or status) },
        { key = "worker", label = Shared.Tr("UI_PNC_Tasks_Worker", "WORKER"),
            detail = tostring(task.workerName or task.workerId
                or Shared.Tr("UI_PNC_Task_Unassigned", "UNASSIGNED")) },
        { key = "target", label = Shared.Tr("UI_PNC_Tasks_Target", "TARGET"),
            detail = tostring(targetName(task) or Shared.Tr(
                "UI_PNC_Task_BaseArea", "BASE AREA")) },
        { key = "progress", label = Shared.Tr("UI_PNC_Tasks_Progress", "PROGRESS"),
            detail = progress },
    }
    if task.executionMode then
        rows[#rows + 1] = { key = "mode",
            label = Shared.Tr("UI_PNC_Tasks_Execution", "EXECUTION"),
            detail = tostring(task.executionMode) }
    end
    if task.locationState then
        rows[#rows + 1] = { key = "location",
            label = Shared.Tr("UI_PNC_Tasks_Location", "LOCATION"),
            detail = tostring(task.locationState) }
    end
    rows[#rows + 1] = { key = "blocker",
        label = Shared.Tr("UI_PNC_Tasks_Blocker", "BLOCKER"),
        detail = tostring(task.blocker or task.blockedReason
            or Shared.Tr("UI_PNC_Tasks_None", "NONE")),
        colorName = task.blocker and "warning" or nil }
    if task.failureReason then
        rows[#rows + 1] = { key = "failure",
            label = Shared.Tr("UI_PNC_Tasks_Failure", "FAILURE"),
            detail = tostring(task.failureReason), colorName = "danger" }
    end
    if task.stalled then
        rows[#rows + 1] = { key = "stalled",
            label = Shared.Tr("UI_PNC_Tasks_Stalled", "HEALTH"),
            detail = Shared.Tr("UI_PNC_Tasks_StalledHelp", "NO PROGRESS DETECTED"),
            colorName = "danger" }
    end
    if task.cancellable ~= false and task.cancelAction then
        rows[#rows + 1] = {
            key = "inspector_cancel:" .. requestId,
            label = Shared.Tr("UI_PNC_Work_Cancel", "CANCEL"),
            detail = Shared.Tr("UI_PNC_Work_CancelTaskDetail",
                "The active worker is released and unfinished work is removed."),
            action = task.cancelAction,
            actionLabel = Shared.Tr("UI_PNC_Work_Cancel", "CANCEL"),
            actionColorName = "warning",
            workOrder = task,
        }
    end
    return rows
end

return Presentation
