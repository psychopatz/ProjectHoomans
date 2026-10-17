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
Context.DEFAULT_FLOW_LIMIT = 8
Context.DEFAULT_FLOW_STACK_LIMIT = 4
Context.MAX_TEXT = 160
Context.MAX_TOPIC = 64
Context.MAX_FLOW_ID = 64
Context.MAX_NODE_ID = 64
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

function Context.MakeFlowKey(speakerID, addresseeID)
    speakerID = tostring(speakerID or "player")
    addresseeID = tostring(addresseeID or "npc")
    return speakerID .. "|" .. addresseeID
end

function Context:GetFlowSession(key)
    if type(self.flowSessions) ~= "table" or not key then return nil end
    local copy = self.Internal.CopyValue
    return type(copy) == "function"
        and copy(self.flowSessions[key]) or self.flowSessions[key]
end

function Context:StoreFlowSession(session)
    if type(session) ~= "table" or tostring(session.key or "") == "" then
        return false, "invalid_flow_session"
    end
    self.flowSessions = self.flowSessions or {}
    self.flowOrder = self.flowOrder or {}
    self.maxFlows = math.max(
        1,
        math.floor(tonumber(self.maxFlows) or Context.DEFAULT_FLOW_LIMIT)
    )
    local key = tostring(session.key)
    local existing = self.flowSessions[key] ~= nil
    if not existing then
        while #self.flowOrder >= self.maxFlows do
            local retired = table.remove(self.flowOrder, 1)
            self.flowSessions[retired] = nil
        end
        self.flowOrder[#self.flowOrder + 1] = key
    end
    local copy = self.Internal.CopyValue
    self.flowSessions[key] = type(copy) == "function"
        and copy(session) or session
    return true, self.flowSessions[key]
end

function Context:RemoveFlowSession(key)
    if type(self.flowSessions) ~= "table" or not key then
        return false, "flow_session_missing"
    end
    if self.flowSessions[key] == nil then
        return false, "flow_session_missing"
    end
    self.flowSessions[key] = nil
    for index = #self.flowOrder, 1, -1 do
        if self.flowOrder[index] == key then table.remove(self.flowOrder, index) end
    end
    return true
end

function Context:FlowSnapshot()
    local output = {}
    local copy = self.Internal.CopyValue
    for index = 1, #(self.flowOrder or {}) do
        local key = self.flowOrder[index]
        local session = self.flowSessions and self.flowSessions[key]
        if session then
            output[#output + 1] = type(copy) == "function"
                and copy(session) or session
        end
    end
    return output
end

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
        maxFlows = math.max(1, math.floor(
            tonumber(spec.maxFlows) or Context.DEFAULT_FLOW_LIMIT
        )),
        maxFlowStack = math.max(1, math.floor(
            tonumber(spec.maxFlowStack) or Context.DEFAULT_FLOW_STACK_LIMIT
        )),
        currentTopic = topicValue(spec.currentTopic),
        previousTopic = topicValue(spec.previousTopic),
        lastIntent = spec.lastIntent,
        lastAction = spec.lastAction,
        lastSpeaker = spec.lastSpeaker,
        pendingIdentityExchange = spec.pendingIdentityExchange,
        sequence = tonumber(spec.sequence) or 0,
        turns = {},
        mentionOrder = {},
        focusKeys = {},
        mentionsByKey = {},
        flowSessions = {},
        flowOrder = {},
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
    self.pendingIdentityExchange = nil
    self.sequence = 0
    self.turns = {}
    self.mentionOrder = {}
    self.focusKeys = {}
    self.mentionsByKey = {}
    self.flowSessions = {}
    self.flowOrder = {}
    return self
end

return Context
