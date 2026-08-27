local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "client" },
    { "PsychopatzCore", "common_client" },
    { "PsychopatzCore", "client" },
    { "PsychopatzCore", "common" },
})

local configEnabled = false
local onTick
local bootstrap = { enabled = false }
function bootstrap.IsEnabled()
    return bootstrap.enabled == true
end
function bootstrap.ReadConfig()
    return { enabled = configEnabled }
end
function bootstrap.TryActivate()
    bootstrap.enabled = true
    return true
end

local bridge = { registerCount = 0, shutdownCount = 0 }
function bridge.RegisterCommand()
    bridge.registerCount = bridge.registerCount + 1
    return true
end
function bridge.Shutdown()
    bridge.shutdownCount = bridge.shutdownCount + 1
    return true
end

PsychopatzCore = {
    BridgeBootstrap = bootstrap,
    Bridge = bridge,
}
local originalRequire = require
require = function(name)
    if name ~= "PsychopatzCore/UI/Conversation/PsychopatzConversationLayout" then
        return originalRequire(name)
    end
    local layout = {
        defaults = {},
        GetNormalized = function() return {} end,
    }
    PsychopatzCore.Conversation = { Layout = layout }
    return layout
end
PNC = {
    HoomansLLM = {
        IsBridgeEnabled = function()
            return bootstrap:IsEnabled()
        end,
        Poll = function() return { status = "idle" } end,
        Deliver = function() return { accepted = true } end,
    },
}
Events = { OnTick = {
    Add = function(callback) onTick = callback end,
} }
getTimeInMillis = function() return 0 end

T.load("ProjectHoomans", "client", "PNC/Integrations/PNC_HoomansLLMBridge.lua")
T.truthy(onTick, "bridge tick hook registered")
T.equal(bridge.registerCount, 0, "disabled bridge does not register commands")

configEnabled = true
onTick()
T.truthy(bootstrap.enabled, "enabled setting activates the bridge")
T.equal(bridge.registerCount, 2, "enabled bridge registers both LLM commands")

configEnabled = false
onTick()
T.falsy(bootstrap.enabled, "disabled setting stops the bridge")
T.equal(bridge.shutdownCount, 1, "disabled setting shuts down the active bridge")

T.finish("pnc_hoomans_llm_bridge_setting_smoke")
