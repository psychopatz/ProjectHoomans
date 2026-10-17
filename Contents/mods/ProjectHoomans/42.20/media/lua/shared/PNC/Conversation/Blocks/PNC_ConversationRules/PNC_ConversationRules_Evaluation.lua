local Rules = PNC.Conversation.Rules
local Registry = PNC.Conversation.Registry

local function invokeConditionStatus(handler, context, gate)
    local ok
    local passed
    local reason
    if handler.builtin == true then
        passed, reason = handler.evaluate(context, gate)
    else
        -- Registered addon callbacks are isolated failure boundaries.
        ok, passed, reason = pcall(handler.evaluate, context, gate)
        if not ok then return "FAIL", "condition_handler_error" end
    end
    if passed == true then return "PASS", reason end
    if passed == false then return "FAIL", reason end
    return "UNKNOWN", reason or "condition_unknown"
end

local function invertStatus(status)
    if status == "PASS" then return "FAIL" end
    if status == "FAIL" then return "PASS" end
    return "UNKNOWN"
end

local function evaluateGateStatus(gate, context)
    local handler
    local status
    local reason
    local sawUnknown = false
    if type(gate) ~= "table" then return "FAIL", "invalid_gate" end
    if gate.type == "all" then
        for _, child in ipairs(gate.gates or {}) do
            status, reason = evaluateGateStatus(child, context)
            if status == "FAIL" then return status, reason end
            if status == "UNKNOWN" then sawUnknown = true end
        end
        return sawUnknown and "UNKNOWN" or "PASS", reason
    end
    if gate.type == "any" then
        for _, child in ipairs(gate.gates or {}) do
            status, reason = evaluateGateStatus(child, context)
            if status == "PASS" then return status, reason end
            if status == "UNKNOWN" then sawUnknown = true end
        end
        return sawUnknown and "UNKNOWN" or "FAIL", reason
    end
    if gate.type == "not" then
        status, reason = evaluateGateStatus(gate.gate, context)
        return invertStatus(status), reason
    end
    handler = Registry.conditionHandlers[gate.type]
    if not handler then return "FAIL", "unknown_condition" end
    status, reason = invokeConditionStatus(handler, context or {}, gate)
    if status == "PASS" then return status, reason or "gate_passed" end
    return status, gate.reasonKey or reason or "gate_failed"
end

function Rules.EvaluateGate(gate, context)
    local status, reason = evaluateGateStatus(gate, context)
    return status == "PASS", reason
end

function Rules.EvaluateGateStatus(gate, context)
    return evaluateGateStatus(gate, context)
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
