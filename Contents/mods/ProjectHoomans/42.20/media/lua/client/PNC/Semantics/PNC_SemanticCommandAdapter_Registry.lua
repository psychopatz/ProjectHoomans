-- Shared command-adapter registry and action registration contract.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Adapter = PNC.Semantics.CommandAdapter or {}
PNC.Semantics.CommandAdapter = Adapter

Adapter.VERSION = 1
Adapter.Actions = Adapter.Actions or {}
Adapter.ActionOrigins = Adapter.ActionOrigins or {}
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
    -- The real descriptor author, not an inferred generated Lua ownership.
    local debugAPI = rawget(_G, "debug")
    local getInfo = type(debugAPI) == "table" and debugAPI["getinfo"]
    if type(getInfo) == "function" then
        local info = getInfo(2, "S")
        if info and type(info.source) == "string"
            and string.sub(info.source, 1, 1) == "@"
            and #info.source < 1024 then
            Adapter.ActionOrigins[action] = string.sub(info.source, 2)
        end
    end
    return true, definition
end

return Adapter
