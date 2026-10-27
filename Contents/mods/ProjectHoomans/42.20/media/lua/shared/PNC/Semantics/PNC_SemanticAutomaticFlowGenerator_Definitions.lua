-- Automatic-flow templates and metadata validation helpers.
-- This module owns the versioned generation contract, not registry mutation.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Generator = PNC.Semantics.AutomaticFlowGenerator

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
    multi_stage_gift = {
        version = 1,
        fingerprint =
            "multi_stage_gift:v1:context_gate:typed_slots:one_dispatch:lifecycle_map",
        outcomes = {
            "selection_required", "pending", "completed", "rejected", "failed",
        },
        nonTerminalOutcomes = { pending = true },
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
            then
                missing[#missing + 1] = "responsePools." .. outcome
            elseif type(response.variants) == "table" then
                for variantIndex = 1, #response.variants do
                    local variant = response.variants[variantIndex]
                    if type(variant) ~= "table"
                        or tostring(variant.id or "") == ""
                    then
                        missing[#missing + 1] = "responsePools."
                            .. outcome .. ".variants." .. tostring(variantIndex)
                    end
                end
            end
        end
    end
    return missing
end

local function responsePoolID(action, outcome, workflowKind)
    local domain
    if workflowKind == "simple_command" then
        domain = "semantic.command"
    elseif workflowKind == "parameterized_task" then
        domain = "semantic.task"
    elseif workflowKind == "multi_stage_gift" then
        domain = "semantic.gift"
    else
        -- The current templates are exhaustive, but keep a deterministic
        -- domain for a future automatic workflow rather than reintroducing
        -- implementation provenance into the semantic namespace.
        domain = "semantic.automatic." .. lowerID(workflowKind)
    end
    local actionID = lowerID(action)
    -- GIFT is the workflow's semantic domain, not an additional meaning
    -- segment. This keeps the canonical IDs aligned with the existing gift
    -- response pools (semantic.gift.pending, semantic.gift.completed, ...).
    if workflowKind == "multi_stage_gift" and actionID == "gift" then
        return domain .. "." .. tostring(outcome)
    end
    return domain .. "." .. actionID .. "." .. tostring(outcome)
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

return {
    Templates = TEMPLATES,
    RequiredFields = REQUIRED_FIELDS,
    CopyValue = copyValue,
    HasSource = hasSource,
    MissingMetadata = missingMetadata,
    ResponsePoolID = responsePoolID,
    FlowID = flowID,
    GenericTrigger = genericTrigger,
}

