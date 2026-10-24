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
    elseif command == "TALK_MATRIX" then
        return Talk.matrix(context, payload)
    end
    return false
end

return Talk
