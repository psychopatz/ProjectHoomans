-- Semantic click response and observation projection.

local Response = {}
local Payload = require "worker/Conversation_Payload"

local function sliced(values, startIndex)
    local output = {}
    local start = tonumber(startIndex) or 1
    for index = start, #(values or {}) do
        output[#output + 1] = values[index]
    end
    return output
end

local function presentedChoices(view, Values)
    local output = {}
    local choices = view and view.session and view.session.choices or {}
    for _, choice in ipairs(choices) do
        if type(choice) == "table" then
            local source = type(choice.source) == "table"
                and choice.source or {}
            output[#output + 1] = {
                id = choice.id,
                text = Payload.resolve(choice.text),
                enabled = choice.enabled ~= false,
                frame = Values.copy(source.semanticFrame),
                source = Values.copy(source),
            }
        end
    end
    return output
end

function Response.build(context, state)
    local Runtime = state.Runtime
    local Values = state.Values
    local view = state.view
    local frame = state.frame
    local Conversation = state.Conversation
    local classification = state.classification
    local allMessages = sliced(Runtime.queued, state.queuedBefore + 1)
    local newTrace = sliced(Runtime.trace, state.traceBefore + 1)
    local newTransport = sliced(Runtime.transport, state.transportBefore + 1)
    local newTranslations = sliced(
        Runtime.translationLookups,
        state.translationBefore + 1
    )
    local response = {
        ok = true,
        type = "semantic_click",
        input = tostring(frame.textFallback or frame.candidateID or ""),
        accepted = state.accepted == true,
        reason = state.reason,
        result = {
            accepted = state.accepted == true,
            reason = state.reason,
            sequence = state.revision,
            ir = {
                kind = "semantic_click_frame",
                intent = "REQUEST",
                speechAct = "REQUEST",
                subject = "CONVERSATION_TOPIC",
            },
        },
        messages = allMessages,
        trace = newTrace,
        transport = newTransport,
        toolCalls = context.OutputProjection.normalizedToolCalls(
            context, newTrace, newTransport, nil, nil
        ),
        translation = {
            language = context.Translations.currentLanguage(context),
            lookups = newTranslations,
        },
        contextBefore = state.contextBefore,
        contextAfter = context.Conversation.contextSnapshot(
            context, view
        ),
        choiceSurface = Values.copy(
            view.session and view.session.choicePresentationState
        ),
        loadedModules = Runtime.loadedModules,
        conversationBlock = Values.copy(state.projection),
        conversationGraph = Values.copy(Conversation.graphProjection(view)),
    }
    response.transcriptMessages = sliced(
        Runtime.transcript,
        state.transcriptBefore + 1
    )
    response.observation = context.OutputProjection.observation(
        context,
        response,
        view.spec and view.spec.context
    )
    response.observation.choices = presentedChoices(view, Values)
    if (classification.isRootChoice or classification.isGroup
        or classification.isShortcut or classification.isBack)
        and view.semanticSuggestions
    then
        response.observation.suggestions = Values.copy(
            view.semanticSuggestions
        )
        Runtime.lastSuggestionRevision = tonumber(
            view.semanticSuggestions.revision
        ) or Runtime.lastSuggestionRevision
    end
    response.observation.conversationBlock = Values.copy(state.projection)
    response.observation.conversationGraph = Values.copy(
        response.conversationGraph
    )
    response.observation.authoritativeMessages = {}
    for _, message in ipairs(allMessages) do
        if type(message) == "table" and message.speaker == "npc" then
            response.observation.authoritativeMessages[#response.observation.authoritativeMessages + 1] =
                Values.copy(message.payload)
        end
    end
    response.observation.authoritativeMessageCount =
        #response.observation.authoritativeMessages
    if response.observation.suggestions then
        Runtime.lastSuggestionRevision = tonumber(
            response.observation.suggestions.revision
        ) or Runtime.lastSuggestionRevision
    end
    return response
end

return Response

