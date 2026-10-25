-- Automatic-flow artifact builder.
-- Classifies capability metadata and builds deterministic flow artifacts.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Generator = PNC.Semantics.AutomaticFlowGenerator

local Definitions = require
    "PNC/Semantics/PNC_SemanticAutomaticFlowGenerator_Definitions"
local buildFlow = require
    "PNC/Semantics/PNC_SemanticAutomaticFlowGenerator_Flow"
local TEMPLATES = Definitions.Templates
local copyValue = Definitions.CopyValue
local hasSource = Definitions.HasSource
local missingMetadata = Definitions.MissingMetadata

local function summaryFor(rows)
    local summary = {
        total = #rows,
        generated = 0,
        eligible = 0,
        metadata_incomplete = 0,
        recognition_only = 0,
        legacy = 0,
        unsupported_workflow = 0,
        conflicting = 0,
    }
    for index = 1, #rows do
        local key = rows[index].classification
        if summary[key] ~= nil then summary[key] = summary[key] + 1 end
    end
    return summary
end

local function build(capabilityCatalog)
    local actions = capabilityCatalog.ListActions()
    local rows = {}
    local byCapability = {}
    local candidates = {}
    local definitions = {}
    local responsePools = {}
    local index
    for index = 1, #actions do
        local action = actions[index]
        local row = {
            id = action.id,
            capabilityID = action.bindingID,
            binding = copyValue(action.binding),
            workflowKind = action.workflowKind,
            templateVersion = action.templateVersion,
            contractVersion = action.contractVersion,
            targetScope = action.targetScope,
            triggerFrames = copyValue(action.triggerFrames),
            requiredSlots = copyValue(action.requiredSlots),
            permissionGate = copyValue(action.permissionGate),
            outcomeMapping = copyValue(action.outcomeMapping),
            responsePools = copyValue(action.responsePools),
            translationOwner = action.translationOwner,
            recognized = action.recognized == true,
            dispatchable = action.dispatchable == true,
            sources = copyValue(action.sources),
            transports = copyValue(action.transports),
        }
        local template = TEMPLATES[row.workflowKind]
        local missing = template and missingMetadata(row, template) or {}
        local capabilityID = tostring(row.capabilityID or "")
        if capabilityID ~= "" and byCapability[capabilityID] then
            row.classification = "conflicting"
            row.reason = "capabilityID_registered_by_multiple_actions:"
                .. tostring(byCapability[capabilityID]) .. "," .. row.id
            row.missingMetadata = {}
        elseif template and #missing > 0 then
            row.classification = "metadata_incomplete"
            row.reason = tostring(row.workflowKind) .. "_metadata_missing"
            row.missingMetadata = missing
        elseif row.workflowKind ~= nil and not template
        then
            row.classification = "unsupported_workflow"
            row.reason = "workflow_kind_not_supported_by_automatic_generator:"
                .. tostring(row.workflowKind)
            row.missingMetadata = {}
        elseif template then
            row.classification = "eligible"
            row.reason = "complete_" .. tostring(row.workflowKind) .. "_metadata"
            row.missingMetadata = {}
            candidates[#candidates + 1] = action
        elseif hasSource(action, "task_adapter")
            or hasSource(action, "gift_lifecycle")
        then
            row.classification = "unsupported_workflow"
            row.reason = hasSource(action, "gift_lifecycle")
                and "gift_lifecycle_requires_multi_stage_template"
                or "task_adapter_requires_parameterized_task_template"
            row.missingMetadata = {}
        elseif action.dispatchable == true then
            row.classification = "legacy"
            row.reason = "registered_dispatch_route_has_no_versioned_generation_metadata"
            row.missingMetadata = {}
        else
            row.classification = "recognition_only"
            row.reason = "recognized_without_registered_dispatch_binding"
            row.missingMetadata = {}
        end
        if capabilityID ~= "" and not byCapability[capabilityID] then
            byCapability[capabilityID] = row.id
        end
        rows[#rows + 1] = row
    end

    table.sort(candidates, function(left, right) return left.id < right.id end)
    for index = 1, #candidates do
        local definition = buildFlow(candidates[index])
        definitions[#definitions + 1] = definition
        for poolIndex = 1, #definition.responsePools do
            responsePools[#responsePools + 1] = definition.responsePools[poolIndex]
        end
    end
    table.sort(rows, function(left, right) return left.id < right.id end)
    table.sort(definitions, function(left, right) return left.id < right.id end)
    table.sort(responsePools, function(left, right) return left.id < right.id end)
    return {
        schema = "pnc.automatic_flow_generation.v1",
        templateVersion = Generator.TEMPLATE_VERSION,
        templateFingerprint = Generator.TEMPLATE_FINGERPRINT,
        workflowKind = Generator.WORKFLOW_KIND,
        templates = copyValue(TEMPLATES),
        flows = definitions,
        responsePools = responsePools,
        coverage = rows,
        summary = summaryFor(rows),
    }
end

return {
    Build = build,
    SummaryFor = summaryFor,
}

