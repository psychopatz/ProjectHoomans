-- Shared action-dispatch policy, diagnostics, and context helpers.

local Support = {}

Support.EXECUTABLE_ACTION_BRANCHES = {
    COMMAND_ACCEPTED = true,
    REQUEST_ACKNOWLEDGED = true,
    CAMP_REQUESTED = true,
    CONVERSATION_RECRUITMENT_REQUESTED = true,
}
Support.GIFT_DISPATCH_BRANCHES = {
    GIFT_OFFER_DISPATCHED = true,
    GIFT_SELECTION_REQUIRED = true,
    GIFT_CONSENT_GRANTED = true,
}
Support.INVENTORY_DISPATCH_BRANCHES = {
    INVENTORY_QUERY_RECEIVED = true,
}
Support.DIRECTED_HOSTILITY_BRANCHES = {
    HOSTILE_REMARK_RECEIVED = true,
    THREAT_RECEIVED = true,
}
Support.DIRECTED_HOSTILITY_ACTS = {
    INSULT = true,
    HOSTILE_REMARK = true,
    THREATEN = true,
}

function Support.dispatchBranchEligibility(decision, executableBranches)
    if decision.route == "llm_fallback" then
        return false, "llm_fallback_pending"
    end
    if executableBranches[decision.branch] == true then
        return true
    end
    if decision.branch == "ASK_CLARIFICATION"
        or decision.branch == "AMBIGUOUS_INPUT"
    then
        return false, "clarification_required"
    end
    return false, "dispatch_branch_not_approved"
end

function Support.blockedDispatch(reason)
    return {
        status = "semantic_dispatch_blocked",
        accepted = false,
        reason = reason,
    }
end

function Support.install(Input)
    local Internal = Input.Internal
    local Diagnostics = PNC.Semantics.SemanticDiagnostics
    local ActionContext = PNC.Semantics.DialogueInputActionContext

    function Support.audit(eventName, data, options)
        if not Diagnostics
            or type(Diagnostics.IsEnabled) ~= "function"
            or Diagnostics.IsEnabled() ~= true
        then
            return false
        end
        return Diagnostics.Record(eventName, data, options)
    end

    Support.actionContext = ActionContext.Build
    Internal.Audit = Support.audit
    Internal.ActionContext = Support.actionContext
end

return Support
