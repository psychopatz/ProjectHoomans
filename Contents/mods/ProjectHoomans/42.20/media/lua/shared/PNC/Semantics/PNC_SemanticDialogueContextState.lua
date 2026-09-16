-- Entry point for bounded semantic dialogue context.
--
-- Core.DialogueState remains the compact semantic event history. The spokes
-- below own mentions, turn recording, and safe projections separately.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Context = PNC.Semantics.DialogueContextState or {}
PNC.Semantics.DialogueContextState = Context

Context.VERSION = 1
Context.DEFAULT_TURN_LIMIT = 12
Context.DEFAULT_MENTION_LIMIT = 32
Context.DEFAULT_FOCUS_LIMIT = 8
Context.MAX_TEXT = 160
Context.MAX_TOPIC = 64
Context.MAX_METADATA_DEPTH = 6
Context.Internal = Context.Internal or {}

local function topicValue(value)
    if type(value) == "table" then
        value = value.id or value.key or value.name
    end
    value = tostring(value or "")
    if #value > Context.MAX_TOPIC then
        value = string.sub(value, 1, Context.MAX_TOPIC)
    end
    return value ~= "" and value or nil
end

Context.Internal.TopicValue = topicValue

function Context:SetTopic(topic, preservePrevious)
    topic = topicValue(topic)
    if not topic then return false, "invalid_topic" end
    if self.currentTopic == topic then return true, "unchanged" end
    if preservePrevious ~= false then self.previousTopic = self.currentTopic end
    self.currentTopic = topic
    return true, topic
end

require "PNC/Semantics/PNC_SemanticDialogueContextState_Mentions"
require "PNC/Semantics/PNC_SemanticDialogueContextState_Turns"
require "PNC/Semantics/PNC_SemanticDialogueContextState_Snapshot"

function Context.New(spec)
    spec = type(spec) == "table" and spec or {}
    local self = {
        version = Context.VERSION,
        maxTurns = math.max(1, math.floor(
            tonumber(spec.maxTurns) or Context.DEFAULT_TURN_LIMIT
        )),
        maxMentions = math.max(1, math.floor(
            tonumber(spec.maxMentions) or Context.DEFAULT_MENTION_LIMIT
        )),
        maxFocus = math.max(1, math.floor(
            tonumber(spec.maxFocus) or Context.DEFAULT_FOCUS_LIMIT
        )),
        currentTopic = topicValue(spec.currentTopic),
        previousTopic = topicValue(spec.previousTopic),
        lastIntent = spec.lastIntent,
        lastAction = spec.lastAction,
        lastSpeaker = spec.lastSpeaker,
        sequence = tonumber(spec.sequence) or 0,
        turns = {},
        mentionOrder = {},
        focusKeys = {},
        mentionsByKey = {},
    }
    setmetatable(self, { __index = Context })
    return self
end

function Context:Reset()
    self.currentTopic = nil
    self.previousTopic = nil
    self.lastIntent = nil
    self.lastAction = nil
    self.lastSpeaker = nil
    self.sequence = 0
    self.turns = {}
    self.mentionOrder = {}
    self.focusKeys = {}
    self.mentionsByKey = {}
    return self
end

return Context
