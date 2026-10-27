-- Automatic-flow definition builder.
-- Converts eligible capability metadata into validated flow definitions.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Definitions = require
    "PNC/Semantics/PNC_SemanticAutomaticFlowGenerator_Definitions"
local TEMPLATES = Definitions.Templates
local copyValue = Definitions.CopyValue
local responsePoolID = Definitions.ResponsePoolID
local flowID = Definitions.FlowID
local genericTrigger = Definitions.GenericTrigger

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
        local variants = {
            {
                id = "default",
                -- Automatic-flow wording is resolved from the canonical
                -- Conversation shard. The capability adapter supplies facts
                -- and workflow metadata, never a second wording authority.
                templateID = poolID,
            },
        }
        for variantIndex, variant in ipairs(response.variants or {}) do
            if type(variant) == "table"
                and tostring(variant.id or "") ~= ""
            then
                variants[#variants + 1] = {
                    id = variant.id or ("context." .. tostring(variantIndex)),
                    templateID = poolID .. "." .. tostring(
                        variant.id or ("context." .. tostring(variantIndex))
                    ),
                    priority = tonumber(variant.priority) or 0,
                    when = copyValue(variant.when),
                }
            end
        end
        responsePools[#responsePools + 1] = {
            id = poolID,
            provenance = {
                origin = "automatic_flow",
                workflowKind = workflowKind,
                templateVersion = tonumber(row.templateVersion)
                    or template.version,
                templateFingerprint = template.fingerprint,
                actionID = action,
                capabilityID = capabilityID,
            },
            variants = variants,
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
            terminal = not (template.nonTerminalOutcomes
                and template.nonTerminalOutcomes[outcome] == true),
            responsePool = pools[outcome],
        }
        if template.nonTerminalOutcomes
            and template.nonTerminalOutcomes[outcome] == true
        then
            nodes[outcome].accepts = copyValue(row.triggerFrames)
                or genericTrigger(action)
            nodes[outcome].onMatch = outcome
            nodes[outcome].onUnrelated = "suspend"
        end
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

return buildFlow

