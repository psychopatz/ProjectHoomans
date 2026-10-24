-- Message and transcript operations for a headless conversation session.

local Messages = {}
local Payload = require "worker/Conversation_Payload"

function Messages.append(self, speaker, value, metadata)
    local Runtime = self._runtime
    local Values = self._values
    local message = {
        speaker = speaker,
        value = value,
        metadata = Values.copy(metadata),
    }
    self.lastAppend = message
    Runtime.transcript[#Runtime.transcript + 1] = message
    if speaker == "npc" then
        Runtime.queued[#Runtime.queued + 1] = {
            speaker = speaker,
            payload = Values.copy(value),
            metadata = Values.copy(metadata),
        }
    end
    return { messageID = "harness-message-" .. tostring(#Runtime.transcript) }
end

function Messages.queueMessage(self, speaker, payload, metadata)
    local Runtime = self._runtime
    local Values = self._values
    local storedPayload = Values.copy(payload)
    if type(storedPayload) == "table"
        and storedPayload.text == nil
        and storedPayload.fallback == nil
    then
        local resolved = Payload.resolve(storedPayload)
        if resolved ~= "" then
            storedPayload.text = resolved
            storedPayload.fallback = resolved
        end
    end
    local message = {
        speaker = speaker,
        payload = storedPayload,
        metadata = Values.copy(metadata),
    }
    self.lastQueued = message
    Runtime.queued[#Runtime.queued + 1] = message
    Runtime.transcript[#Runtime.transcript + 1] = message
end

return Messages

