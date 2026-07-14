require "PsychopatzCore/UI/PsychopatzSettingsWindow"

PNC.Settings = PNC.Settings or {}

local Settings = PNC.Settings
local Registry = PsychopatzCore.InGameSettings

local function setAIDebug(value)
    value = value == true
    PNC.Nameplates.Settings.showAIDebug = value
    PNC.SettingsStore:Set("showAIDebug", value, true)
    PNC.Runtime = PNC.Runtime or {}
    PNC.Runtime.debugEnabled = value
end

local function setPathDebug(value)
    value = value == true
    PNC.Nameplates.Settings.showPathDebug = value
    PNC.SettingsStore:Set("showPathDebug", value, true)
end

Registry.Register({
    id = "ProjectHoomans",
    title = "Project Hoomans Settings",
    store = PNC.SettingsStore,
    controls = {
        {
            id = "showAIDebug",
            type = "boolean",
            label = "Show NPC AI debug overlay",
            get = function() return PNC.Nameplates.Settings.showAIDebug == true end,
            set = setAIDebug,
        },
        {
            id = "showPathDebug",
            type = "boolean",
            label = "Show NPC path overlay",
            get = function() return PNC.Nameplates.Settings.showPathDebug == true end,
            set = setPathDebug,
        },
    },
    window = {
        anchor = "center",
        responsiveSpec = {
            width = 560,
            height = 360,
            minWidth = 420,
            minHeight = 280,
            maxWidth = 760,
            maxHeight = 620,
        },
    },
})

function Settings.Open()
    return Registry.Open("ProjectHoomans")
end

function Settings.Toggle()
    return Registry.Toggle("ProjectHoomans")
end

return Settings
