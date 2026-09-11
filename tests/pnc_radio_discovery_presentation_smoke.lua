local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "root", "")

package.preload["PsychopatzCore/UI/Radio/PsychopatzRadioSignalHost"] =
    function() return {} end
package.preload["PsychopatzCore/Radio/PsychopatzCustomRadioClient"] =
    function() return {} end

local listener
local halos = {}
local published = {}
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
    Core = { Now = function() return 0 end },
    RadioDiscoveryChannel = {
        ID = "projecthoomans.frequency_scan", FREQUENCY = 69000,
    },
    Client = { RequestWorldDiscovery = function() end },
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
        lines = { "<wzzt>", "Unknown voice: Mayday, mayday." },
    },
} }), true, "broadcast result displays feedback")
T.equal(#published, 1, "successful scan publishes one speakable radio line")
T.equal(published[1].text, "Unknown voice: Mayday, mayday.",
    "radio noise markers are not sent to TTS")
T.equal(published[1].presentationState.speech.effect_profile, "radio",
    "radio broadcast selects the radio DSP profile")
T.equal(published[1].voiceBinding.slot, "VoiceMale:0",
    "radio broadcast supplies a fallback voice binding")
T.equal(PNC.RadioDiscoveryPresentation.ShowResult({ result = {
    ok = true, notificationID = "settlement:2:1",
    kind = "settlement", phase = 1,
} }), false, "replayed snapshots do not duplicate feedback")
T.equal(#halos, 3, "duplicate notification produces no extra halo")
T.finish("pnc_radio_discovery_presentation_smoke")

T.finish("pnc_radio_discovery_presentation_smoke")
