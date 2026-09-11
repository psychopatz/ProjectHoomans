-- Requiring the host here makes the integration deterministic even when the
-- engine's automatic client-file order changes between Build 42 revisions.
require "PsychopatzCore/UI/Radio/PsychopatzRadioSignalHost"
require "PsychopatzCore/Radio/PsychopatzCustomRadioClient"

PNC = PNC or {}

local RadioActions = PsychopatzCore and PsychopatzCore.RadioActions
local CustomRadio = PsychopatzCore and PsychopatzCore.CustomRadio
local RadioDeviceState = PsychopatzCore and PsychopatzCore.RadioDeviceState
local Message = PsychopatzCore and PsychopatzCore.Conversation
    and PsychopatzCore.Conversation.Message
if not Message then
    pcall(require, "PsychopatzCore/Conversation/PsychopatzConversationMessage")
    Message = PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.Message
end
local ScanChannel = PNC.RadioDiscoveryChannel
local lastProbeAt = {}
local lastAmbientProbeAt = {}
local PROBE_INTERVAL_MS = 40000

PNC.RadioDiscoveryPresentation = PNC.RadioDiscoveryPresentation or {}
local Presentation = PNC.RadioDiscoveryPresentation
Presentation.lastNotificationID = Presentation.lastNotificationID or nil
Presentation.pendingBroadcasts = Presentation.pendingBroadcasts or {}
Presentation.pendingNotificationIDs = Presentation.pendingNotificationIDs or {}

local MAX_PENDING_BROADCASTS = 4

local function nowMs()
    if getTimeInMillis then return tonumber(getTimeInMillis()) or 0 end
    if getTimestampMs then return tonumber(getTimestampMs()) or 0 end
    local time = getGameTime and getGameTime() or nil
    if time and time.getWorldAgeHours then
        return (tonumber(time:getWorldAgeHours()) or 0) * 3600000
    end
    return 0
end

local function lineSpacingMs()
    local settings = PNC.Sandbox
    if settings and type(settings.RadioDiscoveryLineSpacingSeconds) == "function" then
        return math.max(0, tonumber(settings.RadioDiscoveryLineSpacingSeconds())
            or 2) * 1000
    end
    return 2000
end

local function ambientEnabled()
    local settings = PNC.Sandbox
    if settings and type(settings.RadioAmbientEnabled) == "function" then
        return settings.RadioAmbientEnabled() == true
    end
    return true
end

local function ambientIntervalMs()
    local settings = PNC.Sandbox
    if settings and type(settings.RadioAmbientIntervalSeconds) == "function" then
        return math.max(1000, tonumber(settings.RadioAmbientIntervalSeconds())
            or 90) * 1000
    end
    return 90000
end

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function activeRadio()
    if not RadioDeviceState
        or type(RadioDeviceState.FindAudiblePlayerDevice) ~= "function"
    then
        return true
    end
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player then return false end
    local ok, device = pcall(
        RadioDeviceState.FindAudiblePlayerDevice, player
    )
    return ok and device ~= nil
end

local function broadcastLineText(value)
    value = type(value) == "table" and value.text or value
    value = tostring(value or "")
    value = string.gsub(value, "<[^>]+>", "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local FALLBACK_RADIO_VOICE_SLOTS = {
    "VoiceFemale:0",
    "VoiceMale:0",
    "VoiceFemale:1",
    "VoiceMale:1",
    "VoiceFemale:2",
    "VoiceMale:2",
    "VoiceFemale:3",
    "VoiceMale:3",
}

local function fallbackVoiceSlot(speakerID)
    speakerID = tostring(speakerID or "")
    if string.sub(speakerID, 1, 6) == "radio:" then
        return "VoiceMale:0"
    end
    local hash = 0
    for index = 1, #speakerID do
        hash = (hash * 31 + (string.byte(speakerID, index) or 0))
            % #FALLBACK_RADIO_VOICE_SLOTS
    end
    return FALLBACK_RADIO_VOICE_SLOTS[hash + 1]
end

local function voiceBindingFor(speakerID)
    local gateway = PNC and PNC.VoiceGateway or nil
    if gateway and type(gateway.GetNPCBinding) == "function" then
        local ok, binding = pcall(gateway.GetNPCBinding, speakerID)
        if ok and type(binding) == "table"
            and tostring(binding.slot or "") ~= ""
        then
            return binding
        end
    end
    return {
        npc_uuid = speakerID,
        slot = fallbackVoiceSlot(speakerID),
        pitch = 0,
    }
end

local function speakerForLine(broadcast, line, notificationID)
    local role = type(line) == "table"
        and (line.speakerRole or line.speaker_role) or nil
    role = tostring(role or "primary")
    local speakerID = type(line) == "table"
        and (line.speakerNPCID or line.speakerID or line.speaker_id) or nil
    if not speakerID then
        speakerID = role == "secondary"
            and broadcast.secondarySpeakerNPCID or broadcast.speakerNPCID
    end
    speakerID = tostring(speakerID or "")
    if speakerID == "" then
        speakerID = "radio:" .. notificationID .. ":" .. role
    end
    return role, speakerID
end

local function publishBroadcastLine(item, line)
    local broadcast = item.broadcast
    local notificationID = item.notificationID
    local text = broadcastLineText(line)
    if text == "" then return false end
    local speakerRole, speakerID = speakerForLine(
        broadcast, line, notificationID
    )
    local messageID = "radio-broadcast:" .. notificationID
        .. ":" .. tostring(item.index)
    Message.Publish(Message.New({
        messageID = messageID,
        conversationID = "radio:" .. notificationID,
        sequence = item.index,
        speaker = "npc",
        speakerID = speakerID,
        speakerKind = "npc",
        npcUUID = speakerID,
        namespace = "ProjectHoomans.Radio",
        text = text,
        payload = {
            text = text,
            style = "radio_broadcast",
            speakerRole = speakerRole,
        },
        source = {
            kind = "radio_broadcast",
            channel = "radio",
            requestID = notificationID,
        },
        voiceBinding = voiceBindingFor(speakerID),
        presentationState = {
            conversationUI = false,
            nameplate = false,
            tts = true,
            speech = item.speech,
        },
    }))
    return true
end

function Presentation.Update()
    local queue = Presentation.pendingBroadcasts
    local item = queue[1]
    if not item then return false end
    local at = nowMs()
    if at < (tonumber(item.nextAt) or 0) then return false end
    if not activeRadio() then
        Presentation.pendingNotificationIDs[item.notificationID] = nil
        table.remove(queue, 1)
        return false
    end
    local line = item.lines[item.index]
    if line then publishBroadcastLine(item, line) end
    item.index = item.index + 1
    if item.index > #item.lines then
        Presentation.pendingNotificationIDs[item.notificationID] = nil
        table.remove(queue, 1)
    else
        item.nextAt = at + lineSpacingMs()
    end
    return true
end

function Presentation.PlayBroadcast(payload)
    local result = payload and payload.result or nil
    local broadcast = result and result.radioBroadcast or nil
    local notificationID = result and tostring(result.notificationID or "")
    local eventType = result and result.eventType
        or broadcast and broadcast.eventType or "discovery"
    local isAmbient = eventType == "ambient"
    if not Message or type(Message.New) ~= "function"
        or type(Message.Publish) ~= "function"
        or type(broadcast) ~= "table"
        or type(broadcast.lines) ~= "table"
        or notificationID == ""
        or not activeRadio()
        or Presentation.pendingNotificationIDs[notificationID]
        or #Presentation.pendingBroadcasts >= MAX_PENDING_BROADCASTS
    then
        return false
    end
    if isAmbient then
        for _, pending in ipairs(Presentation.pendingBroadcasts) do
            if pending.eventType == "ambient" then return false end
        end
    end
    local speech = type(broadcast.speech) == "table"
        and broadcast.speech or {
            effect_profile = "radio",
            environment = "normal",
            intensity = 0.85,
        }
    -- Make the non-overlap contract explicit for the Core/PBrainZ bridge;
    -- the client queue below also prevents a burst before the bridge sees it.
    if speech.mode == nil then speech.mode = "RESPONSE" end
    if speech.allow_overlap == nil then speech.allow_overlap = false end
    if speech.can_interrupt == nil then speech.can_interrupt = false end
    local lines = {}
    for _, line in ipairs(broadcast.lines) do
        if broadcastLineText(line) ~= "" then
            lines[#lines + 1] = line
        end
    end
    if #lines == 0 then return false end
    Presentation.pendingNotificationIDs[notificationID] = true
    local item = {
        broadcast = broadcast,
        lines = lines,
        eventType = eventType,
        notificationID = notificationID,
        speech = speech,
        index = 1,
        nextAt = nowMs(),
    }
    if isAmbient then
        Presentation.pendingBroadcasts[#Presentation.pendingBroadcasts + 1] = item
    else
        table.insert(Presentation.pendingBroadcasts, 1, item)
    end
    -- Deliver the first line immediately; subsequent lines are serialized on
    -- the game tick so one discovery cannot create a TTS burst.
    Presentation.Update()
    return true
end

local function noticeKey(result)
    if (tonumber(result.phase) or 0) >= 2 then
        return result.kind == "settlement"
            and "UI_PNC_DiscoveryLocatedSettlement"
            or "UI_PNC_DiscoveryLocatedMobileGroup"
    end
    if result.kind == "settlement" then
        return "UI_PNC_DiscoveryFoundSettlement"
    end
    local groupType = string.upper(tostring(result.groupType or ""))
    if groupType == "REFUGEE" then
        return "UI_PNC_DiscoveryFoundRefugees"
    elseif groupType == "LOOTER" then
        return "UI_PNC_DiscoveryFoundLooters"
    elseif groupType == "TRADER" then
        return "UI_PNC_DiscoveryFoundTraders"
    end
    return "UI_PNC_DiscoveryFoundMobileGroup"
end

function Presentation.ShowResult(payload)
    local result = payload and payload.result
    local notificationID = result and tostring(result.notificationID or "")
    if not result or result.ok ~= true or notificationID == ""
        or notificationID == Presentation.lastNotificationID
    then return false end
    Presentation.lastNotificationID = notificationID
    if result.eventType == "ambient" then
        return Presentation.PlayBroadcast(payload)
    end
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player or not HaloTextHelper
        or not HaloTextHelper.addTextWithArrow
    then return false end
    local key = noticeKey(result)
    HaloTextHelper.addTextWithArrow(
        player, tr(key, "Radio signal discovered"), true,
        HaloTextHelper.getColorGreen()
    )
    if result.identityRevealed == true then
        HaloTextHelper.addTextWithArrow(
            player,
            tr("UI_PNC_DiscoveryIdentityLearned", "Radio contact identified"),
            true, HaloTextHelper.getColorGreen()
        )
    end
    Presentation.PlayBroadcast(payload)
    return true
end

local function resetPresentationQueue()
    Presentation.pendingBroadcasts = {}
    Presentation.pendingNotificationIDs = {}
end

if Events and Events.OnResetLua and Events.OnResetLua.Add
    and not Presentation._resetHookInstalled
then
    Events.OnResetLua.Add(resetPresentationQueue)
    Presentation._resetHookInstalled = true
end

if Events and Events.OnTick and Events.OnTick.Add
    and not Presentation._tickInstalled
then
    Events.OnTick.Add(Presentation.Update)
    Presentation._tickInstalled = true
end

if CustomRadio and CustomRadio.RegisterListener and ScanChannel then
    CustomRadio.RegisterListener(ScanChannel.ID,
        "projecthoomans.discovery", function(context)
            local settings = PNC.Sandbox
            if settings and type(settings.RadioDiscoveryEnabled) == "function"
                and settings.RadioDiscoveryEnabled() ~= true
            then
                return true
            end
            local player = context and context.player
            local key = player and player.getUsername
                and tostring(player:getUsername())
                or tostring(context and context.playerNum or 0)
            local at = tonumber(context and context.now) or PNC.Core.Now()
            local previous = lastProbeAt[key]
            if previous and at - previous < PROBE_INTERVAL_MS then return true end
            lastProbeAt[key] = at
            if PNC.Client and PNC.Client.RequestWorldDiscovery then
                PNC.Client.RequestWorldDiscovery("radio_scan", {
                    channelID = ScanChannel.ID,
                    frequency = ScanChannel.FREQUENCY,
                })
                if ambientEnabled() then
                    local ambientPrevious = lastAmbientProbeAt[key]
                    if not ambientPrevious then
                        lastAmbientProbeAt[key] = at
                    elseif at - ambientPrevious >= ambientIntervalMs() then
                        lastAmbientProbeAt[key] = at
                        PNC.Client.RequestWorldDiscovery("radio_ambient", {
                            channelID = ScanChannel.ID,
                            frequency = ScanChannel.FREQUENCY,
                        })
                    end
                end
            end
            return true
        end)
end

if RadioActions and RadioActions.Register then
    RadioActions.Register({
        id = "projecthoomans.contacts",
        label = tr("UI_PNC_Contacts", "Contacts"),
        signalLabel = tr("UI_PNC_Contacts", "Contacts"),
        placement = RadioActions.PLACEMENT_SIGNAL
            or "psychopatz.radio.signal",
        order = 90,
        isAvailable = function()
            return PNC.ContactsUI and PNC.ContactsUI.Open ~= nil
        end,
        onClick = function()
            PNC.ContactsUI.Open()
            return true
        end,
    })
    RadioActions.Register({
        id = "projecthoomans.colony_management",
        label = tr("UI_PNC_ColonyManagement", "Colony Management"),
        signalLabel = tr(
            "UI_PNC_ColonyManagement",
            "Colony Management"
        ),
        placement = RadioActions.PLACEMENT_SIGNAL or "psychopatz.radio.signal",
        order = 100,
        isAvailable = function()
            return PNC.ColonyManagementUI and PNC.ColonyManagementUI.Open ~= nil
        end,
        onClick = function()
            PNC.ColonyManagementUI.Open()
            return true
        end,
    })
end

return RadioActions
