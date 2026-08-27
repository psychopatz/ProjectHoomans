-- PsychopatzCore bridge registration for the Project Hoomans LLM channel.
require "PNC/Integrations/PNC_HoomansLLM"

PNC = PNC or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}

local Integration = PNC.HoomansLLM
local bridgeRegistered = false
local tickRegistered = false
local lastRegistrationState = nil
local nextSettingCheckAt = 0
local SETTING_CHECK_INTERVAL_MS = 1000

local function log(event, details)
    if print then
        print("[PNC][LLM] " .. tostring(event) .. " " .. tostring(details or ""))
    end
end

local function bridgeEnabled()
    return Integration.IsBridgeEnabled
        and Integration.IsBridgeEnabled() == true
end

local function nowMs()
    return getTimeInMillis and getTimeInMillis()
        or getTimestampMs and getTimestampMs()
        or 0
end

local function applyBridgeSetting()
    local bootstrap = PsychopatzCore and PsychopatzCore.BridgeBootstrap
    if not bootstrap or not bootstrap.ReadConfig or not bootstrap.TryActivate
        or not bootstrap.IsEnabled
    then
        return
    end
    local now = nowMs()
    if now > 0 and now < nextSettingCheckAt then return end
    nextSettingCheckAt = now > 0 and now + SETTING_CHECK_INTERVAL_MS or 0

    local config = bootstrap.ReadConfig()
    local configured = config and config.enabled == true
    local active = bootstrap:IsEnabled() == true
    if configured and not active then
        if bootstrap.TryActivate() then
            log("bridge_setting_applied", "enabled=true")
        end
        return
    end
    if not configured and active then
        local bridge = PsychopatzCore and PsychopatzCore.Bridge
        if bridge and type(bridge.Shutdown) == "function" then
            bridge.Shutdown()
            -- The core bootstrap intentionally has no live settings watcher.
            -- Reset its public runtime flag so a later file change can activate
            -- the bridge again without requiring a profiler or game restart.
            bootstrap.enabled = false
            bootstrap.config = config
            bridgeRegistered = false
            log("bridge_setting_applied", "enabled=false")
        end
    end
end

local function registerBridge()
    if not bridgeEnabled() then
        if lastRegistrationState ~= "disabled" then
            log("bridge_waiting", "game bridge is disabled")
            lastRegistrationState = "disabled"
        end
        bridgeRegistered = false
        return false
    end
    if bridgeRegistered then return true end
    local bridge = PsychopatzCore and PsychopatzCore.Bridge
    if not bridge or type(bridge.RegisterCommand) ~= "function" then
        if lastRegistrationState ~= "unavailable" then
            log("bridge_waiting", "PsychopatzCore bridge API is unavailable")
            lastRegistrationState = "unavailable"
        end
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
    if bridgeRegistered then
        log("bridge_registered", "namespace=projecthoomans.llm commands=pollChat,deliverChat")
        lastRegistrationState = "registered"
    elseif lastRegistrationState ~= "registration_failed" then
        log(
            "bridge_registration_failed",
            "poll=" .. tostring(pollReason or pollOK)
                .. " deliver=" .. tostring(deliverReason or deliverOK)
        )
        lastRegistrationState = "registration_failed"
    end
    return bridgeRegistered
end

local function onTick()
    applyBridgeSetting()
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

-- Register immediately when the core bridge is already READY. The tick hook
-- remains as a retry path for the bridge's lazy activation mode.
registerBridge()

return Integration
