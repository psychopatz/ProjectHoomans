-- Project Hoomans' adapter for the mod-agnostic PsychopatzCore voice stream.
-- Core owns transport and lifecycle; this file only resolves Hoomans' NPC
-- body/profile into the compact binding understood by PBrainZ.

require "PsychopatzCore/Voice/PsychopatzVoiceGateway"
require "PNC/Audio/PNC_NPCVoice"
require "PNC/Audio/PNC_PlayerVoice"
pcall(require, "PsychopatzCore/UI/PsychopatzAudioSettings")

PNC = PNC or {}
PNC.VoiceGateway = PNC.VoiceGateway or {}

local Adapter = PNC.VoiceGateway
local Gateway = PsychopatzCore and PsychopatzCore.VoiceGateway
local registered = false

local function trim(value)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function activeEntry(message)
    local conversation = PsychopatzCore and PsychopatzCore.Conversation
    local view = conversation and conversation.instance or nil
    local session = view and view.session or nil
    if not view or not session then return nil end
    if tostring(session.conversationID or "")
        ~= tostring(message and message.conversationID or "")
    then
        return nil
    end
    local context = view.spec and view.spec.context or nil
    return context and context.entry or nil
end

local function liveBody(npcID)
    local registry = PNC and PNC.Registry or nil
    if not registry or type(registry.GetLiveZombie) ~= "function" then return nil end
    local ok, body = pcall(registry.GetLiveZombie, npcID)
    return ok and body or nil
end

local function snapshot(npcID, entry)
    if entry and type(entry.snapshot) == "table" then return entry.snapshot end
    if entry and type(entry.record) == "table" then return entry.record end
    local state = PNC and PNC.Network and PNC.Network.ClientState or nil
    local snapshots = state and state.snapshots or nil
    return snapshots and snapshots[tostring(npcID)] or nil
end

local function profileFor(message)
    local npcID = tostring(message and (message.npcUUID or message.speakerID) or "")
    if npcID == "" then return nil end
    local entry = activeEntry(message)
    local body = entry and (entry.zombie or entry.body) or nil
    body = body or liveBody(npcID)
    if not body then return nil end
    local voice = PNC and PNC.NPCVoice or nil
    if not voice or type(voice.GetProfile) ~= "function" then return nil end
    local ok, profile = pcall(voice.GetProfile, snapshot(npcID, entry), body)
    if not ok or type(profile) ~= "table" then return nil end
    local prefix = trim(profile.prefix)
    local voiceType = tonumber(profile.voiceType)
    if prefix == "" or voiceType == nil then return nil end
    return {
        npc_uuid = npcID,
        slot = prefix .. ":" .. tostring(math.floor(voiceType)),
        pitch = tonumber(profile.pitch) or 0,
    }
end

local function playerProfileFor(message)
    local voice = PNC and PNC.PlayerVoice or nil
    if not voice or type(voice.GetProfile) ~= "function" then return nil end
    local ok, profile = pcall(voice.GetProfile, message)
    if not ok or type(profile) ~= "table" then return nil end
    local playerID = trim(profile.player_uuid or profile.speaker_id)
    local slot = trim(profile.slot)
    if playerID == "" or slot == "" then return nil end
    return {
        speaker_id = playerID,
        speaker_kind = "player",
        player_uuid = playerID,
        slot = slot,
        pitch = tonumber(profile.pitch) or 0,
    }
end

local function playerSpeechEnabled()
    local audio = PsychopatzCore and PsychopatzCore.Audio or nil
    if not audio or type(audio.IsPlayerSpeechEnabled) ~= "function" then
        return false
    end
    local ok, enabled = pcall(audio.IsPlayerSpeechEnabled)
    return ok and enabled == true
end

local function brainAvailable()
    if not Gateway or type(Gateway.IsBridgeReady) ~= "function" then
        return false
    end
    local ok, ready = pcall(Gateway.IsBridgeReady)
    return ok and ready == true
end

local function sourceChannel(message)
    local source = message and message.source
    return type(source) == "table" and trim(source.channel) or ""
end

local function accepts(message)
    if type(message) ~= "table" then return false end
    local speakerKind = string.lower(tostring(
        message.speakerKind or message.speaker or "npc"
    ))
    if speakerKind == "player" then
        if not playerSpeechEnabled() or not brainAvailable() then return false end
    elseif speakerKind ~= "npc" then
        return false
    end
    if trim(message.text) == "" then return false end
    local state = type(message.presentationState) == "table"
        and message.presentationState or {}
    if state.tts == false then return false end
    -- These are already managed by the legacy LLM TTS callbacks. This guard
    -- makes the Core stream safe while an older PBrainZ is still in use.
    local channel = sourceChannel(message)
    return channel ~= "tts" and channel ~= "tts_detached"
        and message.ttsManaged ~= true
end

local function enrich(message)
    local speakerKind = string.lower(tostring(
        message.speakerKind or message.speaker or "npc"
    ))
    local binding = speakerKind == "player"
        and playerProfileFor(message) or profileFor(message)
    if not binding then return {} end
    return {
        voice_binding = binding,
        speech = {
            mode = "RESPONSE",
            allow_overlap = false,
            can_interrupt = false,
        },
    }
end

local function bridgeConfigured()
    return brainAvailable()
end

function Adapter.IsBrainAvailable()
    return brainAvailable()
end

function Adapter.GetNPCBinding(npcID)
    npcID = trim(npcID)
    if npcID == "" then return nil end
    return profileFor({
        npcUUID = npcID,
        speakerID = npcID,
    })
end

function Adapter.Register()
    if registered then return true end
    if not bridgeConfigured() then return false, "bridge_disabled" end
    if not Gateway or type(Gateway.RegisterSource) ~= "function" then
        return false, "core_voice_gateway_unavailable"
    end
    local ok, reason = Gateway.RegisterSource("ProjectHoomans", {
        filter = accepts,
        enrich = enrich,
        bufferUntilReady = true,
        pendingTTL = 15000,
        externalTick = true,
    })
    registered = ok == true
    return ok, reason
end

function Adapter.Sync()
    if bridgeConfigured() then return Adapter.Register() end
    if registered then return Adapter.Unregister() end
    return false, "bridge_disabled"
end

function Adapter.Update()
    return Gateway and Gateway.Update and Gateway.Update() or false
end

function Adapter.Unregister()
    local result = Gateway and Gateway.UnregisterSource
        and Gateway.UnregisterSource("ProjectHoomans") or false
    registered = false
    return result
end

Adapter.Register()

return Adapter
