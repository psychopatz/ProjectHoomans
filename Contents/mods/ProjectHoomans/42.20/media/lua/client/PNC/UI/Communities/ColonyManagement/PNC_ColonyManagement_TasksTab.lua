local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"

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

local OPERATION_KEYS = {
    CONSTRUCT = { "UI_PNC_Task_Construct", "BUILD" },
    RECONSTRUCT = { "UI_PNC_Task_Reconstruct", "RECONSTRUCT" },
    DECONSTRUCT = { "UI_PNC_Task_Deconstruct", "DECONSTRUCT" },
    BUILD_OBJECT = { "UI_PNC_Task_Construct", "BUILD" },
    CRAFT = { "UI_PNC_Task_Craft", "CRAFT" },
    DISASSEMBLE = { "UI_PNC_Task_Disassemble", "DISASSEMBLE" },
    RESEARCH = { "UI_PNC_Task_Research", "RESEARCH" },
}

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

local function taskLabel(task)
    local operation = tostring(task.operation or "")
    local definition = OPERATION_KEYS[operation]
    local verb = definition and Shared.Tr(definition[1], definition[2])
        or operation
    local target = targetName(task)
    return verb .. (target and " " .. target or "") .. "  "
        .. tostring(math.max(0, math.min(100,
            math.floor(tonumber(task.percent) or 0)))) .. "%"
end

local function taskDetail(task)
    local worker = task.workerName
        or Shared.Tr("UI_PNC_Task_Unassigned", "UNASSIGNED")
    local status = tostring(task.lifecycleState or task.status or "QUEUED")
    local mode = tostring(task.executionMode or "")
    local area = facilityName(task)
        or task.stationId and tostring(task.stationId)
        or Shared.Tr("UI_PNC_Task_BaseArea", "BASE AREA")
    local details = worker .. "  |  " .. status
    if mode ~= "" then details = details .. "  |  " .. mode end
    details = details .. "  |  " .. area
    if task.blockedReason and task.blockedReason ~= "" then
        details = details .. "  |  " .. tostring(task.blockedReason)
    end
    return details
end

function Tasks.BuildRows(context)
    local tasks = context.snapshot and context.snapshot.tasks or {}
    local rows = {}
    if #tasks <= 0 and #rows <= 0 then
        return {{
            key = "tasks_empty",
            label = Shared.Tr("UI_PNC_Tasks_None", "NO AVAILABLE TASKS"),
            detail = Shared.Tr("UI_PNC_Tasks_NoneHelp",
                "Queue construction, research, crafting, or deconstruction work."),
            colorName = "muted",
        }}
    end
    for index, task in ipairs(tasks) do
        local status = tostring(task.lifecycleState or task.status or "")
        rows[#rows + 1] = {
            key = tostring(task.id or index),
            label = taskLabel(task),
            detail = taskDetail(task),
            colorName = status == "BLOCKED" and "warning"
                or task.workerId and "success" or "muted",
            action = task.cancellable ~= false and "cancel_work" or nil,
            actionLabel = Shared.Tr("UI_PNC_Work_Cancel", "CANCEL"),
            actionColorName = "warning",
            workOrder = task,
        }
    end
    return rows
end

function Tasks.OnRow(window, row)
    local task = row and row.workOrder or nil
    if row.action ~= "cancel_work" or not task or not task.id then
        return false
    end
    local ConfirmModal = require "PNC/UI/Factions/PNC_FactionMemberModal"
    ConfirmModal.Open({
        title = Shared.Tr("UI_PNC_Work_CancelTitle", "Cancel Task"),
        message = Shared.Tr("UI_PNC_Work_CancelMessage",
            "Cancel this colony task?"),
        detail = cancelDetail(task),
        confirmLabel = Shared.Tr("UI_PNC_Work_Cancel", "CANCEL"),
        danger = true,
        context = { requestId = task.requestId or task.id },
        onConfirm = function(context)
            PNC.Client.RequestColonyAction("work_cancel", {
                requestId = context.requestId,
                workOrderId = context.requestId,
            })
        end,
    })
    return true
end

return Tasks
