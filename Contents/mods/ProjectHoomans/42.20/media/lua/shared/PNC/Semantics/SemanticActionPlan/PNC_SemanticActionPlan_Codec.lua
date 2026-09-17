-- Normalization, validation, and cloning for semantic action plans.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Plan = PNC.Semantics.ActionPlan
local Internal = Plan.Internal
local boundedText = Internal.BoundedText
local normalizeID = Internal.NormalizeID
local normalizeAction = Internal.NormalizeAction
local normalizeState = Internal.NormalizeState
local boundedNumber = Internal.BoundedNumber
local copyValue = Internal.CopyValue
local copyOptional = Internal.CopyOptional
local stepAt = Internal.StepAt

local function normalizeStep(raw, index)
    if type(raw) ~= "table" then return nil, "step_invalid" end

    local id = normalizeID(raw.id, "step:" .. tostring(index))
    if not id then return nil, "step_id_invalid" end

    local action = normalizeAction(raw.action)
    if not action then return nil, "step_action_required" end

    local state = normalizeState(raw.state, Plan.STEP_STATES, "PENDING")
    if not state then return nil, "step_state_invalid" end

    local parameters = raw.parameters or raw.spec or raw.args or {}
    local copiedParameters, parametersValid = copyValue(parameters)
    if not parametersValid then return nil, "step_parameters_unsafe" end

    local result, resultValid = copyOptional(raw.result)
    if not resultValid then return nil, "step_result_unsafe" end

    local diagnostics, diagnosticsValid = copyOptional(raw.diagnostics)
    if not diagnosticsValid then return nil, "step_diagnostics_unsafe" end

    local assignment, assignmentValid = copyOptional(raw.assignment)
    if not assignmentValid then return nil, "step_assignment_unsafe" end

    return {
        id = id,
        action = action,
        state = state,
        parameters = copiedParameters or {},
        onFailure = string.upper(tostring(raw.onFailure or "STOP")),
        retryLimit = boundedNumber(raw.retryLimit, 0, 5, 0),
        retryCount = boundedNumber(raw.retryCount, 0, 5, 0),
        timeoutMs = boundedNumber(raw.timeoutMs, 0, 86400000, 0),
        leaseID = normalizeID(raw.leaseID, nil),
        resumeState = normalizeState(raw.resumeState, Plan.STEP_STATES, nil),
        assignment = assignment,
        result = result,
        diagnostics = diagnostics,
        revision = boundedNumber(raw.revision, 1, 2147483647, 1),
    }
end

function Plan.Normalize(raw)
    if type(raw) ~= "table" then return nil, "plan_required" end

    local planID = normalizeID(raw.planID or raw.id, nil)
    if not planID then return nil, "plan_id_required" end
    local npcID = normalizeID(raw.npcID or raw.npcId, nil)
    if not npcID then return nil, "plan_npc_id_required" end
    if type(raw.steps) ~= "table" or #raw.steps < 1 then
        return nil, "plan_steps_required"
    end
    if #raw.steps > Plan.MAX_STEPS then return nil, "plan_steps_exceeded" end

    local state = normalizeState(raw.state, Plan.STATES, "PENDING")
    if not state then return nil, "plan_state_invalid" end

    local steps = {}
    local seenIDs = {}
    for index = 1, #raw.steps do
        local step, reason = normalizeStep(raw.steps[index], index)
        if not step then return nil, reason end
        if seenIDs[step.id] then return nil, "step_id_duplicate" end
        seenIDs[step.id] = true
        steps[index] = step
    end

    local currentStep = boundedNumber(raw.currentStep, 1, #steps + 1, 1)
    if state ~= "COMPLETED" and currentStep > #steps then
        return nil, "plan_current_step_invalid"
    end

    local provenance, provenanceValid = copyOptional(raw.provenance)
    if not provenanceValid then return nil, "plan_provenance_unsafe" end
    local metadata, metadataValid = copyOptional(raw.metadata)
    if not metadataValid then return nil, "plan_metadata_unsafe" end

    local confidence = tonumber(raw.confidence) or 0
    confidence = math.max(0, math.min(1, confidence))

    return {
        schemaVersion = Plan.VERSION,
        kind = Plan.KIND,
        planID = planID,
        npcID = npcID,
        source = boundedText(raw.source, Plan.MAX_SOURCE_LENGTH,
            "semantic_dialogue"),
        requestID = normalizeID(raw.requestID or raw.requestId, nil),
        state = state,
        currentStep = currentStep,
        steps = steps,
        interruptPolicy = string.upper(
            tostring(raw.interruptPolicy or "PAUSE")),
        manualOverride = raw.manualOverride == true,
        confidence = confidence,
        rawText = boundedText(raw.rawText or raw.text,
            Plan.MAX_TEXT_LENGTH, ""),
        provenance = provenance or {},
        metadata = metadata or {},
        revision = boundedNumber(raw.revision, 1, 2147483647, 1),
        createdAt = tonumber(raw.createdAt) or 0,
        updatedAt = tonumber(raw.updatedAt) or tonumber(raw.createdAt) or 0,
    }
end

function Plan.Validate(plan)
    if type(plan) ~= "table"
        or tonumber(plan.schemaVersion) ~= Plan.VERSION
        or plan.kind ~= Plan.KIND
    then
        return false, "invalid_plan_schema"
    end
    if not normalizeID(plan.planID, nil) then
        return false, "plan_id_required"
    end
    if not normalizeID(plan.npcID, nil) then
        return false, "plan_npc_id_required"
    end
    if not Plan.STATES[plan.state] then return false, "plan_state_invalid" end
    if type(plan.steps) ~= "table" or #plan.steps < 1
        or #plan.steps > Plan.MAX_STEPS
    then
        return false, "plan_steps_invalid"
    end
    if tonumber(plan.currentStep) == nil
        or math.floor(tonumber(plan.currentStep)) ~= tonumber(plan.currentStep)
        or plan.currentStep < 1 or plan.currentStep > #plan.steps + 1
    then
        return false, "plan_current_step_invalid"
    end

    local seenIDs = {}
    for index = 1, #plan.steps do
        local step = plan.steps[index]
        if type(step) ~= "table" or not normalizeID(step.id, nil)
            or not normalizeAction(step.action)
            or not Plan.STEP_STATES[step.state]
            or type(step.parameters) ~= "table"
            or seenIDs[step.id]
        then
            return false, "plan_step_invalid"
        end
        seenIDs[step.id] = true
    end
    return true, plan
end

function Plan.Clone(plan)
    local cloned, valid = copyValue(plan)
    return valid and cloned or nil
end

function Plan.Current(plan)
    if type(plan) ~= "table" then return nil end
    return stepAt(plan, plan.currentStep)
end

return Plan
