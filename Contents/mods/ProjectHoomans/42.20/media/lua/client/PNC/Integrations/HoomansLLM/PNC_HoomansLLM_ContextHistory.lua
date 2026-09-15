-- Bounded conversation-history and participant projections.
require "PsychopatzCore/Conversation/PsychopatzConversationMessage"

PNC = PNC or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}
PNC.HoomansLLM.Internal = PNC.HoomansLLM.Internal or {}

local Internal = PNC.HoomansLLM.Internal
local Runtime = Internal.Runtime
local History = Internal.ContextHistory or {}
Internal.ContextHistory = History
local Message = PsychopatzCore.Conversation.Message

function History.CompactParticipants(view, npcID, npcName, playerID, playerName)
    local output = {}
    local seen = {}
    local session = view and view.session or {}
    local values = session.participants or {}
    for index = 1, math.min(#values, 16) do
        local participant = values[index]
        local id = type(participant) == "table"
            and (participant.id or participant.speakerID)
            or participant
        id = Runtime.Trim(id)
        if id ~= "" and not seen[id] then
            seen[id] = true
            output[#output + 1] = {
                id = id,
                name = type(participant) == "table"
                    and (participant.name or participant.speakerName) or id,
                kind = type(participant) == "table"
                    and (participant.kind or participant.speakerKind) or "npc",
                active = type(participant) ~= "table"
                    or participant.active ~= false,
            }
        end
    end
    if not seen[playerID] then
        output[#output + 1] = {
            id = playerID, name = playerName, kind = "player", active = true,
        }
    end
    if not seen[npcID] then
        output[#output + 1] = {
            id = npcID, name = npcName, kind = "npc", active = true,
        }
    end
    return output
end

local function isProviderFailure(message, content)
    local speaker = tostring(message
        and (message.speakerKind or message.speaker) or "")
    if speaker ~= "npc" then return false end

    if Message and Message.IsLLMContextEligible then
        return not Message.IsLLMContextEligible(message, content)
    end

    local source = message and message.source
    if type(source) ~= "table" then source = {} end
    if source.contextEligible == false
        or source.providerFailure == true
        or source.excludeFromLLM == true
    then
        return true
    end

    local lowered = string.lower(tostring(content or ""))
    return string.find(lowered, "i cannot answer right now", 1, true) ~= nil
        or string.find(lowered, "provider request failed", 1, true) ~= nil
        or string.find(lowered, "provider returned an empty response", 1, true) ~= nil
        or string.find(lowered, "openai-compatible provider", 1, true) ~= nil
        or string.find(lowered, "i am an ai assistant", 1, true) ~= nil
        or string.find(lowered, "as an ai", 1, true) ~= nil
        or string.find(lowered, "language model", 1, true) ~= nil
        or string.find(lowered, "personal identity", 1, true) ~= nil
end

function History.Recent(view, currentMessage)
    local history = view and view.historyPart and view.historyPart.messages or {}
    local output = {}
    local first = math.max(1, #history - 7)
    local textResolver = PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.Text
    for index = first, #history do
        local message = history[index]
        local payload = message and (message.payload or message) or nil
        local content = textResolver and textResolver.Resolve
            and textResolver.Resolve(payload) or ""
        content = Runtime.Trim(content)
        if content ~= ""
            and not isProviderFailure(message, content)
            and not (index == #history and content == currentMessage)
        then
            output[#output + 1] = {
                role = message and message.speaker == "player"
                    and "user" or "assistant",
                content = string.sub(content, 1, 500),
            }
        end
    end
    return output
end

return History
