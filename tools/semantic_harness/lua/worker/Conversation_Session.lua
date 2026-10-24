-- Composes the headless conversation session state machine.

local Session = {}
local Messages = require "worker/Conversation_Session_Messages"
local Choices = require "worker/Conversation_Session_Choices"
local Navigation = require "worker/Conversation_Session_Navigation"

function Session.new(Runtime, Values, player)
    local session = {
        _runtime = Runtime,
        _values = Values,
        characterUUID = player.characterUUID,
        conversationID = "harness-conversation",
        queue = {},
        currentNodeID = "menu",
        currentNode = nil,
        semanticConversationVisitedNodes = {},
        spec = nil,
        view = nil,
    }
    session.append = Messages.append
    session.queueMessage = Messages.queueMessage
    session.setPresentedChoices = Choices.setPresentedChoices
    session.clearChoices = Choices.clearChoices
    session.setChoices = Choices.setChoices
    session.enterNode = Navigation.enterNode
    session.selectChoice = Navigation.selectChoice
    session.finishPending = Navigation.finishPending
    return session
end

return Session
