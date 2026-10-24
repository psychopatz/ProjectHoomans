-- PsychopatzCore compatibility façade used by production modules.

local Core = {}

function Core.configure(context)
    local Runtime = context.Runtime
    local Values = context.Values
    local runtime = context.runtime
    PsychopatzCore = PsychopatzCore or {}
    PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}
    PsychopatzCore.Conversation.Text = PsychopatzCore.Conversation.Text or {}
    if type(PsychopatzCore.Conversation.Text.Resolve) ~= "function" then
        PsychopatzCore.Conversation.Text.Resolve = function(value)
            return value and (value.fallback or value.text) or ""
        end
    end
    if type(PsychopatzCore.Conversation.Text.RegisterFallback) ~= "function" then
        PsychopatzCore.Conversation.Text.RegisterFallback = function(key, value)
            Runtime.fallbacks = Runtime.fallbacks or {}
            Runtime.fallbacks[key] = value
            return value
        end
    end
    PsychopatzCore.RuntimeRole = {
        AllowsServerCode = function() return true end,
        IsPureClient = function() return runtime.mode == "multiplayer" end,
    }
    PsychopatzCore.DebugTrace = {
        IsEnabled = function() return true end,
        Record = function(definition)
            Runtime.trace[#Runtime.trace + 1] = Values.copy(definition)
            return true
        end,
    }
end

return Core
