-- Responsive geometry for the Puppet Opera animation catalog tab.

PNC = PNC or {}

local Internal = PNC.PuppetOperaAnimationTabInternal
local Layout = Internal.Layout
local resizeRows = Internal.resizeRows
local Class = ISPNCPuppetOperaAnimationTab

function Class:onResponsiveLayout()
    local pad = Layout.Pixels(8, self.ownerWindow and self.ownerWindow.uiScale)
    local scale = self.ownerWindow and self.ownerWindow.uiScale
    local controlHeight = Layout.Pixels(26, scale)
    resizeRows(self.list, Layout.Pixels(56, scale))
    resizeRows(self.details, Layout.Pixels(25, scale))
    if self.list then self.list.uiScale = scale end
    if self.details then self.details.uiScale = scale end
    local available = math.max(1, self:getWidth() - pad * 2)
    local filterWidth = math.min(Layout.Pixels(190, scale),
        math.max(Layout.Pixels(96, scale), math.floor(available * 0.36)))
    local searchWidth = math.max(1, available - filterWidth - pad)
    local top = pad + controlHeight + pad
    local split = math.floor(self:getWidth() * 0.50)
    split = math.max(1, math.min(split, self:getWidth() - 1))
    Layout.SetBounds(self.search, pad, pad, searchWidth,
        controlHeight)
    Layout.SetBounds(self.filter, pad + searchWidth + pad, pad,
        math.max(1, math.min(filterWidth,
            self:getWidth() - pad * 2 - searchWidth - pad)), controlHeight)
    local footer = Layout.Pixels(38, scale)
    local contentHeight = math.max(1, self:getHeight() - top - footer)
    local narrow = self:getWidth() < Layout.Pixels(600, scale)
    if narrow then
        local listHeight = math.max(1, math.floor(contentHeight * 0.48))
        Layout.SetBounds(self.list, pad, top,
            available, listHeight)
        Layout.SetBounds(self.details, pad, top + listHeight + pad,
            available, math.max(1, contentHeight - listHeight - pad))
    else
        Layout.SetBounds(self.list, pad, top,
            math.max(1, split - pad * 2), contentHeight)
        Layout.SetBounds(self.details, split + pad, top,
            math.max(1, self:getWidth() - split - pad * 2), contentHeight)
    end
    local buttonGap = pad
    local buttonWidth = math.max(1, math.floor((available - buttonGap * 3) / 4))
    local buttonY = self:getHeight() - Layout.Pixels(34,
        self.ownerWindow and self.ownerWindow.uiScale)
    Layout.SetBounds(self.assignButton, pad, buttonY,
        buttonWidth,
        controlHeight)
    Layout.SetBounds(self.previewButton, pad + buttonWidth + buttonGap,
        buttonY, buttonWidth,
        controlHeight)
    Layout.SetBounds(self.loopPreviewButton,
        pad + (buttonWidth + buttonGap) * 2, buttonY,
        buttonWidth, controlHeight)
    Layout.SetBounds(self.stopPreviewButton,
        pad + (buttonWidth + buttonGap) * 3, buttonY,
        math.max(1, available - (buttonWidth + buttonGap) * 3),
        controlHeight)
end

return Class
