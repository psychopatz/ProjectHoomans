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
Context.DEFAULT_AGENDA_LIMIT = 8
Context.DEFAULT_TOPIC_HISTORY_LIMIT = 4
Context.MAX_TEXT = 160
Context.MAX_TOPIC = 64
Context.MAX_AGENDA_ID = 64
Context.MAX_AGENDA_KIND = 32
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

local function boundedText(value, maximum)
    value = tostring(value or "")
    maximum = tonumber(maximum) or Context.MAX_TEXT
    if #value > maximum then return string.sub(value, 1, maximum) end
    return value ~= "" and value or nil
end

local function copyValue(value)
    local copy = Context.Internal.CopyValue
    return type(copy) == "function" and copy(value) or value
end

local function compactList(values, maximum)
    if type(values) ~= "table" then return nil end
    local output = {}
    for index = 1, math.min(#values, maximum or 4) do
        local value = boundedText(values[index], Context.MAX_AGENDA_KIND)
        if value then output[#output + 1] = value end
    end
    return #output > 0 and output or nil
end

local function agendaEntry(spec, sequence)
    if type(spec) ~= "table" then return nil, "invalid_follow_up" end
    local kind = string.upper(tostring(spec.kind or "QUESTION"))
    if #kind == 0 or #kind > Context.MAX_AGENDA_KIND then
        return nil, "invalid_follow_up_kind"
    end
    local topic = topicValue(spec.topic)
    if not topic then return nil, "invalid_follow_up_topic" end
    local id = boundedText(spec.id, Context.MAX_AGENDA_ID)
        or string.sub("follow_up:" .. kind .. ":" .. tostring(sequence), 1,
            Context.MAX_AGENDA_ID)
    local output = {
        id = id,
        kind = kind,
        topic = topic,
        owner = boundedText(spec.owner, Context.MAX_AGENDA_KIND),
        targetID = boundedText(spec.targetID, Context.MAX_AGENDA_ID),
        flowID = boundedText(spec.flowID, Context.MAX_FLOW_ID),
        nodeID = boundedText(spec.nodeID, Context.MAX_NODE_ID),
        requiredSlots = compactList(spec.requiredSlots, 8),
        sourceFactRefs = compactList(spec.sourceFactRefs, 8),
        openedTurn = tonumber(spec.openedTurn) or sequence,
        status = boundedText(spec.status, Context.MAX_AGENDA_KIND) or "open",
    }
    return output
end

Context.Internal.AgendaEntry = agendaEntry

function Context:GetPendingFollowUp()
    return self.pendingFollowUp and copyValue(self.pendingFollowUp) or nil
end

function Context:SetPendingFollowUp(spec)
    local entry, reason = agendaEntry(spec, self.sequence)
    if not entry then return false, reason end
    self.agenda = self.agenda or {}
    local existing
    for index = 1, #self.agenda do
        if self.agenda[index].id == entry.id then
            existing = index
            break
        end
    end
    if existing then
        self.agenda[existing] = entry
    else
        self.agenda[#self.agenda + 1] = entry
    end
    while #self.agenda > (self.maxAgenda or Context.DEFAULT_AGENDA_LIMIT) do
        table.remove(self.agenda, 1)
    end
    self.pendingFollowUp = copyValue(entry)
    return true, copyValue(entry)
end

function Context:CompletePendingFollowUp(status, reason)
    local pending = self.pendingFollowUp
    if type(pending) ~= "table" then return false, "no_pending_follow_up" end
    status = boundedText(status, Context.MAX_AGENDA_KIND) or "fulfilled"
    pending.status = status
    pending.closedTurn = self.sequence
    pending.resolutionReason = boundedText(reason, Context.MAX_TEXT)
    for index = #self.agenda, 1, -1 do
        if self.agenda[index].id == pending.id then
            self.agenda[index] = copyValue(pending)
            break
        end
    end
    self.lastFollowUp = copyValue(pending)
    self.pendingFollowUp = nil
    return true, copyValue(pending)
end

function Context:AgendaSnapshot(limit)
    local maximum = math.min(
        #self.agenda,
        math.max(0, math.floor(tonumber(limit) or #self.agenda))
    )
    local output = {}
    for index = 1, maximum do
        output[index] = copyValue(self.agenda[index])
    end
    return output
end

function Context:RememberTopic(topic, reason)
    topic = topicValue(topic)
    if not topic then return false, "invalid_topic" end
    self.priorTopics = self.priorTopics or {}
    local previous = self.priorTopics[1]
    if previous and previous.topic == topic then return true, "unchanged" end
    table.insert(self.priorTopics, 1, {
        topic = topic,
        reason = boundedText(reason, Context.MAX_AGENDA_KIND) or "interruption",
        turn = self.sequence,
    })
    while #self.priorTopics > (self.maxTopicHistory
        or Context.DEFAULT_TOPIC_HISTORY_LIMIT)
    do
        table.remove(self.priorTopics)
    end
    return true, topic
end

function Context:SetTopic(topic, preservePrevious)
    topic = topicValue(topic)
    if not topic then return false, "invalid_topic" end
    if self.currentTopic == topic then return true, "unchanged" end
    if preservePrevious ~= false then
        self.previousTopic = self.currentTopic
        if self.currentTopic then
            self:RememberTopic(self.currentTopic, "topic_interruption")
        end
    end
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
        maxAgenda = math.max(1, math.floor(
            tonumber(spec.maxAgenda) or Context.DEFAULT_AGENDA_LIMIT
        )),
        maxTopicHistory = math.max(1, math.floor(
            tonumber(spec.maxTopicHistory)
                or Context.DEFAULT_TOPIC_HISTORY_LIMIT
        )),
        currentTopic = topicValue(spec.currentTopic),
        previousTopic = topicValue(spec.previousTopic),
        priorTopics = copyValue(spec.priorTopics) or {},
        lastIntent = spec.lastIntent,
        lastAction = spec.lastAction,
        lastSpeaker = spec.lastSpeaker,
        pendingIdentityExchange = spec.pendingIdentityExchange,
        pendingFollowUp = copyValue(spec.pendingFollowUp),
        lastFollowUp = copyValue(spec.lastFollowUp),
        agenda = copyValue(spec.agenda) or {},
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
    self.priorTopics = {}
    self.lastIntent = nil
    self.lastAction = nil
    self.lastSpeaker = nil
    self.pendingIdentityExchange = nil
    self.pendingFollowUp = nil
    self.lastFollowUp = nil
    self.agenda = {}
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
