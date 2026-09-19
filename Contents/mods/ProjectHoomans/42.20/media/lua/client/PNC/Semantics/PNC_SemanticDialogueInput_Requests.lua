-- Narrow semantic request contracts for client-owned dialogue integrations.
PNC = PNC or {}

local Requests = {}

function Requests.RequestCognitionForIR(view, ir)
    local subject
    local fact
    local target
    local targetID
    local lifecycle
    local context
    local request
    if type(ir) ~= "table"
        or ir.intent ~= "QUESTION"
    then
        return false, "not_a_fact_question"
    end
    subject = tostring(ir.subject or "")
    if subject == ""
        or subject == "TIME"
        or subject == "DATE"
        or subject == "WEATHER"
        or subject == "IDENTITY"
    then
        return false, "local_world_fact"
    end
    fact = ir.extensions and ir.extensions.facts
        and ir.extensions.facts[subject] or nil
    if type(fact) == "table" and fact.status == "known" then
        return false, "fact_already_known"
    end
    target = ir.target
    if type(target) ~= "table" or target.unresolved == true then
        return false, "target_unresolved"
    end
    targetID = target.id or target.entityID or target.npcID
    if tostring(targetID or "") == "" then
        return false, "target_id_unavailable"
    end
    context = view and view.spec and view.spec.context or {}
    lifecycle = context and context.conversationLifecycleState or nil
    request = PNC.Client and PNC.Client.RequestSemanticCognition
    if type(request) ~= "function" then
        return false, "cognition_request_unavailable"
    end
    return request(
        view and view.spec and view.spec.npcID,
        {
            subject = subject,
            targetID = targetID,
            conversationToken = lifecycle and lifecycle.token,
        }
    )
end

local function identityClaimName(ir)
    local claim = ir and ir.slots and ir.slots.identityClaim or nil
    return type(claim) == "table" and claim.name or nil
end

local function pendingIdentity(context)
    local state = context and context.semanticContextState
    return context and context.pendingIdentityExchange
        or state and state.pendingIdentityExchange
        or context and context.semanticDialogueContext
        and context.semanticDialogueContext.pendingIdentityExchange
end

-- Identity disclosure and claims retain their existing network contracts.
function Requests.PrepareIdentityRequest(view, ir, context)
    local npcID = view and view.spec and view.spec.npcID
    local lifecycle = context and context.conversationLifecycleState or nil
    if type(ir) ~= "table" or not npcID then
        return nil
    end

    if ir.intent == "QUESTION" and ir.subject == "IDENTITY" then
        if context.identityTrust == "untrustworthy" then
            return nil
        end
        if context.identityState == "known"
        then
            return nil
        end
        return {
            kind = "identity_disclosure",
            npcID = npcID,
            conversationToken = lifecycle and lifecycle.token,
        }
    end

    if ir.socialContext and ir.socialContext.identityClaim == true then
        return {
            kind = "identity_claim",
            npcID = npcID,
            claimedName = identityClaimName(ir),
            conversationToken = lifecycle and lifecycle.token,
        }
    end

    if pendingIdentity(context)
        and not (ir.intent == "QUESTION" and ir.subject == "IDENTITY")
    then
        return {
            kind = "identity_evasion",
            npcID = npcID,
            conversationToken = lifecycle and lifecycle.token,
        }
    end
    return nil
end

function Requests.DispatchIdentityRequest(request)
    request = type(request) == "table" and request or nil
    local client = PNC.Client
    if not request or not client then return false, "identity_request_unavailable" end
    if request.kind == "identity_disclosure" then
        if type(client.RequestNPCKnowledgeTopic) ~= "function" then
            return false, "identity_disclosure_unavailable"
        end
        local pending = PNC.Network and PNC.Network.ClientState
            and PNC.Network.ClientState.pendingDisclosure
            and PNC.Network.ClientState.pendingDisclosure[
                tostring(request.npcID)
            ]
        if pending then return false, "identity_request_pending" end
        return client.RequestNPCKnowledgeTopic(
            request.npcID, "identity_name", {
                conversationToken = request.conversationToken,
                origin = "semantic_dialogue",
            }
        )
    end
    if type(client.SubmitSemanticIdentity) ~= "function" then
        return false, "identity_claim_transport_unavailable"
    end
    return client.SubmitSemanticIdentity(request.npcID, {
        kind = request.kind,
        claimedName = request.claimedName,
        conversationToken = request.conversationToken,
        origin = "semantic_dialogue",
    })
end

function Requests.RequestIdentityForIR(view, ir, context, internal)
    internal = internal or Requests
    return internal.DispatchIdentityRequest(
        internal.PrepareIdentityRequest(view, ir, context)
    )
end

return Requests
