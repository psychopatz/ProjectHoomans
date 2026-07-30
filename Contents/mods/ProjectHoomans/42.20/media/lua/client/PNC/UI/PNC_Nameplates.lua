require "ISUI/ISUIElement"
require "PsychopatzCore/Settings/PsychopatzSettings"

PNC = PNC or {}
PNC.Nameplates = PNC.Nameplates or {}

local Nameplates = PNC.Nameplates

PNC.SettingsStore = PNC.SettingsStore or PsychopatzCore.Settings.Open("ProjectHoomans", {
    fileName = "ProjectHoomans_Config.txt",
    defaults = {
        enabled = true,
        showAIDebug = false,
        showPathDebug = false,
        showCombatDebug = false,
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
    },
})
Nameplates.Settings = PNC.SettingsStore.values
if Nameplates.Settings.enabled == nil then Nameplates.Settings.enabled = true end
if Nameplates.Settings.showAIDebug == nil then Nameplates.Settings.showAIDebug = false end
if Nameplates.Settings.showPathDebug == nil then Nameplates.Settings.showPathDebug = false end
if Nameplates.Settings.showCombatDebug == nil then Nameplates.Settings.showCombatDebug = false end
if Nameplates.Settings.showFactionDebug == nil then
    Nameplates.Settings.showFactionDebug = false
end
if Nameplates.Settings.showCommunityDebug == nil then
    Nameplates.Settings.showCommunityDebug = false
end
if Nameplates.Settings.showAnimationDebug == nil then Nameplates.Settings.showAnimationDebug = false end
if Nameplates.Settings.showAnimationSceneDebug == nil then
    Nameplates.Settings.showAnimationSceneDebug = false
end
local debugSettingDefaults = {
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
}
for key, value in pairs(debugSettingDefaults) do
    if Nameplates.Settings[key] == nil then Nameplates.Settings[key] = value end
end
Nameplates.State = Nameplates.State or {
    managers = {},
}

require "PNC/UI/Nameplates/PNC_NameplatePresentation"
require "PNC/UI/Nameplates/PNC_NameplateDebug"
require "PNC/UI/Nameplates/PNC_NameplateBodies"
require "PNC/UI/Nameplates/PNC_NameplateEntries"
require "PNC/UI/Nameplates/PNC_NameplateRenderer"

local Settings = Nameplates.Settings
local State = Nameplates.State
local Debug = PNC.NameplateDebug
local Entries = PNC.NameplateEntries
local Renderer = PNC.NameplateRenderer

ISPNCNameplateManager = ISUIElement:derive("ISPNCNameplateManager")

function ISPNCNameplateManager:initialise()
    ISUIElement.initialise(self)
end

function ISPNCNameplateManager:prerender()
    self:setStencilRect(0, 0, self.renderWidth, self.renderHeight)
end

function ISPNCNameplateManager:update()
    Entries.Refresh(self, Settings)
end

function ISPNCNameplateManager:render()
    Renderer.Render(self, Settings)
end

function ISPNCNameplateManager:new(playerIndex, player)
    local x = getPlayerScreenLeft(playerIndex)
    local y = getPlayerScreenTop(playerIndex)
    local width = getPlayerScreenWidth(playerIndex)
    local height = getPlayerScreenHeight(playerIndex)
    local o = ISUIElement:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.playerIndex = playerIndex
    o.player = player
    o.active = true
    o.renderWidth = width
    o.renderHeight = height
    o.entries = {}
    o.updateCounter = 0
    o:setCapture(false)
    return o
end

function Nameplates.IsDebugEnabled()
    return Settings.showAIDebug == true
end

function Nameplates.ToggleDebug()
    local player = getSpecificPlayer(0)
    Settings.showAIDebug = not Settings.showAIDebug
    PNC.SettingsStore:Set("showAIDebug", Settings.showAIDebug, true)
    PNC.Runtime = PNC.Runtime or {}
    PNC.Runtime.debugEnabled = Settings.showAIDebug == true
    if player and HaloTextHelper and HaloTextHelper.addText then
        local messageKey = Settings.showAIDebug and "UI_PNC_AIOverlayEnabled" or "UI_PNC_AIOverlayDisabled"
        HaloTextHelper.addText(player, getText(messageKey))
    end
    return Settings.showAIDebug
end

function Nameplates.IsPathDebugEnabled()
    return Settings.showPathDebug == true
end

function Nameplates.TogglePathDebug()
    local player = getSpecificPlayer(0)
    Settings.showPathDebug = not Settings.showPathDebug
    PNC.SettingsStore:Set("showPathDebug", Settings.showPathDebug, true)
    if player and HaloTextHelper and HaloTextHelper.addText then
        local messageKey = Settings.showPathDebug and "UI_PNC_PathOverlayEnabled" or "UI_PNC_PathOverlayDisabled"
        HaloTextHelper.addText(player, getText(messageKey))
    end
    return Settings.showPathDebug
end

function Nameplates.IsCombatDebugEnabled()
    return Settings.showCombatDebug == true
end

function Nameplates.IsFactionDebugEnabled()
    return Settings.showFactionDebug == true
end

function Nameplates.SetFactionDebugEnabled(enabled, announce)
    local player = getSpecificPlayer(0)
    Settings.showFactionDebug = enabled == true
    PNC.SettingsStore:Set(
        "showFactionDebug",
        Settings.showFactionDebug,
        true
    )
    if announce ~= false
        and player
        and HaloTextHelper
        and HaloTextHelper.addText
    then
        HaloTextHelper.addText(
            player,
            getText(
                Settings.showFactionDebug
                    and "UI_PNC_FactionOverlayEnabled"
                    or "UI_PNC_FactionOverlayDisabled"
            )
        )
    end
    return Settings.showFactionDebug
end

function Nameplates.ToggleFactionDebug()
    return Nameplates.SetFactionDebugEnabled(
        not Settings.showFactionDebug,
        true
    )
end

function Nameplates.IsCommunityDebugEnabled()
    return Settings.showCommunityDebug == true
end

function Nameplates.SetCommunityDebugEnabled(enabled, announce)
    local player = getSpecificPlayer(0)
    Settings.showCommunityDebug = enabled == true
    PNC.SettingsStore:Set(
        "showCommunityDebug",
        Settings.showCommunityDebug,
        true
    )
    if announce ~= false
        and player
        and HaloTextHelper
        and HaloTextHelper.addText
    then
        HaloTextHelper.addText(
            player,
            getText(
                Settings.showCommunityDebug
                    and "UI_PNC_CommunityOverlayEnabled"
                    or "UI_PNC_CommunityOverlayDisabled"
            )
        )
    end
    return Settings.showCommunityDebug
end

function Nameplates.ToggleCommunityDebug()
    return Nameplates.SetCommunityDebugEnabled(
        not Settings.showCommunityDebug,
        true
    )
end

function Nameplates.ToggleCombatDebug()
    local player = getSpecificPlayer(0)
    Settings.showCombatDebug = not Settings.showCombatDebug
    PNC.SettingsStore:Set(
        "showCombatDebug",
        Settings.showCombatDebug,
        true
    )
    if player and HaloTextHelper and HaloTextHelper.addText then
        local messageKey = Settings.showCombatDebug
            and "UI_PNC_CombatOverlayEnabled"
            or "UI_PNC_CombatOverlayDisabled"
        HaloTextHelper.addText(player, getText(messageKey))
    end
    return Settings.showCombatDebug
end

function Nameplates.IsAnimationDebugEnabled()
    return Settings.showAnimationDebug == true
end

function Nameplates.ToggleAnimationDebug()
    local player = getSpecificPlayer(0)
    Settings.showAnimationDebug = not Settings.showAnimationDebug
    PNC.SettingsStore:Set(
        "showAnimationDebug",
        Settings.showAnimationDebug,
        true
    )
    if player and HaloTextHelper and HaloTextHelper.addText then
        HaloTextHelper.addText(
            player,
            Settings.showAnimationDebug
                and "PNC animation tracks enabled"
                or "PNC animation tracks disabled"
        )
    end
    return Settings.showAnimationDebug
end

function Nameplates.IsAnimationSceneDebugEnabled()
    return Settings.showAnimationSceneDebug == true
end

function Nameplates.ToggleAnimationSceneDebug()
    local player = getSpecificPlayer(0)
    Settings.showAnimationSceneDebug =
        not Settings.showAnimationSceneDebug
    PNC.SettingsStore:Set(
        "showAnimationSceneDebug",
        Settings.showAnimationSceneDebug,
        true
    )
    if player and HaloTextHelper and HaloTextHelper.addText then
        HaloTextHelper.addText(
            player,
            Settings.showAnimationSceneDebug
                and "PNC scene overlay enabled"
                or "PNC scene overlay disabled"
        )
    end
    return Settings.showAnimationSceneDebug
end

function Nameplates.DebugDescribeSnapshot(snapshot)
    return Debug.DescribeSnapshot(snapshot)
end

local function initForPlayer(playerIndex)
    local player = getSpecificPlayer(playerIndex)
    if not player or State.managers[playerIndex] then return end
    local manager = ISPNCNameplateManager:new(playerIndex, player)
    manager:initialise()
    State.managers[playerIndex] = manager
end

local function onCreatePlayer(playerIndex)
    initForPlayer(playerIndex)
end

local function onGameStart()
    PNC.Runtime = PNC.Runtime or {}
    PNC.Runtime.debugEnabled = Settings.showAIDebug == true
    for i = 0, getNumActivePlayers() - 1 do
        initForPlayer(i)
    end
end

local function onPreUIDraw()
    if isIngameState and not isIngameState() then return end
    for _, manager in pairs(State.managers) do
        if manager and manager.active then
            manager:update()
            manager:prerender()
            manager:render()
        end
    end
end

local function onResetLua()
    State.managers = {}
end

Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnGameStart.Add(onGameStart)
if Events and Events.OnPreUIDraw then
    Events.OnPreUIDraw.Add(onPreUIDraw)
end
if Events and Events.OnResetLua then
    Events.OnResetLua.Add(onResetLua)
end
