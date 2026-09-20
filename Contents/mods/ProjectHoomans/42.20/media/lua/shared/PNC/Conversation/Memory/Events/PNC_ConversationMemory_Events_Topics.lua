-- Bounded text and IR classifier for current conversation topics.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Memory = PNC.Conversation.Memory
local Events = Memory.Events
local Data = Memory._registry
local Internal = Events.Internal
local normalizedWords = Internal.NormalizeConversationTopicText
local hasBit = Internal.HasConversationTopicBit
local addBit = Internal.AddConversationTopicBit
local MAX_TOPIC_BITS = Events.TOPIC_BIT_LIMIT
local MAX_MATCH_TEXT = 160
local MAX_TOPIC_HISTORY_MESSAGES = 64
local DEFAULT_TOPIC_HISTORY_MESSAGES = 16

local function topicMaskForText(value)
    local words = normalizedWords(value)
    local padded
    local output = 0
    local bit
    local topic
    local aliasIndex
    if not words then return 0 end
    if #words > MAX_MATCH_TEXT then
        words = string.sub(words, 1, MAX_MATCH_TEXT)
        words = string.gsub(words, "%s+$", "")
    end
    padded = " " .. words .. " "
    for bit = 1, MAX_TOPIC_BITS do
        topic = Data.conversationTopicByBit[bit]
        if topic then
            for aliasIndex = 1, #topic.aliases do
                if string.find(
                    padded,
                    " " .. topic.aliases[aliasIndex] .. " ",
                    1,
                    true
                ) then
                    output = addBit(output, bit)
                    break
                end
            end
        end
    end
    return output
end

local CANDIDATE_FIELDS = {
    "id", "key", "name", "text", "value", "category", "concept",
    "type", "kind", "fullType",
}

local function inspectValue(value)
    local output = 0
    local index
    if type(value) == "string" or type(value) == "number" then
        return topicMaskForText(value)
    end
    if type(value) ~= "table" then return output end
    for index = 1, #CANDIDATE_FIELDS do
        output = Events.MergeConversationTopicMasks(
            output,
            topicMaskForText(value[CANDIDATE_FIELDS[index]])
        )
    end
    return output
end

local function inspectList(values, output)
    local index
    if type(values) ~= "table" then return output end
    for index = 1, math.min(#values, 16) do
        output = Events.MergeConversationTopicMasks(
            output,
            inspectValue(values[index])
        )
    end
    return output
end

function Events.TopicMaskFromIR(ir, rawText)
    local output = 0
    local fields = {
        "intent", "speechAct", "action", "subject", "topic",
        "normalizedText", "rawText", "actor", "recipient", "target",
        "object", "source", "destination",
    }
    local index
    local extensions
    if type(ir) == "table" then
        for index = 1, #fields do
            output = Events.MergeConversationTopicMasks(
                output,
                inspectValue(ir[fields[index]])
            )
        end
        extensions = type(ir.extensions) == "table" and ir.extensions or nil
        if extensions then
            output = Events.MergeConversationTopicMasks(
                output,
                inspectValue(extensions.topic)
            )
            output = Events.MergeConversationTopicMasks(
                output,
                inspectValue(extensions.category)
            )
            output = inspectList(extensions.semanticMentions, output)
            output = inspectList(extensions.mentions, output)
        end
        output = inspectList(ir.mentions, output)
    end
    output = Events.MergeConversationTopicMasks(
        output,
        topicMaskForText(rawText)
    )
    return Events.FilterConversationTopicMask(output)
end

function Events.AccumulateConversationTopics(session, ir, rawText)
    if type(session) ~= "table" then return false, "session_unavailable" end
    local mask = Events.TopicMaskFromIR(ir, rawText)
    if mask <= 0 then return false, "no_registered_topic" end
    session.conversationTopicMask = Events.MergeConversationTopicMasks(
        session.conversationTopicMask,
        mask
    )
    return true, session.conversationTopicMask
end

local function messageText(message)
    if type(message) ~= "table" then return nil end
    local content = type(message.text) == "string" and message.text or nil
    if (not content or content == "") and type(message.payload) == "string" then
        content = message.payload
    end
    if not content or content == "" then
        local textResolver = PsychopatzCore
            and PsychopatzCore.Conversation
            and PsychopatzCore.Conversation.Text or nil
        if textResolver and type(textResolver.Resolve) == "function" then
            local ok, resolved = pcall(
                textResolver.Resolve,
                message.payload or message
            )
            if ok and type(resolved) == "string" then
                content = resolved
            end
        end
    end
    if type(content) ~= "string" or content == "" then return nil end
    local source = type(message.source) == "table" and message.source or nil
    if source and (source.providerFailure == true
        or source.excludeFromLLM == true
        or source.contextEligible == false)
    then
        return nil
    end
    return string.sub(content, 1, MAX_MATCH_TEXT)
end

function Events.TopicMaskFromMessages(messages, limit)
    local output = 0
    local maximum = math.max(0, math.min(
        MAX_TOPIC_HISTORY_MESSAGES,
        math.floor(tonumber(limit) or DEFAULT_TOPIC_HISTORY_MESSAGES)
    ))
    local first
    local index
    local content
    if type(messages) ~= "table" or maximum <= 0 then return output end
    first = math.max(1, #messages - maximum + 1)
    for index = first, #messages do
        content = messageText(messages[index])
        if content then
            output = Events.MergeConversationTopicMasks(
                output,
                topicMaskForText(content)
            )
        end
    end
    return Events.FilterConversationTopicMask(output)
end

function Events.GetConversationTopicMask(session, historyLimit)
    if type(session) ~= "table" or session.closed == true
        or session.conversationMemoryClosed == true
    then
        return 0
    end
    local mask = Events.FilterConversationTopicMask(
        session.conversationTopicMask
    )
    local view = session.view
    local history = view and view.historyPart
        and view.historyPart.messages or nil
    if type(history) == "table" then
        mask = Events.MergeConversationTopicMasks(
            mask,
            Events.TopicMaskFromMessages(
                history,
                historyLimit or DEFAULT_TOPIC_HISTORY_MESSAGES
            )
        )
    end
    return Events.FilterConversationTopicMask(mask)
end

return Events
