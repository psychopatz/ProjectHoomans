-- Stable semantic contract for Conversation speech presentation.
--
-- Semantic delivery owns payload construction and deduplication. Conversation
-- owns the world/UI presentation sink and binds it after the presentation
-- modules are composed.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Provider = PNC.Semantics.ConversationSpeechProvider or {}
PNC.Semantics.ConversationSpeechProvider = Provider

Provider.VERSION = 1

function Provider.Bind(implementation)
    if type(implementation) ~= "table"
        or type(implementation.Receive) ~= "function"
    then
        return false, "invalid_conversation_speech_provider"
    end
    Provider.Implementation = implementation
    return true
end

function Provider.IsBound()
    local implementation = Provider.Implementation
    return type(implementation) == "table"
        and type(implementation.Receive) == "function"
end

function Provider.Receive(ambientFlavor, summary, networkArgs)
    local implementation = Provider.Implementation
    if not implementation then
        return false, "conversation_speech_presentation_unavailable"
    end
    return implementation.Receive(ambientFlavor, summary, networkArgs)
end

return Provider
