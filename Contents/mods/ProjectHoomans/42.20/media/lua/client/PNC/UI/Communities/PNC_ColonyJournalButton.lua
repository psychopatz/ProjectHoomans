require "PsychopatzCore/UI/PsychopatzUI"
require "PsychopatzCore/Radio/PC_RadioDeviceState"

PNC = PNC or {}
PNC.ColonyJournalButton = PNC.ColonyJournalButton or {}

local ButtonAPI = PNC.ColonyJournalButton
local Sidebar = PsychopatzCore.UI.Sidebar
local RadioDeviceState = PsychopatzCore.RadioDeviceState
local ICON_ON = "Item_WalkieTalkieCivilian"   -- Base.WalkieTalkie2
local ICON_OFF = "Item_WalkieTalkieCivilian2" -- Base.WalkieTalkie3
local ICONS = {}

local function icon(name)
    if ICONS[name] ~= nil then return ICONS[name] end
    local texture = getTexture and getTexture(name) or nil
    -- Do not permanently cache an early-load miss. PZ may initialize the
    -- sidebar before the RadioIcons atlas is available.
    if texture then ICONS[name] = texture end
    return texture
end

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function activeRadio()
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    return RadioDeviceState.FindActivePlayerDevice(player) ~= nil
end

local function radioIcon()
    return icon(activeRadio() and ICON_ON or ICON_OFF)
end

function ButtonAPI.onClick()
    if not activeRadio() then return end
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
        tooltip = function()
            local active = activeRadio()
            return active
                and tr("UI_PNC_ColonyJournal_Open", "Open colony journal")
                or tr("UI_PNC_ColonyJournal_RequiresRadio",
                    "Requires an active, powered, audible walkie-talkie")
        end,
        enabled = activeRadio,
        variant = "primary",
        disabledVariant = "quiet",
        displayBackground = false,
        onClick = ButtonAPI.onClick,
    })
end

return ButtonAPI
