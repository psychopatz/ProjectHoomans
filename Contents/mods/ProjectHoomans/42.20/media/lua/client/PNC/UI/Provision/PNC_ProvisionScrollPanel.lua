require "ISUI/ISPanel"

ISPNCProvisionScrollPanel = ISPanel:derive("ISPNCProvisionScrollPanel")

function ISPNCProvisionScrollPanel:initialise()
    ISPanel.initialise(self)
    self:noBackground()
end

function ISPNCProvisionScrollPanel:createChildren()
    ISPanel.createChildren(self)
    self:setScrollChildren(true)
    self:addScrollBars()
end

function ISPNCProvisionScrollPanel:onMouseWheel(delta)
    local current = tonumber(self:getYScroll()) or 0
    local maximum = math.max(0, (self.contentHeight or 0) - self.height)
    self:setYScroll(math.max(-maximum, math.min(0,
        current + delta * 32)))
    return true
end

function ISPNCProvisionScrollPanel:prerender()
    ISPanel.prerender(self)
    self:setStencilRect(0, 0, self.width, self.height)
end

function ISPNCProvisionScrollPanel:render()
    ISPanel.render(self)
    self:clearStencilRect()
end

function ISPNCProvisionScrollPanel:new(x, y, width, height)
    local object = ISPanel:new(x, y, width, height)
    setmetatable(object, self)
    self.__index = self
    return object
end

return ISPNCProvisionScrollPanel
