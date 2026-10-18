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

local function catalog(context)
    local Values = context.Values
    local flows = {}
    local CapabilityCatalog = capabilityCatalog()
    local semanticCatalog = CapabilityCatalog.Snapshot()
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

return FlowEditor
