-- Public conversation façade assembled from cohesive semantic-harness modules.

local Conversation = {}
local Context = require "worker/Conversation_Context"
local Projection = require "worker/Conversation_Projection"
local Execution = require "worker/Conversation_Execution"

Conversation.buildContext = Context.buildContext
Conversation.refreshViewContext = function(context)
    return Context.refreshViewContext(context, Conversation)
end
Conversation.blockProjection = Projection.blockProjection
Conversation.graphProjection = Projection.graphProjection
Conversation.buildView = function(context)
    return Projection.buildView(context, Conversation)
end
Conversation.relationshipSnapshot = Projection.relationshipSnapshot
Conversation.contextSnapshot = Projection.contextSnapshot
Conversation.turn = function(context, text)
    return Execution.turn(context, text, Conversation)
end
Conversation.semanticClick = function(context, frame)
    return Execution.semanticClick(context, frame, Conversation)
end
Conversation.preview = function(context, text)
    return Execution.preview(context, text, Conversation)
end

return Conversation
