-- Responsive geometry for the Puppet Opera window.

PNC = PNC or {}

local Internal = PNC.PuppetOperaDebugWindow.Internal
local Layout = Internal.Layout
local Class = ISPNCPuppetOperaDebugWindow

function Class:onResponsiveLayout()
    local scale = self.uiScale
    local width = self:getWidth()
    local height = self:getHeight()
    local compact = height < Layout.Pixels(430, scale)
    local pad = Layout.Pixels(compact and 6 or 10, scale)
    local gap = Layout.Pixels(compact and 5 or 8, scale)
    local toolbarHeight = Layout.Pixels(compact and 26 or 30, scale)
    local hideSecondaryToolbar = compact
    -- Keep editor controls below the native collapsable-window title bar.
    -- Placing the combos at y=6 made them overlap the close/pin controls on
    -- narrow windows, which looked like a clipped toolbar rather than a
    -- resizable scene builder.
    local rowY = self:titleBarHeight() + Layout.Pixels(6, scale)
    local innerWidth = math.max(1, width - pad * 2)
    local comboWidth = math.max(1, math.floor((innerWidth - gap) / 2))
    Layout.SetBounds(self.blueprintCombo, pad, rowY,
        comboWidth, toolbarHeight)
    Layout.SetBounds(self.actorCombo, pad + comboWidth + gap, rowY,
        math.max(1, innerWidth - comboWidth - gap), toolbarHeight)

    local topRowY = rowY + toolbarHeight + gap
    local topButtonCount = math.max(1, #self.topButtons)
    local topButtonWidth = math.max(1,
        math.floor((innerWidth - gap * (topButtonCount - 1))
            / topButtonCount))
    for index, button in ipairs(self.topButtons) do
        button:setVisible(not hideSecondaryToolbar)
        Layout.SetBounds(button,
            pad + (index - 1) * (topButtonWidth + gap),
            topRowY,
            topButtonWidth,
            toolbarHeight)
    end

    local descriptionY = hideSecondaryToolbar
        and (rowY + toolbarHeight + gap)
        or (topRowY + toolbarHeight + Layout.Pixels(4, scale))
    local bottomColumns = width >= Layout.Pixels(900, scale) and 6 or 3
    local bottomRows = math.ceil(#self.controls / bottomColumns)
    local bottom = bottomRows * toolbarHeight
        + (bottomRows - 1) * gap + pad
    -- The action bar is the last thing to give up when the window is made
    -- short. The editor body may collapse to a one-pixel viewport, but the
    -- controls remain reachable and never sit below the window edge.
    local actionY = math.max(1, height - bottom)
    self.showDescription = not compact
        and actionY - descriptionY >= Layout.Pixels(20, scale)
    local contentTop = descriptionY
        + (self.showDescription and Layout.Pixels(22, scale) or gap)
    local bodyHeight = actionY - contentTop
    local showEditor = bodyHeight > 0
    local tabTop = math.max(1, contentTop)
    self.actionY = actionY
    if self.tabPanel.setVisible then self.tabPanel:setVisible(showEditor) end
    Layout.SetBounds(self.tabPanel, pad, tabTop,
        innerWidth,
        math.max(1, showEditor and actionY - tabTop or 1))
    local viewHeight = math.max(1,
        self.tabPanel:getHeight() - self.tabPanel.tabHeight)
    for _, view in ipairs({
        self.layoutTab,
        self.playerAnimationTab,
        self.npcAnimationTab,
        self.beatsTab,
        self.traceTab,
    }) do
        Layout.SetBounds(view, 0, self.tabPanel.tabHeight,
            self.tabPanel:getWidth(), viewHeight)
        if view.onResponsiveLayout then view:onResponsiveLayout() end
    end

    local buttonWidth = math.max(1,
        math.floor((innerWidth - gap * (bottomColumns - 1))
            / bottomColumns))
    for index, button in ipairs(self.controls) do
        local row = math.floor((index - 1) / bottomColumns)
        local column = (index - 1) % bottomColumns
        Layout.SetBounds(button,
            pad + column * (buttonWidth + gap),
            actionY + row * (toolbarHeight + gap),
            buttonWidth,
            toolbarHeight)
    end
    self.descriptionY = descriptionY
end

return Class
