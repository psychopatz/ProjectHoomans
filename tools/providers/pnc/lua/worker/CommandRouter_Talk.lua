-- Native Talk parity operations for the semantic worker router.

local TalkParity = PNC.Conversation
    and PNC.Conversation.TalkParity
    or require "PNC/Conversation/PNC_ConversationTalkParity"

local Talk = {}

function Talk.catalog()
    return {
        schema = "semantic.talk.catalog.v1",
        targets = TalkParity.GetCatalog(),
    }
end

function Talk.start(context, payload)
    payload = type(payload) == "table" and payload or {}
    local result, reason = TalkParity.Start(
        context,
        payload.targetID or payload.target or "current",
        payload.utterance or "hello"
    )
    if not result then return nil, reason end
    return result
end

function Talk.open(context, payload)
    payload = type(payload) == "table" and payload or {}
    local result, reason = TalkParity.Open(
        context, payload.targetID or payload.target or "current"
    )
    if not result then return nil, reason end
    return result
end

function Talk.suspend(context)
    local result, reason = TalkParity.Suspend(context)
    if not result then return nil, reason end
    return result
end

function Talk.resume(context)
    local result, reason = TalkParity.Resume(context)
    if not result then return nil, reason end
    return result
end

function Talk.close(context, payload)
    payload = type(payload) == "table" and payload or {}
    local result, reason = TalkParity.Close(
        context, payload.reason or "conversation_closed"
    )
    if not result then return nil, reason end
    return result
end

function Talk.emote(context, payload)
    local result, reason = TalkParity.Emote(context, payload)
    if not result then return nil, reason end
    return result
end

function Talk.matrix(context, payload)
    return TalkParity.Matrix(context, payload)
end

function Talk.handle(context, command, payload)
    local Runtime = context.Runtime
    local Values = context.Values

    if command == "TALK_CATALOG" then
        return {
            ok = true,
            type = "talk_catalog",
            schema = "semantic.talk.catalog.v1",
            targets = Talk.catalog().targets,
        }
    elseif command == "TALK_START" then
        payload = type(payload) == "table" and payload or {}
        return Talk.start(context, payload)
    elseif command == "CONVERSATION_OPEN"
        or command == "TALK_OPEN"
    then
        payload = type(payload) == "table" and payload or {}
        return Talk.open(context, payload)
    elseif command == "CONVERSATION_SUSPEND"
        or command == "TALK_SUSPEND"
    then
        return Talk.suspend(context)
    elseif command == "CONVERSATION_RESUME"
        or command == "TALK_RESUME"
    then
        return Talk.resume(context)
    elseif command == "CONVERSATION_CLOSE"
        or command == "TALK_CLOSE"
    then
        return Talk.close(context, payload)
    elseif command == "CONVERSATION_EMOTE"
        or command == "TALK_EMOTE"
    then
        return Talk.emote(context, payload)
    elseif command == "TALK_MATRIX" then
        return Talk.matrix(context, payload)
    end
    return false
end

return Talk
