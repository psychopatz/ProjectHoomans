require "PZAPI/ModOptions"

PNC.Settings = PNC.Settings or {}

local Settings = PNC.Settings
local ModOptions = PZAPI and PZAPI.ModOptions or nil

local function setAIDebug(value)
    value = value == true
    PNC.Nameplates.Settings.showAIDebug = value
    PNC.SettingsStore:Set("showAIDebug", value, true)
    PNC.Runtime = PNC.Runtime or {}
    PNC.Runtime.debugEnabled = value
end

local function setStoredFlag(id, value)
    value = value == true
    PNC.Nameplates.Settings[id] = value
    PNC.SettingsStore:Set(id, value, true)
end

local function currentFlag(id, fallback)
    local value = PNC.Nameplates.Settings[id]
    if value == nil then return fallback == true end
    return value == true
end

local definitions = {
    {
        id = "showAIDebug",
        label = "UI_PNC_Settings_ShowAIDebug",
        get = function() return currentFlag("showAIDebug", false) end,
        set = setAIDebug,
    },
    {
        id = "showCampDebug",
        label = "UI_PNC_Settings_ShowCampDebug",
        get = function() return currentFlag("showCampDebug", false) end,
    },
    {
        id = "showPathDebug",
        label = "UI_PNC_Settings_ShowPathDebug",
        get = function() return currentFlag("showPathDebug", false) end,
    },
    {
        id = "showCombatDebug",
        label = "UI_PNC_Settings_ShowCombatDebug",
        get = function() return currentFlag("showCombatDebug", false) end,
    },
    {
        id = "showFactionDebug",
        label = "UI_PNC_Settings_ShowFactionDebug",
        get = function()
            return currentFlag("showFactionDebug", false)
        end,
    },
    {
        id = "showCommunityDebug",
        label = "UI_PNC_Settings_ShowCommunityDebug",
        get = function()
            return currentFlag("showCommunityDebug", false)
        end,
    },
    {
        id = "showAnimationDebug",
        label = "UI_PNC_Settings_ShowAnimationDebug",
        get = function() return currentFlag("showAnimationDebug", false) end,
    },
    {
        id = "showAnimationSceneDebug",
        label = "UI_PNC_Settings_ShowAnimationSceneDebug",
        get = function()
            return currentFlag("showAnimationSceneDebug", false)
        end,
    },
    {
        id = "debugShowPresence",
        label = "UI_PNC_Settings_DebugPresence",
        get = function() return currentFlag("debugShowPresence", true) end,
    },
    {
        id = "debugShowAI",
        label = "UI_PNC_Settings_DebugAI",
        get = function() return currentFlag("debugShowAI", true) end,
    },
    {
        id = "debugShowJob",
        label = "UI_PNC_Settings_DebugJob",
        get = function() return currentFlag("debugShowJob", true) end,
    },
    {
        id = "debugShowOrder",
        label = "UI_PNC_Settings_DebugOrder",
        get = function() return currentFlag("debugShowOrder", true) end,
    },
    {
        id = "debugShowTarget",
        label = "UI_PNC_Settings_DebugTarget",
        get = function() return currentFlag("debugShowTarget", true) end,
    },
    {
        id = "debugShowCombat",
        label = "UI_PNC_Settings_DebugCombat",
        get = function() return currentFlag("debugShowCombat", true) end,
    },
    {
        id = "debugShowMagazine",
        label = "UI_PNC_Settings_DebugMagazine",
        get = function() return currentFlag("debugShowMagazine", true) end,
    },
    {
        id = "debugShowStamina",
        label = "UI_PNC_Settings_DebugStamina",
        get = function() return currentFlag("debugShowStamina", true) end,
    },
    {
        id = "debugShowBlock",
        label = "UI_PNC_Settings_DebugBlock",
        get = function() return currentFlag("debugShowBlock", true) end,
    },
    {
        id = "debugShowInfection",
        label = "UI_PNC_Settings_DebugInfection",
        get = function() return currentFlag("debugShowInfection", true) end,
    },
    {
        id = "debugShowAnimation",
        label = "UI_PNC_Settings_DebugAnimation",
        get = function() return currentFlag("debugShowAnimation", true) end,
    },
    {
        id = "storageTransactionLogging",
        label = "UI_PNC_Settings_StorageTransactionLogging",
        get = function()
            return currentFlag("storageTransactionLogging", false)
        end,
    },
}

local function applyDefinition(definition, value)
    if definition.set then
        definition.set(value)
    else
        setStoredFlag(definition.id, value)
    end
end

local function optionApplyHandler(definition)
    return function(_, value)
        applyDefinition(definition, value)
    end
end

if ModOptions and not Settings.nativeRegistered then
    local options = ModOptions:getOptions("ProjectHoomans")
        or ModOptions:create(
            "ProjectHoomans",
            "UI_PNC_Settings_Title"
        )
    options:addTitle("UI_PNC_Settings_OverlaySection")
    local index
    for index = 1, #definitions do
        if index == 8 then
            options:addSeparator()
            options:addTitle("UI_PNC_Settings_OverlayPartsSection")
        end
        if index == 20 then
            options:addSeparator()
            options:addTitle("UI_PNC_Settings_LoggingSection")
        end
        local definition = definitions[index]
        local option = options:addTickBox(
            definition.id,
            definition.label,
            definition.get()
        )
        option.onChangeApply = optionApplyHandler(definition)
    end
    local inheritedApply = options.apply
    function options:apply()
        if inheritedApply then inheritedApply(self) end
        local definition
        for index = 1, #definitions do
            definition = definitions[index]
            local option = self:getOption(definition.id)
            if option then
                applyDefinition(definition, option:getValue())
            end
        end
    end
    Settings.Options = options
    Settings.nativeRegistered = true
end

-- Kept as a small compatibility surface for callers. The actual presentation
-- is now owned by Project Zomboid's Options > Mods page.
function Settings.Open()
    return Settings.Options
end

function Settings.Toggle()
    return Settings.Options
end

return Settings
