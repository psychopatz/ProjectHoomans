-- Canonical player speech adapter.
--
-- Player-facing flavor keeps the normal in-world Say() presentation, but when
-- player TTS is enabled and the live PBrainZ bridge is ready it also publishes
-- the exact same line through Core's conversation message bus. Keeping the
-- gate here prevents a configured-but-not-running brain from swallowing the
-- vanilla speech path.

require "PsychopatzCore/Conversation/PsychopatzConversationMessage"
require "PsychopatzCore/Voice/PsychopatzVoiceGateway"
require "PNC/Audio/PNC_PlayerVoice"

PNC = PNC or {}
PNC.PlayerSpeech = PNC.PlayerSpeech or {}

local Speech = PNC.PlayerSpeech
local Message = PsychopatzCore and PsychopatzCore.Conversation
    and PsychopatzCore.Conversation.Message or nil

local function trim(value)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function call(target, method, ...)
    if not target or type(target[method]) ~= "function" then return nil end
    local ok, value = pcall(target[method], target, ...)
    return ok and value or nil
end

local function bridgeReady()
    local gateway = PsychopatzCore and PsychopatzCore.VoiceGateway or nil
    if not gateway or type(gateway.IsBridgeReady) ~= "function" then
        return false
    end
    local ok, ready = pcall(gateway.IsBridgeReady)
    return ok and ready == true
end

local function playerSpeechEnabled()
    local audio = PsychopatzCore and PsychopatzCore.Audio or nil
    if not audio or type(audio.IsPlayerSpeechEnabled) ~= "function" then
        return false
    end
    local ok, enabled = pcall(audio.IsPlayerSpeechEnabled)
    return ok and enabled == true
end

local function gatewayReady()
    local gateway = PsychopatzCore and PsychopatzCore.VoiceGateway or nil
    if not gateway or type(gateway.GetStatus) ~= "function" then
        return false
    end
    local ok, status = pcall(gateway.GetStatus)
    if not ok or type(status) ~= "table" then return false end
    for _, sourceID in ipairs(status.sources or {}) do
        if tostring(sourceID) == "ProjectHoomans" then return true end
    end
    return false
end

local function targetID(target)
    if type(target) ~= "table" then return nil end
    local id = target.npcUUID or target.npcID or target.id
        or target.PNC_UUID or target.uuid
    id = trim(id)
    return id ~= "" and id or nil
end

local function firstTarget(context)
    if type(context) ~= "table" then return nil end
    if context.target then return context.target end
    if type(context.targets) == "table" then return context.targets[1] end
    return nil
end

local function playerID(player)
    local id = trim(call(player, "getUsername"))
    if id ~= "" then return id end
    id = trim(call(player, "getOnlineID"))
    return id ~= "" and id or nil
end

function Speech.CanUseVoiceEndpoint()
    if not playerSpeechEnabled() then return false, "player_tts_disabled" end
    if not bridgeReady() then return false, "brain_unavailable" end
    if not gatewayReady() then return false, "voice_gateway_unavailable" end
    if not Message or type(Message.New) ~= "function"
        or type(Message.Publish) ~= "function"
    then
        return false, "conversation_message_unavailable"
    end
    return true
end

function Speech.Publish(player, text, context)
    text = trim(text)
    if text == "" or not player then return false, "empty_speech" end
    local usable, reason = Speech.CanUseVoiceEndpoint()
    if not usable then return false, reason end

    local id = playerID(player)
    if not id then return false, "player_identity_unavailable" end
    local target = firstTarget(context)
    local npcID = targetID(target)
    local conversationID = type(context) == "table"
        and trim(context.conversationID or context.conversation_id) or ""
    if conversationID == "" then
        conversationID = Message.NewID("player-speech")
    end

    local message = Message.New({
        messageID = Message.NewID("player-speech"),
        saveUUID = Message.GetSaveID and Message.GetSaveID() or nil,
        conversationID = conversationID,
        sequence = 0,
        speaker = "player",
        speakerID = id,
        speakerName = call(player, "getUsername") or id,
        speakerKind = "player",
        playerUUID = id,
        npcUUID = npcID,
        namespace = "ProjectHoomans",
        payload = { text = text },
        text = text,
        worldAgeHours = Message.GetWorldAgeHours
            and Message.GetWorldAgeHours() or nil,
        source = {
            kind = "player_flavor",
            channel = "player_flavor",
            -- This is authored command flavor, not a new player-authored
            -- conversation turn. Keep it out of long-term LLM memory while
            -- still sending it to the voice endpoint.
            contextEligible = false,
            commandID = type(context) == "table" and context.commandID or nil,
            eventID = type(context) == "table" and context.eventID or nil,
        },
        presentationState = {
            conversationUI = false,
            nameplate = false,
            tts = true,
        },
    })
    local ok, published = pcall(Message.Publish, message)
    if not ok or published ~= true then
        return false, "message_publish_failed"
    end
    return true, message
end

-- The single player speech entry point. The ordinary bubble is deliberately
-- retained as presentation even when TTS is active; it is also the safe
-- fallback when the setting, bridge, or voice source is unavailable.
function Speech.Speak(player, text, context)
    text = trim(text)
    if text == "" or not player then return false end
    local voiced = Speech.Publish(player, text, context) == true
    if type(player.Say) == "function" then
        player:Say(text)
        return true
    end
    if type(player.setHaloNote) == "function" then
        player:setHaloNote(text, 255, 255, 255, 300)
        return true
    end
    return voiced
end

return Speech
