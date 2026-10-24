-- Node entry, choice selection, and pending-transition operations.

local Navigation = {}
local Payload = require "worker/Conversation_Payload"

function Navigation.enterNode(self, nodeID)
    self.currentNodeID = tostring(nodeID or "")
    self.semanticConversationVisitedNodes[
        self.currentNodeID
    ] = true
    self.currentNode = self.spec
        and self.spec.nodes
        and self.spec.nodes[self.currentNodeID] or nil
    self:clearChoices("enter_node")
    self:setChoices(self.currentNode and self.currentNode.choices or {})
    local node = self.currentNode
    if node and node.npc then
        local text = Payload.resolve(node.npc)
        self:append("npc", {
            key = "conversation.node." .. self.currentNodeID,
            text = text,
            fallback = text,
            nodeID = self.currentNodeID,
        }, { conversationNode = true })
    end
    return self.currentNode ~= nil
end

function Navigation.selectChoice(self, choice)
    if self.busy or not choice or choice.enabled == false then
        return false
    end
    self:clearChoices("select_choice")
    if choice.log ~= false then
        self:append("player", Payload.resolve(choice.text))
    end
    if type(choice.action) == "function" then
        choice.action(self.context, choice, self)
    end
    local response = choice.response
    if type(response) == "function" then
        response = response(self.context, choice, self)
    end
    if response then self:queueMessage("npc", response) end
    self.pendingNext = choice.next
    self.pendingClose = choice.close == true
    self.pendingCloseReason = choice.closeReason
    if #self.queue == 0 then self:finishPending() end
    return true
end

function Navigation.finishPending(self)
    self.pendingFinished = true
    if self.pendingClose == true then
        self.lifecycleFinished = true
        self.pendingClose = nil
        self.pendingNext = nil
        self.pendingChoices = nil
        return true
    end
    if self.pendingNext then
        local nextNode = self.pendingNext
        self.pendingNext = nil
        self:enterNode(nextNode)
        return true
    end
    if self.pendingChoices then
        local choices = self.pendingChoices
        self.pendingChoices = nil
        self:setChoices(choices)
    end
    return true
end

return Navigation

