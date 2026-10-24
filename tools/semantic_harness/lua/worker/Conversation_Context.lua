-- Context exports for the semantic conversation façade.

local Context = {}
local Builder = require "worker/Conversation_Context_Builder"
local Refresh = require "worker/Conversation_Context_Refresh"

Context.buildContext = Builder.build
Context.refreshViewContext = function(context, Conversation)
    return Refresh.apply(context, Conversation)
end

return Context
