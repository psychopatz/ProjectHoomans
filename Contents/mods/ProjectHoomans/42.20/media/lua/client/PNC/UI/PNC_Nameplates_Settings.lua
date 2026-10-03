local Nameplates = PNC.Nameplates

PNC.SettingsStore = PNC.SettingsStore or PsychopatzCore.Settings.Open(
    "ProjectHoomans",
    {
        fileName = "ProjectHoomans_Config.txt",
        defaults = {
            enabled = true,
            showStealthIndicator = true,
            showNameplateDebug = false,
            showAIDebug = false,
            showCampDebug = false,
            showPathDebug = false,
            showCombatDebug = false,
            showZombieDebug = false,
            showFactionDebug = false,
            showCommunityDebug = false,
            showAnimationDebug = false,
            showAnimationSceneDebug = false,
            debugShowPresence = true,
            debugShowAI = true,
            debugShowJob = true,
            debugShowOrder = true,
            debugShowTarget = true,
            debugShowCombat = true,
            debugShowMagazine = true,
            debugShowStamina = true,
            debugShowBlock = true,
            debugShowInfection = true,
            debugShowAnimation = true,
            storageTransactionLogging = false,
            relationshipFeedbackScale = 1.0,
            nameplateTextScale = 1.0,
            nameplateBarScale = 1.0,
        },
    }
)

Nameplates.Settings = PNC.SettingsStore.values
local Settings = Nameplates.Settings
if Settings.enabled == nil then Settings.enabled = true end
if Settings.showStealthIndicator == nil then
    Settings.showStealthIndicator = true
end

local function normalizeNameplateDebugSetting()
    local legacyNameplateDebug = Settings.showAIDebug
    if legacyNameplateDebug == true and Settings.showNameplateDebug ~= true then
        Settings.showNameplateDebug = true
        PNC.SettingsStore:Set("showNameplateDebug", true, false)
        PNC.SettingsStore:Set("showAIDebug", false, true)
    end
    if Settings.showNameplateDebug == nil then
        Settings.showNameplateDebug = false
    end
    if Settings.showAIDebug == nil then Settings.showAIDebug = false end
    Settings.showAIDebug = Settings.showNameplateDebug
    local pncSettings = PNC.Settings
    local options = pncSettings and pncSettings.Options or nil
    local option = options and options.getOption
        and options:getOption("showNameplateDebug") or nil
    if option and type(option.setValue) == "function" then
        option:setValue(Settings.showNameplateDebug)
    elseif option and option.value ~= nil then
        option.value = Settings.showNameplateDebug
    end
end

normalizeNameplateDebugSetting()
for _, key in ipairs({
    "showCampDebug", "showPathDebug", "showCombatDebug", "showZombieDebug",
    "showFactionDebug", "showCommunityDebug", "showAnimationDebug",
    "showAnimationSceneDebug",
}) do
    if Settings[key] == nil then Settings[key] = false end
end
for key, value in pairs({
    debugShowPresence = true,
    debugShowAI = true,
    debugShowJob = true,
    debugShowOrder = true,
    debugShowTarget = true,
    debugShowCombat = true,
    debugShowMagazine = true,
    debugShowStamina = true,
    debugShowBlock = true,
    debugShowInfection = true,
    debugShowAnimation = true,
    storageTransactionLogging = false,
}) do
    if Settings[key] == nil then Settings[key] = value end
end
for _, key in ipairs({
    "relationshipFeedbackScale", "nameplateTextScale", "nameplateBarScale",
}) do
    if Settings[key] == nil then Settings[key] = 1.0 end
end

Nameplates.State = Nameplates.State or { managers = {} }
Nameplates.Internal = Nameplates.Internal or {}
Nameplates.Internal.NormalizeDebugSetting = normalizeNameplateDebugSetting
