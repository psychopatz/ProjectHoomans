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

local function debugPartControl(id, label)
    return {
        id = id,
        type = "boolean",
        label = label,
        get = function() return PNC.Nameplates.Settings[id] ~= false end,
        set = function(value)
            value = value == true
            PNC.Nameplates.Settings[id] = value
            PNC.SettingsStore:Set(id, value, true)
        end,
    }
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
        debugPartControl("debugShowPresence", "Overlay: presence/body binding"),
        debugPartControl("debugShowAI", "Overlay: AI state"),
        debugPartControl("debugShowJob", "Overlay: active job"),
        debugPartControl("debugShowOrder", "Overlay: current order"),
        debugPartControl("debugShowTarget", "Overlay: current target"),
        debugPartControl("debugShowCombat", "Overlay: combat mode and weapon"),
        debugPartControl("debugShowStamina", "Overlay: stamina"),
        debugPartControl("debugShowBlock", "Overlay: block reason"),
        debugPartControl("debugShowInfection", "Overlay: infection status"),
        debugPartControl("debugShowAnimation", "Overlay: animation diagnostics"),
    },
    window = {
        anchor = "center",
        responsiveSpec = {
            width = 560,
            height = 620,
            minWidth = 420,
            minHeight = 420,
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
