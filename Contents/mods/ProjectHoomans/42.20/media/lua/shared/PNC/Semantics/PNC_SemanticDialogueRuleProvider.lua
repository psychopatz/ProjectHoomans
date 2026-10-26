-- Stable semantic contract for authored conversation gate evaluation.
--
-- The flow kernel depends on this provider, not on Conversation's concrete
-- rule implementation. Conversation binds its registry-backed rules during
-- its own composition phase.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Provider = PNC.Semantics.DialogueRuleProvider or {}
PNC.Semantics.DialogueRuleProvider = Provider

Provider.VERSION = 1

function Provider.Bind(implementation)
    if type(implementation) ~= "table"
        or type(implementation.EvaluateGateStatus) ~= "function"
    then
        return false, "invalid_dialogue_rule_provider"
    end
    Provider.Implementation = implementation
    return true
end

function Provider.IsBound()
    return type(Provider.Implementation) == "table"
        and type(Provider.Implementation.EvaluateGateStatus) == "function"
end

function Provider.EvaluateGateStatus(gate, context)
    local implementation = Provider.Implementation
    if not implementation then
        return "UNKNOWN", "conversation_rules_unavailable"
    end
    return implementation.EvaluateGateStatus(gate, context)
end

return Provider
