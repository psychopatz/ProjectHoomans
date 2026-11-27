-- Shared runtime gate for the semantic dialogue feature.
--
-- Semantic dialogue is a core gameplay subsystem and is always enabled in
-- production (never exposed as a DebugSettings toggle that "Disable All" could
-- turn off). Headless test scenarios may still override availability via
-- SetHarnessOverride().
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Runtime = PNC.ConvoEngine.SemanticDialogueRuntime or {}
PNC.ConvoEngine.SemanticDialogueRuntime = Runtime

Runtime.VERSION = 1
Runtime.Enabled = true
Runtime.HarnessOverride = nil

function Runtime.IsEnabled()
    if Runtime.HarnessOverride ~= nil then
        return Runtime.HarnessOverride == true
    end
    return Runtime.Enabled == true
end

function Runtime.SetEnabled(enabled)
    Runtime.Enabled = enabled == true
    return Runtime.Enabled
end

function Runtime.SetHarnessOverride(enabled)
    if enabled == nil then
        Runtime.HarnessOverride = nil
    else
        Runtime.HarnessOverride = enabled == true
    end
    return Runtime.IsEnabled()
end

return Runtime
