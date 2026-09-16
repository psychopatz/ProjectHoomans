-- Shared schema, bounds, and safe-value helpers for semantic action plans.
-- This module does not start tasks or mutate gameplay state.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Plan = PNC.Semantics.ActionPlan or {}
PNC.Semantics.ActionPlan = Plan
Plan.Internal = Plan.Internal or {}

Plan.VERSION = 1
Plan.KIND = "semantic_action_plan"
Plan.MAX_STEPS = 16
Plan.MAX_ID_LENGTH = 128
Plan.MAX_SOURCE_LENGTH = 64
Plan.MAX_TEXT_LENGTH = 4096
Plan.MAX_VALUE_DEPTH = 6
Plan.MAX_VALUE_FIELDS = 96

Plan.STATES = {
    PENDING = true,
    RUNNING = true,
    PAUSED = true,
    COMPLETED = true,
    FAILED = true,
    CANCELLED = true,
}

Plan.STEP_STATES = {
    PENDING = true,
    RESOLVING = true,
    ASSIGNED = true,
    TRAVEL = true,
    ARRIVED = true,
    WAITING = true,
    EXECUTING = true,
    COMPLETED = true,
    BLOCKED = true,
    FAILED = true,
    PAUSED = true,
    CANCELLED = true,
}

local function boundedText(value, maximum, fallback)
    if value == nil then return fallback end
    value = tostring(value)
    if value == "" then return fallback end
    return string.sub(value, 1, tonumber(maximum) or #value)
end

local function normalizeID(value, fallback)
    value = boundedText(value, Plan.MAX_ID_LENGTH, fallback)
    if not value then return nil end
    if string.find(value, "[^%w_%.:%-]", 1) then return nil end
    return value
end

local function normalizeAction(value)
    value = boundedText(value, Plan.MAX_ID_LENGTH, nil)
    if not value then return nil end
    value = string.upper(value)
    value = string.gsub(value, "[%s%-]+", "_")
    return value
end

local function normalizeState(value, states, fallback)
    value = string.upper(tostring(value or fallback or ""))
    return states[value] and value or nil
end

local function boundedNumber(value, minimum, maximum, fallback)
    value = tonumber(value)
    if value == nil then value = fallback end
    if value == nil then return nil end
    value = math.floor(value)
    if minimum and value < minimum then value = minimum end
    if maximum and value > maximum then value = maximum end
    return value
end

-- Only plain Lua data may cross the plan persistence/network boundary.
local function copyValue(value, depth, budget)
    local valueType = type(value)
    local output

    if value == nil or valueType == "string" or valueType == "number"
        or valueType == "boolean"
    then
        return value, true
    end
    if valueType ~= "table" or getmetatable(value) ~= nil then
        return nil, false
    end

    depth = tonumber(depth) or 0
    if depth >= Plan.MAX_VALUE_DEPTH then return nil, false end
    budget = budget or { count = 0, seen = {} }
    if budget.seen[value] then return nil, false end
    budget.seen[value] = true
    output = {}

    for key, item in pairs(value) do
        budget.count = budget.count + 1
        if budget.count > Plan.MAX_VALUE_FIELDS
            or (type(key) ~= "string" and type(key) ~= "number")
        then
            budget.seen[value] = nil
            return nil, false
        end

        local copiedKey, keyValid = copyValue(key, depth + 1, budget)
        local copiedItem, itemValid = copyValue(item, depth + 1, budget)
        if not keyValid or not itemValid then
            budget.seen[value] = nil
            return nil, false
        end
        output[copiedKey] = copiedItem
    end

    budget.seen[value] = nil
    return output, true
end

local function copyOptional(value)
    if value == nil then return nil, true end
    return copyValue(value)
end

local function touch(plan, now)
    plan.revision = (tonumber(plan.revision) or 0) + 1
    if now ~= nil then plan.updatedAt = tonumber(now) or plan.updatedAt end
end

local function stepAt(plan, reference)
    local index = tonumber(reference)
    if index then
        index = math.floor(index)
        if index >= 1 and index <= #plan.steps then
            return plan.steps[index], index
        end
    end
    reference = tostring(reference or "")
    if reference == "" then return nil end
    for index = 1, #plan.steps do
        if plan.steps[index].id == reference then
            return plan.steps[index], index
        end
    end
    return nil
end

Plan.Internal.BoundedText = boundedText
Plan.Internal.NormalizeID = normalizeID
Plan.Internal.NormalizeAction = normalizeAction
Plan.Internal.NormalizeState = normalizeState
Plan.Internal.BoundedNumber = boundedNumber
Plan.Internal.CopyValue = copyValue
Plan.Internal.CopyOptional = copyOptional
Plan.Internal.Touch = touch
Plan.Internal.StepAt = stepAt

return Plan
