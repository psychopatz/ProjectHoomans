-- Stable semantic contract for read-only Conversation memory access.
--
-- Semantic fact providers may be loaded before Conversation memory during
-- shared composition. Keep the implementation binding late and fail closed
-- until Conversation registers its memory table.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Provider = PNC.Semantics.ConversationMemoryProvider or {}
PNC.Semantics.ConversationMemoryProvider = Provider
Provider.Events = Provider.Events or {}

Provider.VERSION = 1

function Provider.Bind(implementation)
    if type(implementation) ~= "table"
        or type(implementation.GetBackstory) ~= "function"
        or type(implementation.GetBackstoryText) ~= "function"
    then
        return false, "invalid_conversation_memory_provider"
    end
    Provider.Implementation = implementation
    Provider.Events = implementation.Events or {}
    return true
end

function Provider.IsBound()
    local implementation = Provider.Implementation
    return type(implementation) == "table"
        and type(implementation.GetBackstory) == "function"
        and type(implementation.GetBackstoryText) == "function"
end

function Provider.GetBackstory(record, kind)
    local implementation = Provider.Implementation
    if not implementation then return nil end
    return implementation.GetBackstory(record, kind)
end

function Provider.GetBackstoryText(backstory, language)
    local implementation = Provider.Implementation
    if not implementation then return nil end
    return implementation.GetBackstoryText(backstory, language)
end

function Provider.RenderText(template, arguments)
    local implementation = Provider.Implementation
    if not implementation
        or type(implementation.RenderText) ~= "function"
    then
        return template
    end
    return implementation.RenderText(template, arguments)
end

function Provider.AccumulateConversationTopics(session, ir, rawText)
    local implementation = Provider.Implementation
    local events = implementation and implementation.Events or nil
    if not events
        or type(events.AccumulateConversationTopics) ~= "function"
    then
        return false, "conversation_memory_events_unavailable"
    end
    return events.AccumulateConversationTopics(session, ir, rawText)
end

function Provider.GetGossipTemplateByCode(code)
    local implementation = Provider.Implementation
    if not implementation
        or type(implementation.GetGossipTemplateByCode) ~= "function"
    then
        return nil
    end
    return implementation.GetGossipTemplateByCode(code)
end

function Provider.BuildGossipPacket(code, options)
    local implementation = Provider.Implementation
    if not implementation
        or type(implementation.BuildGossipPacket) ~= "function"
    then
        return nil
    end
    return implementation.BuildGossipPacket(code, options)
end

function Provider.RenderGossipPacket(packet)
    local implementation = Provider.Implementation
    if not implementation
        or type(implementation.RenderGossipPacket) ~= "function"
    then
        return nil
    end
    return implementation.RenderGossipPacket(packet)
end

return Provider
