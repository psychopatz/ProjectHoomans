-- Client bridge lifecycle facade for HoomansLLM.
--
-- Settings and registration are separate providers so the tick hook only
-- coordinates lifecycle work; it does not own command definitions or UI.
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_Runtime"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_ConversationMemorySync"
require "PNC/Integrations/PNC_VoiceGateway"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_BridgeSettings"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_BridgeRegistration"

PNC = PNC or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}

local Integration = PNC.HoomansLLM
local Internal = Integration.Internal
local Runtime = Internal.Runtime
local Settings = Internal.BridgeSettings
local Registration = Internal.BridgeRegistration
local Context = Integration.Context
local MemorySync = PNC.ConversationMemorySync
local VoiceGateway = PNC.VoiceGateway
local bridgeRegistered = false
local tickRegistered = false
local lastRegistrationState = nil

local function log(event, details)
    Runtime.Log(event, details)
end

local function bridgeEnabled()
    return Integration.IsBridgeEnabled
        and Integration.IsBridgeEnabled() == true
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
    local registered, details = Registration.Register(
        bridge, Integration, Context, MemorySync
    )
    bridgeRegistered = registered
    if registered then
        log(
            "bridge_registered",
            "namespace=projecthoomans.llm commands=pollChat,deliverChat"
                .. " speech_events=" .. tostring(details.speechEventsAvailable)
                .. " memory_sync=" .. tostring(details.memorySyncAvailable)
                .. " tool_catalog=" .. tostring(details.catalogAvailable)
        )
        lastRegistrationState = "registered"
    elseif lastRegistrationState ~= "registration_failed" then
        log(
            "bridge_registration_failed",
            "poll=" .. tostring(details.pollReason)
                .. " deliver=" .. tostring(details.deliverReason)
                .. " speechStarted=" .. tostring(details.startedReason)
                .. " speechFinished=" .. tostring(details.finishedReason)
                .. " speechFallback=" .. tostring(details.fallbackReason)
                .. " syncPoll=" .. tostring(details.syncPollReason)
                .. " syncAck=" .. tostring(details.syncAckReason)
                .. " toolCatalog=" .. tostring(details.catalogReason)
        )
        lastRegistrationState = "registration_failed"
    end
    return bridgeRegistered
end

local function onTick()
    Settings.Apply(function()
        bridgeRegistered = false
        lastRegistrationState = nil
    end)
    if VoiceGateway and VoiceGateway.Sync then
        VoiceGateway.Sync()
        if VoiceGateway.Update then VoiceGateway.Update() end
    end
    registerBridge()
end

if Events and Events.OnTick and Events.OnTick.Add and not tickRegistered then
    Events.OnTick.Add(onTick)
    tickRegistered = true
end

registerBridge()
if VoiceGateway and VoiceGateway.Sync then VoiceGateway.Sync() end

return Integration
