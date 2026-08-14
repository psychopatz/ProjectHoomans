local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"

local Tasks = {}

local OPERATION_KEYS = {
    CONSTRUCT = { "UI_PNC_Task_Construct", "BUILD" },
    RECONSTRUCT = { "UI_PNC_Task_Reconstruct", "RECONSTRUCT" },
    DECONSTRUCT = { "UI_PNC_Task_Deconstruct", "DECONSTRUCT" },
    CRAFT = { "UI_PNC_Task_Craft", "CRAFT" },
    DISASSEMBLE = { "UI_PNC_Task_Disassemble", "DISASSEMBLE" },
    RESEARCH = { "UI_PNC_Task_Research", "RESEARCH" },
}

local NEED_TASKS = {
    hunger = { labelKey = "UI_PNC_Task_Eat", operation = "EAT",
        active = "eating", trigger = 0.25 },
    thirst = { labelKey = "UI_PNC_Task_Drink", operation = "DRINK",
        active = "drinking", trigger = 0.25 },
    fatigue = { labelKey = "UI_PNC_Task_Sleep", operation = "SLEEP",
        active = "sleeping", trigger = 0.70 },
}

local function needRows(context)
    local rows = {}
    for _, person in ipairs(context.snapshot and context.snapshot.people or {}) do
        for needType, definition in pairs(NEED_TASKS) do
            local value = tonumber(person.needs and person.needs[needType]) or 0
            local active = tostring(person.activity or "") == definition.active
            if active or value >= definition.trigger then
                local kind = needType == "thirst" and "HYDRATION"
                    or needType == "hunger" and "FOOD" or nil
                local lane = kind and person.supply and person.supply.byKind
                    and person.supply.byKind[kind] or nil
                local status = active and "WORKING"
                    or lane and tostring(lane.phase or "QUEUED") or "QUEUED"
                rows[#rows + 1] = {
                    key = "need:" .. tostring(person.id) .. ":" .. needType,
                    label = Shared.Tr(definition.labelKey,
                        definition.operation) .. "  "
                        .. tostring(person.name or person.id),
                    detail = status .. "  |  NEED "
                        .. tostring(math.floor(value * 100 + 0.5)) .. "%",
                    colorName = status == "FAILED" and "warning"
                        or active and "success" or "accent",
                }
            end
        end
    end
    table.sort(rows, function(a, b) return a.key < b.key end)
    return rows
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
    local status = tostring(task.status or "QUEUED")
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
    local rows = needRows(context)
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
        local status = tostring(task.status or "")
        rows[#rows + 1] = {
            key = tostring(task.id or index),
            label = taskLabel(task),
            detail = taskDetail(task),
            colorName = status == "BLOCKED" and "warning"
                or task.workerId and "success" or "muted",
        }
    end
    return rows
end

return Tasks
