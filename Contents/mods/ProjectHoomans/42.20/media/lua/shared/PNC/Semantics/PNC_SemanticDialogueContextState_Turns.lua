-- Semantic turn recording for bounded dialogue context.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Context = PNC.Semantics.DialogueContextState
local Internal = Context.Internal

local function topicFor(ir, options)
    local topic = type(options) == "table" and options.topic or nil
    if topic == nil and type(ir) == "table" then
        local extensions = type(ir.extensions) == "table"
            and ir.extensions or nil
        topic = extensions and extensions.topic or nil
        topic = topic or ir.action or ir.subject
        if topic == nil and type(ir.object) == "table" then
            topic = ir.object.category or ir.object.concept
        end
        topic = topic or ir.intent
    end
    return Internal.TopicValue(topic)
end

Internal.TopicFor = topicFor

local function recordMentionList(self, values, options, event)
    if type(values) ~= "table" then return end
    local index
    local recorded
    local mention
    for index = 1, #values do
        recorded, mention = self:RecordMention(values[index], options)
        if recorded == true and mention and event then
            event.mentionKeys[#event.mentionKeys + 1] = mention.key
        end
    end
end

function Context:RecordTurn(ir, options)
    options = type(options) == "table" and options or {}
    if type(ir) ~= "table" then return false, "invalid_ir" end

    self.sequence = self.sequence + 1
    local sequence = self.sequence
    local timestamp = options.timestamp or Internal.TimestampValue(options)
    local topic = topicFor(ir, options)
    if topic then self:SetTopic(topic) end
    self.lastIntent = ir.intent or ir.speechAct
    self.lastAction = ir.action
    self.lastSpeaker = options.speaker or ir.speaker

    -- Identity questions create a bounded, conversation-local obligation.
    -- The next turn can answer it with a self-name claim; any other turn is
    -- observable as an evasion before the state is advanced again.
    if ir.intent == "QUESTION" and ir.subject == "IDENTITY" then
        self.pendingIdentityExchange = {
            kind = "PLAYER_NAME",
            requestedAt = sequence,
        }
    elseif self.pendingIdentityExchange then
        self.pendingIdentityExchange = nil
    end

    local event = {
        sequence = sequence,
        timestamp = timestamp,
        speaker = self.lastSpeaker,
        intent = ir.intent,
        speechAct = ir.speechAct,
        action = ir.action,
        subject = ir.subject,
        topic = topic or self.currentTopic,
        confidence = tonumber(ir.confidence) or 0,
        rawText = Internal.TextValue(ir.rawText),
        mentionKeys = {},
    }

    local fields = {
        { value = ir.actor, role = "actor" },
        { value = ir.recipient, role = "recipient" },
        { value = ir.target, role = "target" },
        { value = ir.object, role = "object" },
        { value = ir.source, role = "source" },
        { value = ir.destination, role = "destination" },
    }
    local index
    local field
    for index = 1, #fields do
        field = fields[index]
        if type(field.value) == "table" then
            local recorded, mention = self:RecordMention(field.value, {
                turn = sequence,
                timestamp = timestamp,
                source = options.source or "semantic_turn",
                role = field.role,
                topic = topic or self.currentTopic,
            })
            if recorded == true and mention then
                event.mentionKeys[#event.mentionKeys + 1] = mention.key
            end
        end
    end

    local extensions = type(ir.extensions) == "table" and ir.extensions or {}
    local mentionOptions = {
        turn = sequence,
        timestamp = timestamp,
        source = options.source,
        role = "mention",
        topic = topic or self.currentTopic,
    }
    recordMentionList(self, ir.mentions, mentionOptions, event)
    recordMentionList(
        self,
        extensions.semanticMentions or extensions.mentions,
        mentionOptions,
        event
    )
    recordMentionList(self, options.mentions, mentionOptions, event)

    self.turns[#self.turns + 1] = event
    while #self.turns > self.maxTurns do table.remove(self.turns, 1) end
    return true, Internal.CopyValue(event)
end

Context.Record = Context.RecordTurn

return Context
