-- PsychopatzCore bridge registration for the Project Hoomans LLM channel.
require "PNC/Integrations/PNC_HoomansLLM"

PNC = PNC or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}

local Integration = PNC.HoomansLLM
local bridgeRegistered = false
local tickRegistered = false

local function bridgeEnabled()
    return Integration.IsBridgeEnabled
        and Integration.IsBridgeEnabled() == true
end

local function registerBridge()
    if not bridgeEnabled() then
        bridgeRegistered = false
        return false
    end
    if bridgeRegistered then return true end
    local bridge = PsychopatzCore and PsychopatzCore.Bridge
    if not bridge or type(bridge.RegisterCommand) ~= "function" then
        return false
    end
    local pollOK, pollReason = bridge.RegisterCommand(
        "projecthoomans.llm",
        "pollChat",
        {
            readOnly = false,
            category = "LLM",
            handler = function()
                return Integration.Poll()
            end,
        }
    )
    local deliverOK, deliverReason = bridge.RegisterCommand(
        "projecthoomans.llm",
        "deliverChat",
        {
            readOnly = false,
            category = "LLM",
            handler = function(_, arguments)
                return Integration.Deliver(arguments)
            end,
        }
    )
    local pollAvailable = pollOK == true or pollReason == "duplicate_command"
    local deliverAvailable = deliverOK == true
        or deliverReason == "duplicate_command"
    bridgeRegistered = pollAvailable and deliverAvailable
    return bridgeRegistered
end

local function onTick()
    registerBridge()
    local view = PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.instance or nil
    local part = view and view.extensionParts
        and view.extensionParts.llmInput or nil
    if part and part.refreshControls then part:refreshControls() end
end

if Events and Events.OnTick and Events.OnTick.Add and not tickRegistered then
    Events.OnTick.Add(onTick)
    tickRegistered = true
end

return Integration
