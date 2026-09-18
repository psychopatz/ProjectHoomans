-- Responsive geometry for the Puppet Opera beat tab.

PNC = PNC or {}

local Internal = PNC.PuppetOperaBeatsTabInternal
local Layout = Internal.Layout
local Class = ISPNCPuppetOperaBeatsTab

function Class:onResponsiveLayout()
    if not Layout or type(Layout.SetBounds) ~= "function" then return end
    local scale = self.ownerWindow and self.ownerWindow.uiScale
    local pad = Layout.Pixels(8, scale)
    local top = Layout.Pixels(4, scale)
    local leftWidth = math.max(Layout.Pixels(200, scale),
        math.floor(self:getWidth() * 0.36))
    leftWidth = math.min(leftWidth,
        math.max(Layout.Pixels(1, scale), self:getWidth() - pad * 3
            - Layout.Pixels(190, scale)))
    local bottom = Layout.Pixels(132, scale)
    Layout.SetBounds(self.beatList, pad, top, leftWidth,
        self:getHeight() - top - Layout.Pixels(44, scale))
    Layout.SetBounds(self.durationEntry, pad,
        self:getHeight() - Layout.Pixels(34, scale),
        Layout.Pixels(120, scale), Layout.Pixels(26, scale))
    Layout.SetBounds(self.applyDurationButton,
        pad + Layout.Pixels(128, scale),
        self:getHeight() - Layout.Pixels(34, scale),
        Layout.Pixels(140, scale), Layout.Pixels(26, scale))
    local rightX = leftWidth + pad * 2
    Layout.SetBounds(self.details, rightX, top,
        math.max(1, self:getWidth() - rightX - pad),
        math.max(1, self:getHeight() - top - bottom))
    local buttonAreaWidth = math.max(1, self:getWidth() - rightX - pad)
    local columns = buttonAreaWidth >= Layout.Pixels(500, scale) and 5 or 3
    local buttonWidth = math.max(Layout.Pixels(64, scale),
        math.floor((buttonAreaWidth - pad * (columns - 1)) / columns))
    local buttonTop = self:getHeight() - Layout.Pixels(98, scale)
    for index, button in ipairs(self.buttons or {}) do
        local row = math.floor((index - 1) / columns)
        local column = (index - 1) % columns
        Layout.SetBounds(button,
            rightX + column * (buttonWidth + pad),
            buttonTop + row * Layout.Pixels(31, scale),
            buttonWidth, Layout.Pixels(26, scale))
    end
end

return Class
