local Rules = PNC.Conversation.Rules
local Registry = PNC.Conversation.Registry

local function invokeCondition(handler, context, gate)
    local ok
    local passed
    local reason
    if handler.builtin == true then
        return handler.evaluate(context, gate)
    end
    -- Registered addon callbacks are isolated failure boundaries.
    ok, passed, reason = pcall(handler.evaluate, context, gate)
    if not ok then return false, "condition_handler_error" end
    return passed == true, reason
end

local function evaluateAny(gate, context)
    local child
    local passed
    for _, child in ipairs(gate.gates or {}) do
        passed = Rules.EvaluateGate(child, context)
        if passed then return true end
    end
    return false, gate.reasonKey or "no_gate_matched"
end

function Rules.EvaluateGate(gate, context)
    local handler
    local passed
    local reason
    if type(gate) ~= "table" then return false, "invalid_gate" end
    if gate.type == "all" then
        return Rules.EvaluateAll(gate.gates, context)
    end
    if gate.type == "any" then return evaluateAny(gate, context) end
    if gate.type == "not" then
        passed = Rules.EvaluateGate(gate.gate, context)
        return not passed, gate.reasonKey
    end
    handler = Registry.conditionHandlers[gate.type]
    if not handler then return false, "unknown_condition" end
    passed, reason = invokeCondition(handler, context or {}, gate)
    if passed then return true end
    return false, gate.reasonKey or reason or "gate_failed"
end

function Rules.EvaluateAll(gates, context)
    local gate
    local passed
    local reason
    for _, gate in ipairs(gates or {}) do
        passed, reason = Rules.EvaluateGate(gate, context)
        if not passed then return false, reason, gate end
    end
    return true
end

function Rules.MatchesAudience(block, context)
    local audience
    for _, audience in ipairs(block and block.audiences or {}) do
        if context and context.audiences
            and context.audiences[audience] == true
        then
            return true
        end
    end
    return false
end

function Rules.CheckRepeat(policy, entry, worldAgeHours)
    if type(policy) ~= "table" then return true end
    entry = type(entry) == "table" and entry or {}
    if policy.oncePerDay == true and entry.lastUsedWorldHour ~= nil
        and math.floor((tonumber(entry.lastUsedWorldHour) or 0) / 24)
            == math.floor((tonumber(worldAgeHours) or 0) / 24)
    then
        return false, "once_per_day_used"
    end
    if policy.maxUses ~= nil
        and (tonumber(entry.useCount) or 0) >= tonumber(policy.maxUses)
    then
        return false, "max_uses_reached"
    end
    if policy.cooldownHours ~= nil and entry.lastUsedWorldHour ~= nil
        and (tonumber(worldAgeHours) or 0)
            < tonumber(entry.lastUsedWorldHour)
                + tonumber(policy.cooldownHours)
    then
        return false, "cooldown_active"
    end
    return true
end
