local Nameplates = PNC.Nameplates
local Settings = Nameplates.Settings
local State = Nameplates.State
local Entries = PNC.NameplateEntries
local Renderer = PNC.NameplateRenderer
local StealthIndicator = PNC.NameplateStealthIndicator

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
    if StealthIndicator and StealthIndicator.Render then
        StealthIndicator.Render(self, Settings)
    end
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
