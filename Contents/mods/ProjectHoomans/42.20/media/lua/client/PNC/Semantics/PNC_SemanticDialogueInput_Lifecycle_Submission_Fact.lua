-- Completion of deferred, read-only live-fact questions.
--
-- The server has already projected the authoritative fact into the
-- conversation-scoped cognition cache. This completion path re-resolves the
-- original IR and lets the normal local response/catalog realization consume
-- it; it never starts or changes an excursion.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Input = PNC.Semantics.DialogueInput
local Internal = Input.Internal

function Input.CompleteFactRequest(request)
    local view = request and request.view or nil
    local session = request and request.session or nil
    local requestID = tostring(request and request.requestID or "")
    local result
    local context
    local localResponse
    local response
    local value
    if not view or not session or requestID == ""
        or view.session ~= session or session.closed == true
        or view.closed == true or view.closing == true
        or tostring(session.semanticFactRequestID or "") ~= requestID
        or type(session.semanticDialoguePending) ~= "table"
        or session.semanticDialoguePending.kind ~= "semantic_fact"
        or tostring(session.semanticDialoguePending.requestID or "")
            ~= requestID
    then
        return false, "stale_fact_request"
    end
    result = session.semanticFactRequestResult
    value = session.semanticFactRequestValue
    if not result or not result.ir or not result.decision then
        return false, "fact_response_unavailable"
    end
    context = Internal.ShallowContext(view)
    if type(Internal.ResolveReferences) == "function" then
        result.ir = Internal.ResolveReferences(
            result.ir,
            session.semanticDialogueState,
            context,
            request.options
        ) or result.ir
    end
    localResponse = PNC.Semantics and PNC.Semantics.LocalResponse or nil
    if localResponse and type(localResponse.Resolve) == "function" then
        response = localResponse.Resolve(
            result.ir,
            session.semanticDialogueState,
            context,
            result.decision.branch
        )
        if type(response) == "table" then
            result.decision.response = response
        end
    end
    session.semanticMemoryTargetID = nil
    session.semanticFactRequestID = nil
    session.semanticFactRequestResult = nil
    session.semanticFactRequestValue = nil
    session.semanticFactRequestRouter = nil
    session.semanticFactRequestOptions = nil
    session.semanticDialoguePending = nil
    if type(Internal.QueueDeterministicResponse) ~= "function" then
        return false, "response_queue_unavailable"
    end
    return Internal.QueueDeterministicResponse(
        view,
        value,
        result,
        nil
    )
end
