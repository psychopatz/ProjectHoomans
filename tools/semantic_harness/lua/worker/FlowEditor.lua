-- Bounded flow browser/editor seam over the production dialogue registry.
-- Draft validation and registration deliberately use the same Registry that
-- the live semantic policy loads; Python/Tk only presents and edits data.

local FlowEditor = {}
local Registry = require
    "PNC/Semantics/PNC_SemanticDialogueFlowCatalog"

local function capabilityCatalog()
    return PNC.Semantics.CapabilityCatalog
        or require "PNC/Semantics/PNC_SemanticCapabilityCatalog"
end

local function automaticGenerator()
    return PNC.Semantics.AutomaticFlowGenerator
        or require "PNC/Semantics/PNC_SemanticAutomaticFlowGenerator"
end

local function policyCatalog(Values, semanticCatalog)
    local Policy = PNC.Semantics.DialoguePolicy
        or require "PNC/Semantics/PNC_SemanticDialoguePolicy"
    local branches = {}
    local byID = {}
    local templates = type(Policy.ResponseTemplates) == "table"
        and Policy.ResponseTemplates or {}
    local branchID
    local definition
    for branchID, definition in pairs(templates) do
        if type(branchID) == "string" and type(definition) == "table" then
            byID[branchID] = {
                id = branchID,
                kind = "policy_branch",
                owner = "PNC.Semantics.DialoguePolicy",
                route = "DialoguePolicy.Internal.ResolveIntentBranch",
                triggerIDs = {},
                responseTemplate = Values.copy(definition),
            }
        end
    end

    local resolver = Policy.Internal
        and Policy.Internal.ResolveIntentBranch or nil
    if type(resolver) == "function" then
        for _, trigger in ipairs(semanticCatalog.triggers or {}) do
            local frame = type(trigger.frame) == "table"
                and Values.copy(trigger.frame) or {}
            local branch, reason = resolver(frame, {}, {}, nil)
            local row = byID[branch]
            if row then
                row.triggerIDs[#row.triggerIDs + 1] = trigger.id
                row.reason = row.reason or reason
            end
        end
    end

    for _, row in pairs(byID) do
        table.sort(row.triggerIDs)
        branches[#branches + 1] = row
    end
    table.sort(branches, function(left, right)
        return tostring(left.id) < tostring(right.id)
    end)
    return {
        schemaVersion = 1,
        owner = "PNC.Semantics.DialoguePolicy",
        branchCount = #branches,
        branches = branches,
    }
end

local function responsePoolCatalog(Values, responseCatalog)
    local output = {}
    local pools = type(responseCatalog) == "table"
        and responseCatalog.POOLS or {}
    for poolID, pool in pairs(pools) do
        if type(pool) == "table" and type(pool.id) == "string" then
            output[#output + 1] = {
                id = pool.id or tostring(poolID),
                variantCount = type(pool.variants) == "table"
                    and #pool.variants or 0,
            }
        end
    end
    table.sort(output, function(left, right)
        return tostring(left.id) < tostring(right.id)
    end)
    return output
end

local function publicGeneration(values, generation)
    local output = {}
    generation = type(generation) == "table" and generation or {}
    -- The top-level `flows` field already carries the normalized production
    -- registry. Exclude the generator's duplicate flow/response-pool payload
    -- from the bounded Lab envelope while retaining coverage and fingerprints.
    for key, value in pairs(generation) do
        if key ~= "flows" and key ~= "responsePools" then
            output[key] = values.copy(value)
        end
    end
    return output
end

local function catalog(context)
    local Values = context.Values
    local flows = {}
    local CapabilityCatalog = capabilityCatalog()
    if type(CapabilityCatalog.EnsureAutomaticGeneration) == "function" then
        CapabilityCatalog.EnsureAutomaticGeneration()
    end
    local semanticCatalog = CapabilityCatalog.Snapshot()
    local generation = CapabilityCatalog.AutomaticFlowGeneration or {}
    local policy = policyCatalog(Values, semanticCatalog)
    local ResponseCatalog = PNC.Semantics.ResponseCatalog
        or require "PNC/Semantics/PNC_SemanticDialogueResponseCatalog"
    local responsePools = responsePoolCatalog(Values, ResponseCatalog)
    local index
    local flowID
    local flow
    for index, flowID in ipairs(Registry.List()) do
        flow = Registry.Get(flowID)
        if type(flow) == "table" then
            flows[#flows + 1] = Values.copy(flow)
        end
    end
    return {
        ok = true,
        type = "flow_catalog",
        schemaVersion = 1,
        registryRevision = Registry.GetRevision(),
        flowCount = #flows,
        flows = flows,
        factCatalog = PNC.Semantics.EngineFacts
            and PNC.Semantics.EngineFacts.List
            and PNC.Semantics.EngineFacts.List() or {},
        eventCatalog = PNC.Semantics.EngineEvents
            and PNC.Semantics.EngineEvents.ListTypes
            and PNC.Semantics.EngineEvents.ListTypes() or {},
        commandCatalog = CapabilityCatalog.ListCommandActions(),
        actionCatalog = semanticCatalog.actions,
        triggerCatalog = semanticCatalog.triggers,
        conceptCatalog = semanticCatalog.concepts,
        speechActCatalog = semanticCatalog.speechActs,
        semanticCatalog = {
            schemaVersion = semanticCatalog.schemaVersion,
            registryRevision = semanticCatalog.registryRevision,
            actionCount = #semanticCatalog.actions,
            triggerCount = #semanticCatalog.triggers,
            conceptCount = #semanticCatalog.concepts,
            speechActCount = #semanticCatalog.speechActs,
        },
        generation = publicGeneration(Values, generation),
        policyCatalog = policy,
        responsePoolCatalog = responsePools,
        capabilityCoverage = Values.copy(generation.coverage or {}),
    }
end

function FlowEditor.catalog(context)
    return catalog(context)
end

function FlowEditor.validate(context, definition)
    local Values = context.Values
    local valid, normalized = Registry.Validate(definition)
    if not valid then
        return {
            ok = true,
            type = "flow_validation",
            schemaVersion = 1,
            valid = false,
            reason = tostring(normalized),
        }
    end
    return {
        ok = true,
        type = "flow_validation",
        schemaVersion = 1,
        valid = true,
        definition = Values.copy(normalized),
    }
end

function FlowEditor.register(context, definition)
    local Values = context.Values
    local valid, normalized = Registry.Validate(definition)
    if not valid then
        return {
            ok = true,
            type = "flow_registration",
            schemaVersion = 1,
            registered = false,
            valid = false,
            reason = tostring(normalized),
        }
    end
    local registered, result = Registry.Register(definition)
    if not registered then
        return {
            ok = true,
            type = "flow_registration",
            schemaVersion = 1,
            registered = false,
            valid = true,
            reason = tostring(result),
        }
    end
    local response = catalog(context)
    response.type = "flow_registration"
    response.registered = true
    response.valid = true
    response.definition = Values.copy(result)
    return response
end

function FlowEditor.generate(context)
    local Values = context.Values
    local CapabilityCatalog = capabilityCatalog()
    local artifact = automaticGenerator().Regenerate(CapabilityCatalog)
    CapabilityCatalog.AutomaticFlowGeneration = artifact
    local response = catalog(context)
    response.type = "flow_generation"
    response.generated = true
    response.generation = publicGeneration(Values, artifact)
    response.capabilityCoverage = Values.copy(artifact.coverage or {})
    return response
end

return FlowEditor
