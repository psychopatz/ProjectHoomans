local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/"

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

package.preload["PsychopatzCore/UI/Radio/PsychopatzRadioSignalHost"] =
    function() return {} end
package.preload["PsychopatzCore/Radio/PsychopatzCustomRadioClient"] =
    function() return {} end

local listener
local halos = {}
local player = {}
PsychopatzCore = {
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

dofile(ROOT .. "client/PNC/Integrations/PNC_PsychopatzCoreRadio.lua")
equal(type(listener), "function", "scan listener registers")
equal(PNC.RadioDiscoveryPresentation.ShowResult({ result = {
    ok = true, notificationID = "settlement:1:1",
    kind = "settlement", phase = 1, identityRevealed = true,
} }), true, "successful discovery displays feedback")
equal(halos[1].value, "Found an enclave",
    "discovery uses a native-style positive arrow notification")
equal(halos[2].value, "Radio contact identified",
    "identity introduction displays separate feedback")
equal(PNC.RadioDiscoveryPresentation.ShowResult({ result = {
    ok = true, notificationID = "settlement:1:1",
    kind = "settlement", phase = 1,
} }), false, "replayed snapshots do not duplicate feedback")
equal(#halos, 2, "duplicate notification produces no extra halo")

print("pnc_radio_discovery_presentation_smoke: ok")
