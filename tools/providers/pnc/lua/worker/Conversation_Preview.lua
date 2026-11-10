-- Pure conversation preview execution.

local Preview = {}

function Preview.run(context, text, Conversation)
    local Runtime = context.Runtime
    local Values = context.Values
    local view = Runtime.view
    local Input = PNC.Semantics and PNC.Semantics.DialogueInput or nil
    local Internal = Input and Input.Internal or {}
    local router, routerReason
    if type(Internal.RouterFor) == "function" then
        router, routerReason = Internal.RouterFor(view)
    end
    if not router then
        return {
            ok = true,
            type = "preview",
            input = text,
            accepted = false,
            reason = routerReason or "conversation_unavailable",
            contextBefore = Conversation.contextSnapshot(context, view),
            contextAfter = Conversation.contextSnapshot(context, view),
            messages = {},
            trace = {},
            transport = {},
            toolCalls = {},
            llmCalls = Runtime.llmCalls,
        }
    end

    local value = tostring(text or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    value = string.sub(value, 1, Input.MAX_INPUT_LENGTH)
    local contextBefore = Conversation.contextSnapshot(context, view)
    local relationshipBefore = Conversation.relationshipSnapshot(context)
    local traceBefore = #Runtime.trace
    local transportBefore = #Runtime.transport
    local translationBefore = #Runtime.translationLookups
    local projection = type(Internal.ShallowContext) == "function"
        and Internal.ShallowContext(view) or {}
    local options = {
        timestamp = type(Internal.Now) == "function" and Internal.Now() or 0,
    }
    local result = router:Preview(value, projection, options)
    if result and result.accepted == true
        and result.ir and type(router.Decide) == "function"
    then
        -- Router:Preview intentionally does not commit a turn. Ask the same
        -- production policy for its pure flow preview so the lab can inspect
        -- generated gates/bindings without recording or dispatching anything.
        local decision = router:Decide(result.ir, projection, options)
        result.decision = decision
        result.flow = decision and decision.flow
    end
    local newTrace = {}
    local newTransport = {}
    local newTranslations = {}
    local index
    for index = traceBefore + 1, #Runtime.trace do
        newTrace[#newTrace + 1] = Values.copy(Runtime.trace[index])
    end
    for index = transportBefore + 1, #Runtime.transport do
        newTransport[#newTransport + 1] = Values.copy(Runtime.transport[index])
    end
    for index = translationBefore + 1, #Runtime.translationLookups do
        newTranslations[#newTranslations + 1] = Values.copy(Runtime.translationLookups[index])
    end
    local toolCalls = context.OutputProjection.normalizedToolCalls(
        context, newTrace, newTransport, result, nil
    )
    local response = {
        ok = true,
        type = "preview",
        input = value,
        accepted = result and result.accepted == true,
        reason = result and result.reason,
        result = result and {
            accepted = result.accepted == true,
            reason = result.reason,
            sequence = result.sequence,
            ir = Values.copy(result.ir),
            decision = Values.copy(result.decision),
            flow = Values.copy(result.flow),
            candidates = Values.copy(result.candidates),
            candidateDiagnostics = Values.copy(result.candidateDiagnostics),
        } or nil,
        messages = {},
        trace = newTrace,
        transport = newTransport,
        toolCalls = toolCalls,
        translation = {
            language = context.Translations.currentLanguage(context),
            lookups = newTranslations,
        },
        relationshipBefore = relationshipBefore,
        relationshipAfter = Conversation.relationshipSnapshot(context),
        contextBefore = contextBefore,
        contextAfter = Conversation.contextSnapshot(context, view),
        routedSituation = Values.copy(projection.dialogueSituation),
        llmCalls = Runtime.llmCalls,
        loadedModules = Runtime.loadedModules,
    }
    response.observation = context.OutputProjection.observation(
        context, response, view.spec and view.spec.context
    )
    return response
end

return Preview

