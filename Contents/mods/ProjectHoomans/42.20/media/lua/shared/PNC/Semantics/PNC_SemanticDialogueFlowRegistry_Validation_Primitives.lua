-- Primitive field normalizers for dialogue-flow definitions.
-- These bounded helpers are shared by frame and node normalization.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local ValueBounds = require "PNC/Semantics/PNC_SemanticValueBounds"
local copyValue = ValueBounds.Copy

local FRAME_FIELDS = {
    "intent", "speechAct", "action", "subject", "target", "reference",
    "identityClaim", "selfDirected", "stateType", "stateValue", "pattern",
}
local FRAME_FIELD_SET = {}
for index = 1, #FRAME_FIELDS do FRAME_FIELD_SET[FRAME_FIELDS[index]] = true end

local SPECIAL_TARGETS = {
    cancel = true,
    resume = true,
    suspend = true,
}

local GATE_FIELDS = {
    type = true,
    field = true,
    operator = true,
    value = true,
    reasonKey = true,
    unknownReasonKey = true,
    passReasonKey = true,
    failReasonKey = true,
    startHour = true,
    endHour = true,
    gates = true,
    gate = true,
    fact = true,
    subject = true,
    unit = true,
    unknownPolicy = true,
    capabilityID = true,
    requiresTarget = true,
    requiresAuthority = true,
}

local ACTION_FIELDS = {
    capabilityID = true,
    route = true,
    targetScope = true,
    binding = true,
    resultTransitions = true,
    dispatchCount = true,
}

local function stringValue(value)
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function frameKey(frame)
    local values = {}
    local index
    local field
    for index = 1, #FRAME_FIELDS do
        field = FRAME_FIELDS[index]
        if frame[field] ~= nil then
            values[#values + 1] = field .. "=" .. tostring(frame[field])
        end
    end
    return table.concat(values, "|")
end

local function normalizeFrame(frame, label)
    if type(frame) ~= "table" then
        return nil, label .. "_must_be_object"
    end
    local output = {}
    local key
    local value
    local supported = false
    for key, value in pairs(frame) do
        if not FRAME_FIELD_SET[key] then
            return nil, label .. "_unsupported_field:" .. tostring(key)
        end
        if type(value) ~= "string"
            and type(value) ~= "number"
            and type(value) ~= "boolean"
        then
            return nil, label .. "_field_must_be_scalar:" .. tostring(key)
        end
        output[key] = value
        supported = true
    end
    if not supported then return nil, label .. "_empty" end
    return output
end

local function normalizeTransition(value, nodes, label)
    if value == nil then return nil end
    value = stringValue(value)
    if not value then return nil, label .. "_empty" end
    if SPECIAL_TARGETS[value] then return value end
    if not nodes[value] then
        return nil, label .. "_unknown_node:" .. value
    end
    return value
end

local function normalizeSlots(slots, label)
    if slots == nil then return {} end
    if type(slots) ~= "table" then return nil, label .. "_must_be_object" end
    local output = {}
    local name
    local definition
    for name, definition in pairs(slots) do
        if type(name) ~= "string" or name == "" then
            return nil, label .. "_invalid_name"
        end
        if type(definition) ~= "table" then
            return nil, label .. "_invalid_slot:" .. name
        end
        local slotType = stringValue(definition.type)
        local owner = stringValue(definition.owner)
        local source = stringValue(definition.source)
        if not slotType or not owner then
            return nil, label .. "_slot_requires_type_and_owner:" .. name
        end
        output[name] = {
            type = slotType,
            owner = owner,
            source = source,
        }
    end
    return output
end

local function normalizeNodeList(values, label)
    if values == nil then return nil end
    if type(values) ~= "table" then
        return nil, label .. "_must_be_array"
    end
    local output = {}
    for index = 1, math.min(#values, 8) do
        local value = stringValue(values[index])
        if not value or #value > 64 then
            return nil, label .. "_item_invalid"
        end
        output[#output + 1] = value
    end
    return output
end

local function normalizeAction(action, nodes, label)
    if action == nil then return nil end
    if type(action) ~= "table" then
        return nil, label .. "_must_be_object"
    end
    local output = {}
    local key
    local value
    for key, value in pairs(action) do
        if not ACTION_FIELDS[key] then
            return nil, label .. "_unsupported_field:" .. tostring(key)
        end
        if key == "binding" then
            if type(value) ~= "table" then
                return nil, label .. "_binding_must_be_object"
            end
            output.binding = copyValue(value)
        elseif key == "resultTransitions" then
            if type(value) ~= "table" then
                return nil, label .. "_result_transitions_must_be_object"
            end
            output.resultTransitions = {}
            for outcome, target in pairs(value) do
                if type(outcome) ~= "string" or type(target) ~= "string"
                    or target == ""
                then
                    return nil, label .. "_invalid_result_transition"
                end
                if not SPECIAL_TARGETS[target] and not nodes[target] then
                    return nil, label .. "_result_unknown_node:" .. target
                end
                output.resultTransitions[outcome] = target
            end
        elseif key == "dispatchCount" then
            if value ~= 1 then
                return nil, label .. "_dispatch_count_must_be_one"
            end
            output.dispatchCount = 1
        else
            if type(value) ~= "string" and type(value) ~= "number"
                and type(value) ~= "boolean"
            then
                return nil, label .. "_field_invalid:" .. tostring(key)
            end
            output[key] = value
        end
    end
    if not output.capabilityID or not output.route
        or type(output.binding) ~= "table"
        or type(output.resultTransitions) ~= "table"
    then
        return nil, label .. "_requires_typed_binding_and_results"
    end
    output.dispatchCount = output.dispatchCount or 1
    return output
end

local function normalizeGate(gate, label)
    if gate == nil then return nil end
    if type(gate) ~= "table" then
        return nil, label .. "_must_be_object"
    end
    local gateType = stringValue(gate.type)
    if not gateType then return nil, label .. "_requires_type" end
    if gateType == "pnc:fact" and not stringValue(gate.fact or gate.subject) then
        return nil, label .. "_fact_required"
    end
    local output = { type = gateType }
    local key
    local value
    for key, value in pairs(gate) do
        if not GATE_FIELDS[key] then
            return nil, label .. "_unsupported_field:" .. tostring(key)
        end
        if key ~= "type" and type(value) ~= "string"
            and type(value) ~= "number"
            and type(value) ~= "boolean"
            and type(value) ~= "table"
        then
            return nil, label .. "_field_invalid:" .. tostring(key)
        end
        output[key] = copyValue(value)
    end
    return output
end

return {
    StringValue = stringValue,
    NormalizeFrame = normalizeFrame,
    NormalizeTransition = normalizeTransition,
    NormalizeSlots = normalizeSlots,
    NormalizeNodeList = normalizeNodeList,
    NormalizeAction = normalizeAction,
    NormalizeGate = normalizeGate,
    FrameKey = frameKey,
    SpecialTargets = SPECIAL_TARGETS,
}


