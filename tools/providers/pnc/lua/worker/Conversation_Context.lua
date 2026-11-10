-- Context exports for the semantic conversation façade.

local Context = {}
local Builder = require "worker/Conversation_Context_Builder"
local Refresh = require "worker/Conversation_Context_Refresh"

Context.buildContext = function(context)
    local output = Builder.build(context)
    local runtime = context.Runtime or {}
    local scenario = runtime.scenario or {}
    if type(scenario.campSiteCandidates) == "table" then
        output.campSiteCandidates = scenario.campSiteCandidates
    end
    if type(scenario.campfireCandidates) == "table" then
        output.campfireCandidates = scenario.campfireCandidates
    end
    if type(scenario.locationObservation) == "table" then
        output.locationObservation = scenario.locationObservation
    end
    return output
end
Context.refreshViewContext = function(context, Conversation)
    return Refresh.apply(context, Conversation)
end

return Context
