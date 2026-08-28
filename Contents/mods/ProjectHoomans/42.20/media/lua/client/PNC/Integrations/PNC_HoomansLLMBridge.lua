-- PsychopatzCore bridge registration for the Project Hoomans LLM and local
-- TTS speech-lifecycle channel.
require "PNC/Integrations/PNC_HoomansLLM"
require "PNC/Integrations/PNC_ConversationMemorySync"
require "PNC/Integrations/PNC_VoiceGateway"

-- The context adapter is optional for bridge-only consumers and lightweight
-- bootstrap tests. A real Project Hoomans runtime has Conversation loaded.
if PsychopatzCore and PsychopatzCore.Conversation then
    require "PNC/Integrations/PNC_HoomansLLMContext"
end

PNC = PNC or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}

local Integration = PNC.HoomansLLM
local Context = PNC.HoomansLLM.Context
local MemorySync = PNC.ConversationMemorySync
local VoiceGateway = PNC.VoiceGateway
local bridgeRegistered = false
local tickRegistered = false
local lastRegistrationState = nil
local nextSettingCheckAt = 0
local SETTING_CHECK_INTERVAL_MS = 1000
local TOOL_NAMESPACE = "projecthoomans.llm"

local function log(event, details)
    if print then
        print("[PNC][LLM] " .. tostring(event) .. " " .. tostring(details or ""))
    end
end

local function bridgeEnabled()
    return Integration.IsBridgeEnabled
        and Integration.IsBridgeEnabled() == true
end

local function registerToolCatalog(bridge)
    if type(bridge.RegisterTool) ~= "function"
        or not Context or type(Context.GetToolDefinitions) ~= "function"
    then
        return false, "catalog_api_unavailable"
    end
    local definitions = Context.GetToolDefinitions()
    for _, tool in ipairs(definitions or {}) do
        local definition = tool and tool["function"] or nil
        local name = definition and tostring(definition.name or "") or ""
        if name ~= "" then
            local ok, reason = bridge.RegisterTool(
                TOOL_NAMESPACE, name, tool, { kind = "llm_tool" }
            )
            if not ok and reason ~= "duplicate_tool" then
                return false, tostring(reason or "registration_failed")
            end
        end
    end
    return true, "registered"
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
    local catalogAvailable, catalogReason = registerToolCatalog(bridge)
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
    local syncPollOK, syncPollReason = bridge.RegisterCommand(
        "projecthoomans.llm",
        "pollConversationSync",
        {
            readOnly = true,
            category = "LLM",
            handler = function()
                return MemorySync.Poll()
            end,
        }
    )
    local syncAckOK, syncAckReason = bridge.RegisterCommand(
        "projecthoomans.llm",
        "ackConversationSync",
        {
            readOnly = false,
            category = "LLM",
            handler = function(_, arguments)
                return MemorySync.Ack(arguments)
            end,
        }
    )
    local memorySyncAvailable = (syncPollOK == true or syncPollReason == "duplicate_command")
        and (syncAckOK == true or syncAckReason == "duplicate_command")
    local startedOK, startedReason = bridge.RegisterCommand(
        "projecthoomans.llm",
        "speechStarted",
        {
            readOnly = false,
            category = "LLM",
            handler = function(_, arguments)
                return Integration.SpeechStarted(arguments)
            end,
        }
    )
    local finishedOK, finishedReason = bridge.RegisterCommand(
        "projecthoomans.llm",
        "speechFinished",
        {
            readOnly = false,
            category = "LLM",
            handler = function(_, arguments)
                return Integration.SpeechFinished(arguments)
            end,
        }
    )
    local fallbackOK, fallbackReason = bridge.RegisterCommand(
        "projecthoomans.llm",
        "speechFallback",
        {
            readOnly = false,
            category = "LLM",
            handler = function(_, arguments)
                return Integration.SpeechFallback(arguments)
            end,
        }
    )
    local speechEventsAvailable = (startedOK == true or startedReason == "duplicate_command")
        and (finishedOK == true or finishedReason == "duplicate_command")
        and (fallbackOK == true or fallbackReason == "duplicate_command")
    bridgeRegistered = pollAvailable and deliverAvailable
    if bridgeRegistered then
        log(
            "bridge_registered",
            "namespace=projecthoomans.llm commands=pollChat,deliverChat speech_events="
                .. tostring(speechEventsAvailable)
                .. " memory_sync=" .. tostring(memorySyncAvailable)
                .. " tool_catalog=" .. tostring(catalogAvailable)
        )
        lastRegistrationState = "registered"
    elseif lastRegistrationState ~= "registration_failed" then
        log(
            "bridge_registration_failed",
                "poll=" .. tostring(pollReason or pollOK)
                .. " deliver=" .. tostring(deliverReason or deliverOK)
                .. " speechStarted=" .. tostring(startedReason or startedOK)
                .. " speechFinished=" .. tostring(finishedReason or finishedOK)
                .. " speechFallback=" .. tostring(fallbackReason or fallbackOK)
                .. " syncPoll=" .. tostring(syncPollReason or syncPollOK)
                .. " syncAck=" .. tostring(syncAckReason or syncAckOK)
                .. " toolCatalog=" .. tostring(catalogReason)
        )
        lastRegistrationState = "registration_failed"
    end
    return bridgeRegistered
end

local function onTick()
    applyBridgeSetting()
    if VoiceGateway and VoiceGateway.Sync then
        VoiceGateway.Sync()
        if VoiceGateway.Update then VoiceGateway.Update() end
    end
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
if VoiceGateway and VoiceGateway.Sync then VoiceGateway.Sync() end

return Integration
