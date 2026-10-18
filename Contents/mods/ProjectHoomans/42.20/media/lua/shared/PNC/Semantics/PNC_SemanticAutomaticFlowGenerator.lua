-- Deterministic metadata-driven production-flow generation.
--
-- This module only turns registered capability metadata into validated flow
-- data. It never parses text and never dispatches a gameplay command. The
-- existing DialogueInput action boundary remains the sole dispatcher.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Generator = PNC.Semantics.AutomaticFlowGenerator or {}
PNC.Semantics.AutomaticFlowGenerator = Generator

Generator.VERSION = 1
Generator.TEMPLATE_VERSION = 1
Generator.TEMPLATE_FINGERPRINT =
    "simple_command:v1:context_gate:typed_binding:one_dispatch:result_map"
Generator.WORKFLOW_KIND = "simple_command"

local TEMPLATES = {
    simple_command = {
        version = 1,
        fingerprint = Generator.TEMPLATE_FINGERPRINT,
        outcomes = { "queued", "rejected", "failed" },
    },
    parameterized_task = {
        version = 1,
        fingerprint =
            "parameterized_task:v1:context_gate:typed_slots:one_dispatch:admission_map",
        outcomes = { "admitted", "active", "completed", "rejected", "failed" },
    },
}

local REQUIRED_FIELDS = {
    "capabilityID", "workflowKind", "templateVersion", "contractVersion",
    "targetScope", "triggerFrames", "requiredSlots", "permissionGate",
    "outcomeMapping", "responsePools", "translationOwner",
}

local function copyValue(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 10 then return nil end
    local output = {}
    for key, item in pairs(value) do
        if type(key) ~= "function" and type(item) ~= "function" then
            output[key] = copyValue(item, depth + 1)
        end
    end
    return output
end

local function lowerID(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "[^%w]+", ".")
    value = string.gsub(value, "^%.", "")
    value = string.gsub(value, "%.$", "")
    return value
end

local function hasSource(row, source)
    for index = 1, #(row.sources or {}) do
        if row.sources[index] == source then return true end
    end
    return false
end

local function missingMetadata(row, template)
    local missing = {}
    for index = 1, #REQUIRED_FIELDS do
        local field = REQUIRED_FIELDS[index]
        if row[field] == nil then
            missing[#missing + 1] = field
        end
    end
    if type(row.binding) ~= "table" then
        missing[#missing + 1] = "binding"
    end
    if type(row.triggerFrames) == "table" and #row.triggerFrames == 0 then
        missing[#missing + 1] = "triggerFrames.nonempty"
    end
    if type(row.permissionGate) ~= "table"
        or tostring(row.permissionGate.type or "") == ""
    then
        missing[#missing + 1] = "permissionGate.type"
    end
    if type(row.outcomeMapping) == "table" then
        for index = 1, #template.outcomes do
            local outcome = template.outcomes[index]
            if type(row.outcomeMapping[outcome]) ~= "string"
                or row.outcomeMapping[outcome] == ""
            then
                missing[#missing + 1] = "outcomeMapping." .. outcome
            end
        end
    end
    if type(row.responsePools) == "table" then
        for index = 1, #template.outcomes do
            local outcome = template.outcomes[index]
            local response = row.responsePools[outcome]
            if type(response) ~= "table"
                or tostring(response.key or "") == ""
                or tostring(response.en or "") == ""
                or tostring(response.tl or "") == ""
            then
                missing[#missing + 1] = "responsePools." .. outcome
            end
        end
    end
    return missing
end

local function responsePoolID(action, outcome, workflowKind)
    return "semantic.generated." .. tostring(workflowKind) .. "."
        .. lowerID(action) .. "." .. tostring(outcome)
end

local function flowID(capabilityID, workflowKind)
    return "pnc.generated." .. tostring(workflowKind) .. "."
        .. lowerID(capabilityID)
end

local function genericTrigger(action)
    return {
        { intent = "REQUEST", speechAct = "REQUEST", action = action },
    }
end

local function buildFlow(row)
    local workflowKind = row.workflowKind
    local template = TEMPLATES[workflowKind]
    local binding = row.binding
    local capabilityID = row.bindingID or binding.id
    local action = row.id
    local mapping = {}
    for outcome, target in pairs(row.outcomeMapping) do
        mapping[outcome] = target
    end
    local pools = {}
    local responsePools = {}
    for index = 1, #template.outcomes do
        local outcome = template.outcomes[index]
        local response = row.responsePools[outcome]
        local poolID = responsePoolID(action, outcome, workflowKind)
        pools[outcome] = poolID
        responsePools[#responsePools + 1] = {
            id = poolID,
            variants = {
                {
                    id = "default",
                    templateID = response.key,
                    fallback = response.en,
                },
            },
        }
    end

    local nodes = {
        authorize = {
            id = "authorize",
            gate = copyValue(row.permissionGate),
            onPass = "request",
            onFail = "rejected",
            onUnknown = "rejected",
        },
        request = {
            id = "request",
            accepts = copyValue(row.triggerFrames)
                or genericTrigger(action),
            slots = copyValue(row.requiredSlots),
            action = {
                capabilityID = capabilityID,
                route = binding.route,
                targetScope = row.targetScope,
                binding = copyValue(binding),
                resultTransitions = mapping,
                dispatchCount = 1,
            },
            onMatch = "request",
        },
    }
    for index = 1, #template.outcomes do
        local outcome = template.outcomes[index]
        nodes[outcome] = {
            id = outcome,
            terminal = true,
            responsePool = pools[outcome],
        }
    end

    return {
        id = flowID(capabilityID, workflowKind),
        version = tonumber(row.contractVersion) or 1,
        owner = binding.owner or row.translationOwner or "ProjectHoomans",
        workflowKind = workflowKind,
        templateVersion = tonumber(row.templateVersion) or template.version,
        templateFingerprint = template.fingerprint,
        capabilityID = capabilityID,
        initial = "authorize",
        triggers = copyValue(row.triggerFrames) or genericTrigger(action),
        nodes = nodes,
        responsePools = responsePools,
    }
end

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

function Generator.Build(capabilityCatalog)
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

local function markGenerated(artifact, registry)
    local generated = {}
    for index = 1, #artifact.flows do
        local definition = artifact.flows[index]
        if registry.Get(definition.id) then
            generated[definition.capabilityID] = definition.id
        end
    end
    for index = 1, #artifact.coverage do
        local row = artifact.coverage[index]
        local flow = generated[row.capabilityID]
        if flow then
            row.classification = "generated"
            row.reason = "registered_generated_flow"
            row.flowID = flow
        end
    end
    artifact.generatedFlowIDs = {}
    for _, flowIDValue in pairs(generated) do
        artifact.generatedFlowIDs[#artifact.generatedFlowIDs + 1] = flowIDValue
    end
    table.sort(artifact.generatedFlowIDs)
    artifact.summary = summaryFor(artifact.coverage)
end

function Generator.Register(capabilityCatalog, artifact)
    local registry = PNC.Semantics.DialogueFlowRegistry
        or require "PNC/Semantics/PNC_SemanticDialogueFlowRegistry"
    local responses = PNC.Semantics.ResponseCatalog
        or require "PNC/Semantics/PNC_SemanticDialogueResponseCatalog"
    artifact = type(artifact) == "table" and artifact or Generator.Build(
        capabilityCatalog
    )
    for index = 1, #artifact.responsePools do
        local pool = artifact.responsePools[index]
        local registered = responses.Register(pool.id, pool)
        if registered ~= true then
            error("automatic semantic response registration failed: "
                .. tostring(pool.id))
        end
    end
    for index = 1, #artifact.flows do
        local definition = artifact.flows[index]
        if not registry.Get(definition.id) then
            local registered, reason = registry.Register(definition)
            if not registered then
                error("automatic semantic flow registration failed: "
                    .. tostring(definition.id) .. " (" .. tostring(reason) .. ")")
            end
        end
    end
    markGenerated(artifact, registry)
    artifact.registryRevision = registry.GetRevision()
    artifact.capabilityCatalogVersion = capabilityCatalog.VERSION
    return copyValue(artifact)
end

function Generator.Regenerate(capabilityCatalog)
    local artifact = Generator.Build(capabilityCatalog)
    return Generator.Register(capabilityCatalog, artifact)
end

return Generator
