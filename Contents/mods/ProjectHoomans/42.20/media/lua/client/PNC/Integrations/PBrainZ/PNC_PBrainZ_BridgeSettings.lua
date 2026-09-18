-- Polls the Core bridge setting and applies activation changes.
PNC = PNC or {}
PNC.PBrainZ = PNC.PBrainZ or {}
PNC.PBrainZ.Internal = PNC.PBrainZ.Internal or {}

local Internal = PNC.PBrainZ.Internal
local Runtime = Internal.Runtime
local Settings = Internal.BridgeSettings or {}
Internal.BridgeSettings = Settings
local nextCheckAt = 0
local CHECK_INTERVAL_MS = 1000

function Settings.Apply(onDisabled)
    local bootstrap = PsychopatzCore and PsychopatzCore.BridgeBootstrap
    if not bootstrap or not bootstrap.ReadConfig or not bootstrap.TryActivate
        or not bootstrap.IsEnabled
    then
        return
    end
    local now = Runtime.Now()
    if now > 0 and now < nextCheckAt then return end
    nextCheckAt = now > 0 and now + CHECK_INTERVAL_MS or 0

    local config = bootstrap.ReadConfig()
    local configured = config and config.enabled == true
    local active = bootstrap:IsEnabled() == true
    if configured and not active then
        if bootstrap.TryActivate() and print then
            print("[PNC][LLM] bridge_setting_applied enabled=true")
        end
        return
    end
    if not configured and active then
        local bridge = PsychopatzCore and PsychopatzCore.Bridge
        if bridge and type(bridge.Shutdown) == "function" then
            bridge.Shutdown()
            bootstrap.enabled = false
            bootstrap.config = config
            if onDisabled then onDisabled() end
            if print then
                print("[PNC][LLM] bridge_setting_applied enabled=false")
            end
        end
    end
end

return Settings
