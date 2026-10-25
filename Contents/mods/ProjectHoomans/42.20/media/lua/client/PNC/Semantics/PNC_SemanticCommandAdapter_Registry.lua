-- Shared command-adapter registry and action registration contract.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Adapter = PNC.Semantics.CommandAdapter or {}
PNC.Semantics.CommandAdapter = Adapter

Adapter.VERSION = 1
Adapter.Actions = Adapter.Actions or {}
Adapter.Internal = Adapter.Internal or {}

local Internal = Adapter.Internal
local function normalized(value)
    return string.upper(tostring(value or ""))
end
Internal.Normalize = normalized

function Adapter.RegisterAction(action, definition)
    action = normalized(action)
    if action == "" then return false, "invalid_action" end
    if type(definition) ~= "string" and type(definition) ~= "table" then
        return false, "invalid_action_definition"
    end
    Adapter.Actions[action] = definition
    return true, definition
end

return Adapter
