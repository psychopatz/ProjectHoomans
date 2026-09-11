local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "root", "")

package.preload["PsychopatzCore/UI/Radio/PsychopatzRadioSignalHost"] =
    function() return {} end
package.preload["PsychopatzCore/Radio/PsychopatzCustomRadioClient"] =
    function() return {} end

local listener
local halos = {}
local published = {}
local requests = {}
local clock = 0
local player = {}
PsychopatzCore = {
    Conversation = {
        Message = {
            New = function(spec) return spec end,
            Publish = function(message) published[#published + 1] = message end,
        },
    },
    CustomRadio = {
        RegisterListener = function(_, _, callback) listener = callback end,
    },
    RadioActions = { PLACEMENT_SIGNAL = "signal", Register = function() end },
}
PNC = {
    VoiceGateway = {
        GetNPCBinding = function(npcID)
            if npcID == "npc_one" then
                return { npc_uuid = npcID, slot = "VoiceFemale:1", pitch = -2 }
            end
            return { npc_uuid = npcID, slot = "VoiceMale:1", pitch = 3 }
        end,
    },
    Core = { Now = function() return 0 end },
    RadioDiscoveryChannel = {
        ID = "projecthoomans.frequency_scan", FREQUENCY = 69000,
    },
    Client = {
        RequestWorldDiscovery = function(action)
            requests[#requests + 1] = action
        end,
    },
    ContactsUI = { Open = function() end },
    ColonyManagementUI = { Open = function() end },
}
getText = function(key)
    local values = {
        UI_PNC_DiscoveryFoundSettlement = "Found an enclave",
        UI_PNC_DiscoveryIdentityLearned = "Radio contact identified",
    }
    return values[key] or key
end
getSpecificPlayer = function() return player end
getTimeInMillis = function() return clock end
HaloTextHelper = {
    getColorGreen = function() return "green" end,
    addTextWithArrow = function(target, value, positive, color)
        halos[#halos + 1] = {
            target = target, value = value,
            positive = positive, color = color,
        }
    end,
}

T.load(ROOT .. "client/PNC/Integrations/PNC_PsychopatzCoreRadio.lua")
T.equal(type(listener), "function", "scan listener registers")
listener({ player = player, playerNum = 0, now = 0 })
listener({ player = player, playerNum = 0, now = 40000 })
listener({ player = player, playerNum = 0, now = 80000 })
T.equal(#requests, 3,
    "radio polling does not request ambient chatter before its interval")
listener({ player = player, playerNum = 0, now = 120000 })
T.equal(requests[4], "radio_scan",
    "the normal discovery probe remains separate from ambience")
T.equal(requests[5], "radio_ambient",
    "ambient chatter is requested only after its independent interval")
T.equal(PNC.RadioDiscoveryPresentation.ShowResult({ result = {
    ok = true, notificationID = "settlement:1:1",
    kind = "settlement", phase = 1, identityRevealed = true,
} }), true, "successful discovery displays feedback")
T.equal(halos[1].value, "Found an enclave",
    "discovery uses a native-style positive arrow notification")
T.equal(halos[2].value, "Radio contact identified",
    "identity introduction displays separate feedback")
T.equal(#published, 0, "radio speech waits for a successful broadcast payload")
T.equal(PNC.RadioDiscoveryPresentation.ShowResult({ result = {
    ok = true, notificationID = "settlement:2:1",
    kind = "settlement", phase = 1,
    radioBroadcast = {
        speech = { effect_profile = "radio", intensity = 0.85 },
        speakerNPCID = "npc_one",
        secondarySpeakerNPCID = "npc_two",
        lines = {
            { text = "<wzzt>" },
            {
                text = "Mayday, mayday.",
                speakerRole = "primary",
                speakerNPCID = "npc_one",
            },
            {
                text = "Tell them about the wounded.",
                speakerRole = "secondary",
                speakerNPCID = "npc_two",
            },
        },
    },
} }), true, "broadcast result displays feedback")
T.equal(#published, 1,
    "successful scan starts one radio line without a TTS burst")
T.equal(published[1].text, "Mayday, mayday.",
    "radio labels are not sent to TTS")
T.equal(published[1].speakerID, "npc_one",
    "primary radio line retains its internal speaker identity")
T.equal(published[1].speakerName, nil,
    "radio does not publish a player-facing speaker name")
T.equal(published[1].voiceBinding.slot, "VoiceFemale:1",
    "primary radio line resolves the selected NPC voice")
T.equal(published[1].presentationState.speech.effect_profile, "radio",
    "radio broadcast selects the radio DSP profile")
T.equal(published[1].presentationState.speech.allow_overlap, false,
    "radio speech explicitly disallows overlapping utterances")
T.equal(published[1].presentationState.speech.can_interrupt, false,
    "radio speech cannot interrupt an active utterance")
clock = 2000
PNC.RadioDiscoveryPresentation.Update()
T.equal(#published, 2,
    "the next radio line is released after the configured spacing")
T.equal(published[2].text, "Tell them about the wounded.",
    "serialized radio playback preserves line order")
T.equal(published[2].speakerID, "npc_two",
    "secondary radio line retains its internal speaker identity")
T.equal(published[2].voiceBinding.slot, "VoiceMale:1",
    "secondary radio line resolves a separate NPC voice")

T.equal(PNC.RadioDiscoveryPresentation.ShowResult({ result = {
    ok = true, notificationID = "settlement:2:1",
    kind = "settlement", phase = 1,
} }), false, "replayed snapshots do not duplicate feedback")
T.equal(#halos, 3, "duplicate notification produces no extra halo")

local ambientShown = PNC.RadioDiscoveryPresentation.ShowResult({ result = {
    ok = true, eventType = "ambient", notificationID = "ambient:2:20",
    radioBroadcast = {
        eventType = "ambient",
        speech = { effect_profile = "radio", intensity = 0.7 },
        speakerNPCID = "radio:ambient:2:primary",
        secondarySpeakerNPCID = "radio:ambient:2:secondary",
        lines = {
            {
                text = "Static on the line.",
                speakerRole = "primary",
                speakerNPCID = "radio:ambient:2:primary",
            },
            {
                text = "Say again?",
                speakerRole = "secondary",
                speakerNPCID = "radio:ambient:2:secondary",
            },
        },
    },
} })
T.equal(ambientShown, true,
    "ambient broadcast is playable through the existing radio queue")
T.equal(#halos, 3,
    "ambient chatter does not create a discovery notification")
T.equal(#published, 3,
    "ambient chatter publishes its first line without a TTS burst")
T.equal(published[3].presentationState.speech.effect_profile, "radio",
    "ambient chatter uses the radio DSP profile")
T.finish("pnc_radio_discovery_presentation_smoke")

T.finish("pnc_radio_discovery_presentation_smoke")
