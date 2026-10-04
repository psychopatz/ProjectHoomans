PNC = PNC or {}

local Model = {}
local Shared = require "PNC/UI/Shared/PNC_ColonyUIShared"
local Registry = require "PNC/Core/Jobs/PNC_JobRequirements"
local WorkRegistry = require "PNC/UI/CommandHub/PNC_CommandHub_WorkRegistry"

local function tr(key, fallback)
    return Shared.Tr(key, fallback)
end

function Model.ItemName(fullType)
    fullType = tostring(fullType or "")
    if fullType == "" then return "unknown item" end
    if getItemNameFromFullType then
        local value = getItemNameFromFullType(fullType)
        if value and tostring(value) ~= "" then return tostring(value) end
    end
    return string.gsub(string.match(fullType, "([^%.]+)$") or fullType,
        "_", " ")
end

function Model.OperationLabel(operation, definition)
    local fallback = string.gsub(string.upper(tostring(operation or "")),
        "_", " ")
    if definition and definition.labelKey then
        return tr(definition.labelKey, fallback)
    end
    if definition and definition.titleKey then
        return tr(definition.titleKey,
            definition.titleFallback or fallback)
    end
    return fallback
end

function Model.RequirementRows(operation)
    local definition = Registry.Get(operation)
    local rows = {}
    if not definition then
        rows[1] = {
            label = string.upper(tostring(operation or "")),
            detail = tr("UI_PNC_Storage_JobRequirements_Unregistered",
                "No requirements registered for this job."),
            colorName = "warning",
        }
        return rows
    end
    for index, requirement in ipairs(definition.requirements or {}) do
        local candidates = {}
        for _, fullType in ipairs(requirement.candidates or {}) do
            candidates[#candidates + 1] = Model.ItemName(fullType)
        end
        rows[#rows + 1] = {
            label = tr(requirement.labelKey,
                string.upper(tostring(requirement.role or "requirement"))),
            detail = string.format("%s | x%d | %s",
                table.concat(candidates, ", "),
                math.max(1, math.floor(tonumber(requirement.quantity) or 1)),
                requirement.durable and "durable" or "consumable"),
            colorName = requirement.equipSlot == "primary"
                and "accent" or "text",
            index = index,
        }
    end
    if #rows == 0 then
        rows[1] = {
            label = Model.OperationLabel(operation, definition),
            detail = tr("UI_PNC_Storage_JobRequirements_None",
                "This job has no registered item requirements."),
            colorName = "warning",
        }
    end
    return rows
end

function Model.Operations()
    local operations, definitions, seen = {}, {}, {}
    local function add(operation, definition)
        local key = string.upper(tostring(operation or ""))
        if key == "" or seen[key] then return end
        seen[key] = true
        operations[#operations + 1] = key
        definitions[key] = definition
    end
    for _, operation in ipairs(Registry.All and Registry.All() or {}) do
        add(operation, Registry.Get(operation))
    end
    for _, definition in ipairs(WorkRegistry.All and WorkRegistry.All()
        or {}) do
        add(definition.id, definition)
    end
    return operations, definitions
end

function Model.IsRegistered(operation)
    return Registry.Get(operation) ~= nil
end

return Model
