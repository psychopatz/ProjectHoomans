require "PsychopatzCore/UI/PsychopatzUI"
require "PsychopatzCore/Radio/PC_RadioDeviceState"

PNC = PNC or {}
PNC.ColonyJournalButton = PNC.ColonyJournalButton or {}

local ButtonAPI = PNC.ColonyJournalButton
local Sidebar = PsychopatzCore.UI.Sidebar
local RadioDeviceState = PsychopatzCore.RadioDeviceState
local RadioImageAnimation = PsychopatzCore.RadioImageAnimation
local radioAnimation = RadioImageAnimation
    and RadioImageAnimation.New({
        offPath = "media/ui/Radio/Signal_found/2.png",
        searchPrefix = "media/ui/Radio/Signal_search/",
        frameCount = 5,
        frameDuration = 200,
    }) or nil

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function activeRadio()
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    return RadioDeviceState.FindActivePlayerDevice(player) ~= nil
end

local function hasRadio()
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    return RadioDeviceState.HasPlayerDevice(player)
end

local function radioIcon()
    return radioAnimation and radioAnimation:GetTexture(activeRadio()) or nil
end

-- This is the single sidebar access point for the colony UI.  The journal is
-- now opened from the hub's Events action, so the journal/radio icon opens the
-- hub instead of creating a second text-labelled sidebar button.
function ButtonAPI.onClick()
    local hub = PNC.CommandHub
    if hub and type(hub.Toggle) == "function" then
        return hub.Toggle()
    end
    return false
end

-- Public predicates are shared by the sidebar entry and hub actions.  Keep
-- the gate based on radio possession, not active signal, so the hub remains
-- usable while the journal is waiting for a powered radio to sync.
ButtonAPI.HasRadio = hasRadio
ButtonAPI.IsRadioActive = activeRadio

function ButtonAPI.Refresh(host)
    return Sidebar and Sidebar.Refresh and Sidebar.Refresh(host)
end

if Sidebar and Sidebar.Register then
    ButtonAPI.registration = Sidebar.Register({
        id = "PNC.ColonyJournal",
        order = 900,
        title = "",
        image = radioIcon,
        imageRefreshInterval = 200,
        tooltip = function()
            if not hasRadio() then
                return tr("UI_PNC_CommandHub_RadioRequiredHelp",
                    "Open colony command hub (event sync requires a radio)")
            end
            local active = activeRadio()
            return active
                and tr("UI_PNC_CommandHub_OpenHelp",
                    "Open colony command hub")
                or tr("UI_PNC_CommandHub_RadioPausedHelp",
                    "Open colony command hub (radio sync paused)")
        end,
        -- The access icon must remain clickable even before a radio is
        -- available.  Availability gates belong to the functionality inside
        -- the hub, not to the only control that opens the hub.
        variant = "primary",
        disabledVariant = "quiet",
        displayBackground = false,
        onClick = ButtonAPI.onClick,
    })
end

return ButtonAPI
