-- Headless conversation view construction.

local View = {}
local Session = require "worker/Conversation_Session"
local Spec = require "worker/Conversation_View_Spec"
local Root = require "worker/Conversation_View_Root"
local Finalize = require "worker/Conversation_View_Finalize"

function View.build(context, Conversation)
    local Runtime = context.Runtime
    local Values = context.Values
    local scenario = Runtime.scenario or {}
    local npc = scenario.npc or {}
    local player = scenario.player or {}
    local session = Session.new(Runtime, Values, player)
    local spec = Spec.build(context, Conversation, scenario, npc)
    local root = Root.resolve(context, spec, scenario, npc, player)
    if root then
        spec.nodes.greeting = root
        spec.nodes.menu = { choices = root.choices or {} }
    end
    local view = {
        headless = true,
        lifecycleFinished = false,
        spec = spec,
        session = session,
    }
    return Finalize.apply(context, Conversation, view, session, spec)
end

return View
