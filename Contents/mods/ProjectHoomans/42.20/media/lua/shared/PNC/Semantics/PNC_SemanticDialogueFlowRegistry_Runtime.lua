-- Dialogue-flow registry storage, lookup, and frame matching.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Registry = PNC.Semantics.DialogueFlowRegistry

function Registry.Register(definition)
    local valid, normalized = Registry.Validate(definition)
    if not valid then return false, normalized end
    if #Registry.FlowOrder >= Registry.DEFAULT_MAX_FLOWS then
        return false, "flow_limit"
    end
    if Registry.Flows[normalized.id] then
        return false, "duplicate_flow_id:" .. normalized.id
    end
    Registry.Flows[normalized.id] = normalized
    Registry.FlowOrder[#Registry.FlowOrder + 1] = normalized.id
    Registry.Revision = Registry.Revision + 1
    return true, normalized
end

-- Regeneration may update a flow that was produced by the automatic
-- generator, but it must never overwrite an authored or otherwise-owned flow
-- with the same ID. Validation remains the single registry contract.
function Registry.ReplaceGenerated(definition)
    local valid, normalized = Registry.Validate(definition)
    if not valid then return false, normalized end
    local existing = Registry.Flows[normalized.id]
    if not existing then
        return Registry.Register(definition)
    end
    if existing.workflowKind == nil
        or normalized.workflowKind == nil
        or existing.workflowKind ~= normalized.workflowKind
    then
        return false, "generated_replace_requires_matching_workflow_kind"
    end
    Registry.Flows[normalized.id] = normalized
    Registry.Revision = Registry.Revision + 1
    return true, normalized
end

function Registry.Get(flowID)
    return Registry.Flows[flowID]
end

function Registry.List()
    local output = {}
    for index = 1, #Registry.FlowOrder do
        output[index] = Registry.FlowOrder[index]
    end
    return output
end

function Registry.GetRevision()
    return Registry.Revision
end

function Registry.FrameMatches(frame, ir)
    if type(frame) ~= "table" or type(ir) ~= "table" then return false end
    local social = type(ir.socialContext) == "table"
        and ir.socialContext or {}
    local state = type(ir.slots) == "table" and ir.slots.state or {}
    if frame.intent ~= nil and ir.intent ~= frame.intent then return false end
    if frame.speechAct ~= nil and ir.speechAct ~= frame.speechAct then
        return false
    end
    if frame.action ~= nil and ir.action ~= frame.action then return false end
    if frame.subject ~= nil and ir.subject ~= frame.subject then return false end
    if frame.target ~= nil and social.target ~= frame.target then return false end
    if frame.reference ~= nil then
        local reference = ir.references and ir.references.reference
            or ir.object and ir.object.reference
            or ir.target and ir.target.reference
        if reference ~= frame.reference then return false end
    end
    if frame.identityClaim ~= nil
        and social.identityClaim ~= frame.identityClaim
    then
        return false
    end
    if frame.selfDirected ~= nil
        and social.selfDirected ~= frame.selfDirected
    then
        return false
    end
    if frame.stateType ~= nil and state.type ~= frame.stateType then
        return false
    end
    if frame.stateValue ~= nil and state.value ~= frame.stateValue then
        return false
    end
    if frame.pattern ~= nil
        and (type(ir.provenance) ~= "table"
            or ir.provenance.pattern ~= frame.pattern)
    then
        return false
    end
    return true
end

function Registry.MatchesAny(frames, ir)
    if type(frames) ~= "table" then return false, nil end
    for index = 1, #frames do
        if Registry.FrameMatches(frames[index], ir) then
            return true, frames[index]
        end
    end
    return false, nil
end

function Registry.Reset()
    Registry.Flows = {}
    Registry.FlowOrder = {}
    Registry.Revision = Registry.Revision + 1
end

return Registry

