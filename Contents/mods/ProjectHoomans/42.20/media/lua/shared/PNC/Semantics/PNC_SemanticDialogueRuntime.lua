-- Shared runtime gate for the semantic dialogue feature.
--
-- Production uses PsychopatzCore's persisted debug-settings registry. The
-- headless harness may provide a scenario override, but it still calls this
-- module and therefore exercises the same gate as the native client.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Runtime = PNC.Semantics.SemanticDialogueRuntime or {}
PNC.Semantics.SemanticDialogueRuntime = Runtime

Runtime.VERSION = 1
Runtime.SETTING_ID = "ProjectHoomans.SemanticDialogueEnabled"
Runtime.Enabled = Runtime.Enabled ~= false
Runtime.HarnessOverride = nil

local function settingsObject()
    local core = PsychopatzCore or {}
    if core.DebugSettings then return core.DebugSettings end
    return require "PsychopatzCore/Debug/PsychopatzDebugSettings"
end

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

local settings = settingsObject()
if settings and type(settings.Register) == "function" then
    settings.Register({
        id = Runtime.SETTING_ID,
        source = "Project Hoomans",
        order = 130,
        title = "Semantic dialogue enabled",
        description = "Enable Project Hoomans semantic dialogue and suggestions.",
        defaultEnabled = true,
        runtimeMutable = true,
        apply = function(enabled)
            Runtime.SetEnabled(enabled)
        end,
    })
    if type(settings.IsEnabled) == "function" then
        Runtime.SetEnabled(settings.IsEnabled(Runtime.SETTING_ID) == true)
    end
end

return Runtime
