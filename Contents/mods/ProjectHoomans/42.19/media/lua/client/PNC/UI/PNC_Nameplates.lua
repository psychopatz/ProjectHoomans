require "ISUI/ISUIElement"

PNC = PNC or {}
PNC.Nameplates = PNC.Nameplates or {}

local Nameplates = PNC.Nameplates

Nameplates.Settings = Nameplates.Settings or {
    enabled = true,
    showAIDebug = false,
}
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
    PNC.Runtime = PNC.Runtime or {}
    PNC.Runtime.debugEnabled = Settings.showAIDebug == true
    if player and HaloTextHelper and HaloTextHelper.addText then
        local messageKey = Settings.showAIDebug and "UI_PNC_AIOverlayEnabled" or "UI_PNC_AIOverlayDisabled"
        HaloTextHelper.addText(player, getText(messageKey))
    end
    return Settings.showAIDebug
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
