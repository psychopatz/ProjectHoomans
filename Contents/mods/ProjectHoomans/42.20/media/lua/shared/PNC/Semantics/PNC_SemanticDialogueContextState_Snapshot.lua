-- Safe bounded projections of semantic dialogue context.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Context = PNC.Semantics.DialogueContextState
local copyValue = Context.Internal.CopyValue

function Context:GetMentions(limit)
    local maximum = math.min(
        #self.mentionOrder,
        math.max(0, math.floor(tonumber(limit) or #self.mentionOrder))
    )
    local output = {}
    local index
    local key
    for index = 1, maximum do
        key = self.mentionOrder[index]
        if self.mentionsByKey[key] then
            output[#output + 1] = copyValue(self.mentionsByKey[key])
        end
    end
    return output
end

function Context:GetFocus(limit)
    local maximum = math.min(
        #self.focusKeys,
        math.max(0, math.floor(tonumber(limit) or #self.focusKeys))
    )
    local output = {}
    local index
    local key
    for index = 1, maximum do
        key = self.focusKeys[index]
        if self.mentionsByKey[key] then
            output[#output + 1] = copyValue(self.mentionsByKey[key])
        end
    end
    return output
end

function Context:FindMention(key)
    return key and copyValue(self.mentionsByKey[key]) or nil
end

function Context:RecentTurns(limit, newestFirst)
    local maximum = math.min(
        #self.turns,
        math.max(0, math.floor(tonumber(limit) or #self.turns))
    )
    local output = {}
    local index
    if newestFirst == false then
        for index = 1, maximum do output[index] = copyValue(self.turns[index]) end
        return output
    end
    for index = 1, maximum do
        output[index] = copyValue(
            self.turns[#self.turns - index + 1]
        )
    end
    return output
end

function Context:ToContext()
    return {
        version = self.version,
        currentTopic = self.currentTopic,
        previousTopic = self.previousTopic,
        lastIntent = self.lastIntent,
        lastAction = self.lastAction,
        lastSpeaker = self.lastSpeaker,
        pendingIdentityExchange = self.pendingIdentityExchange,
        sequence = self.sequence,
        recentTurns = self:RecentTurns(6, true),
        focus = self:GetFocus(self.maxFocus),
        mentions = self:GetMentions(self.maxMentions),
    }
end

function Context:Snapshot()
    local output = self:ToContext()
    output.maxTurns = self.maxTurns
    output.maxMentions = self.maxMentions
    output.maxFocus = self.maxFocus
    return output
end

return Context
