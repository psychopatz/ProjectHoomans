-- Completion of deferred, cognition-backed gossip requests.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Input = PNC.Semantics.DialogueInput
local Internal = Input.Internal

function Input.CompleteGossipRequest(request)
    local view = request and request.view or nil
    local session = request and request.session or nil
    local requestID = tostring(request and request.requestID or "")
    local result
    local decision
    local localResponse
    local context
    local value
    if not view or not session or requestID == ""
        or view.session ~= session or session.closed == true
        or view.closed == true or view.closing == true
        or tostring(session.semanticGossipRequestID or "") ~= requestID
        or type(session.semanticDialoguePending) ~= "table"
        or tostring(session.semanticDialoguePending.requestID or "")
            ~= requestID
    then
        return false, "stale_gossip_request"
    end
    result = session.semanticGossipRequestResult
    value = session.semanticGossipRequestValue
    decision = result and result.decision or nil
    if not result or not result.ir or not decision then
        return false, "gossip_response_unavailable"
    end
    context = Internal.ShallowContext(view)
    local groundedGossip = context and context.npcGossip or nil
    if not groundedGossip
        or groundedGossip.source ~= "world_knowledge"
    then
        local clientState = PNC.Network and PNC.Network.ClientState or nil
        local clientGossip = clientState
            and clientState.semanticWorldKnowledgeGossip or nil
        local npcID = view.spec and tostring(view.spec.npcID or "") or ""
        groundedGossip = clientGossip and clientGossip[npcID] or nil
    end
    if groundedGossip and groundedGossip.source == "world_knowledge"
        and type(groundedGossip.factRefs) == "table"
        and #groundedGossip.factRefs > 0
    then
        local response = result.decision.response
        if type(response) == "table" then
            response.groundedFactRefs = {}
            for index = 1, math.min(#groundedGossip.factRefs, 4) do
                response.groundedFactRefs[#response.groundedFactRefs + 1] =
                    groundedGossip.factRefs[index]
            end
            response.selectionSource = "world_knowledge"
            if type(response.plan) == "table" then
                response.plan.groundedFactRefs = response.groundedFactRefs
                response.plan.sourcePoolID = "world_knowledge"
            end
        end
    end
    localResponse = PNC.Semantics and PNC.Semantics.LocalResponse or nil
    if localResponse and type(localResponse.Resolve) == "function" then
        decision.response = localResponse.Resolve(
            result.ir,
            session.semanticDialogueState,
            context,
            decision.branch
        ) or decision.response
    end
    if groundedGossip and groundedGossip.source == "world_knowledge"
        and type(groundedGossip.factRefs) == "table"
        and #groundedGossip.factRefs > 0
        and type(decision.response) == "table"
    then
        decision.response.groundedFactRefs = {}
        for index = 1, math.min(#groundedGossip.factRefs, 4) do
            decision.response.groundedFactRefs[#decision.response.groundedFactRefs + 1] =
                groundedGossip.factRefs[index]
        end
        decision.response.selectionSource = "world_knowledge"
        if type(decision.response.plan) == "table" then
            decision.response.plan.groundedFactRefs =
                decision.response.groundedFactRefs
            decision.response.plan.sourcePoolID = "world_knowledge"
        end
    end
    session.semanticMemoryTargetID = nil
    session.semanticGossipRequestID = nil
    session.semanticGossipRequestResult = nil
    session.semanticGossipRequestValue = nil
    session.semanticDialoguePending = nil
    if type(Internal.QueueDeterministicResponse) ~= "function" then
        return false, "response_queue_unavailable"
    end
    return Internal.QueueDeterministicResponse(view, value, result, nil)
end
