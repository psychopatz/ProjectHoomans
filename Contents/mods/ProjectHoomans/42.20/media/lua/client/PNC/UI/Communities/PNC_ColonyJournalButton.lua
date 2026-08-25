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

function ButtonAPI.onClick()
    if PNC.ColonyJournalUI and PNC.ColonyJournalUI.Toggle then
        PNC.ColonyJournalUI.Toggle()
    end
end

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
            local active = activeRadio()
            return active
                and tr("UI_PNC_ColonyJournal_Open", "Open colony journal")
                or tr("UI_PNC_ColonyJournal_SyncPaused",
                    "Open colony journal (radio sync paused)")
        end,
        enabled = hasRadio,
        variant = "primary",
        disabledVariant = "quiet",
        displayBackground = false,
        onClick = ButtonAPI.onClick,
    })
end

return ButtonAPI
