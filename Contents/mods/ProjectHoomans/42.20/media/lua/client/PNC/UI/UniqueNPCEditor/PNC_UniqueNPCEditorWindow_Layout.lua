local Window = ISPNCNPCAuthoringEditor
local I = Window.Internal
local Layout = I.Layout

local function bounds(control, x, y, w, h)
    if control then Layout.SetBounds(control, x, y, math.max(1, w), math.max(1, h)) end
end

local function scroll(page, height)
    page.contentHeight = math.max(page.height, height)
    page.maxScroll = math.max(0, page.contentHeight - page.height)
    page:setScrollHeight(page.contentHeight)
    if page.getYScroll then
        page:setYScroll(math.max(-page.maxScroll, math.min(0, page:getYScroll())))
    end
    if page.onResize then page:onResize() end
end

function Window:layoutBio(width, rowHeight, gap)
    local y = gap
    local available = math.max(1, width - gap * 2 - 16)
    local columns = available >= Layout.Pixels(580, self.uiScale) and 2 or 1
    local inputWidth = math.min(Layout.Pixels(340, self.uiScale), (available - gap * (columns - 1)) / columns)
    local index = 0
    self.fileLabel:setVisible(false)
    self.fileCombo:setVisible(false)
    for _, label in pairs(self.sectionLabels) do label:setVisible(false) end
    for _, row in ipairs(self.coreRows) do
        local capability = self:fieldCapability(row.fieldID)
        local visible = capability.visible ~= false and row.id ~= "hair"
            and row.id ~= "beard" and row.id ~= "equipmentMode"
        row.labelControl:setVisible(visible)
        row.entry:setVisible(visible)
        if visible then
            local x = gap + (index % columns) * (inputWidth + gap)
            local top = y + math.floor(index / columns) * (rowHeight * 2 + gap * 2)
            bounds(row.labelControl, x, top, inputWidth, rowHeight)
            PNC.NPCAuthoringFields.Lock(self, row.entry, row.fieldID, self.formView)
            PNC.NPCAuthoringFields.Bounds(row.entry, x, top + rowHeight, inputWidth, rowHeight)
            if row.entry.onResize then row.entry:onResize() end
            index = index + 1
        elseif row.entry.pncLock then row.entry.pncLock:setVisible(false) end
    end
    scroll(self.formView, y + math.ceil(index / columns) * (rowHeight * 2 + gap * 2))
end

function Window:layoutAttributes(width, rowHeight, gap)
    local page = self.pages.attributes
    local w = math.max(1, width - gap * 2 - 16)
    local y = gap
    for _, row in ipairs(self.addRows) do
        local capability = self:fieldCapability(row.fieldID)
        local visible = capability.visible ~= false
        row.labelControl:setVisible(visible)
        row.button:setVisible(visible)
        for _, entry in ipairs(row.entries) do entry:setVisible(visible) end
        if visible then
            bounds(row.labelControl, gap, y, w, rowHeight)
            y = y + rowHeight
            local buttonWidth = math.min(w * 0.25, Layout.Pixels(64, self.uiScale))
            local inputs = math.max(1, w - buttonWidth - gap)
            local each = math.max(1, (inputs - gap * (#row.entries - 1)) / #row.entries)
            for index, entry in ipairs(row.entries) do
                bounds(entry, gap + (index - 1) * (each + gap), y, each, rowHeight)
            end
            bounds(row.button, gap + inputs + gap, y, buttonWidth, rowHeight)
            y = y + rowHeight + gap
        end
    end
    local listHeight = math.max(rowHeight * 4, page.height - y - rowHeight - gap * 3)
    bounds(self.configuredDetails, gap, y, w, listHeight)
    y = y + listHeight + gap
    bounds(self.removeConfiguredButton, gap, y, w, rowHeight)
    scroll(page, y + rowHeight + gap)
end

function Window:onResponsiveLayout()
    if not self.pages then return end
    local rect = self:getContentRect()
    local scale = self.uiScale
    local gap = Layout.Pixels(8, scale)
    local fontHeight = getTextManager and getTextManager():getFontHeight(UIFont.Small) or 16
    local rowHeight = math.max(Layout.Pixels(26, scale), fontHeight + 10)
    local toolbar = Layout.Flow(self.toolbar, rect,
        { scale = scale, minWidth = 76, gap = 6 })
    local top = toolbar.bottom + gap
    local height = math.max(1, rect.height - top - rowHeight - gap)
    local rosterWidth = math.min(Layout.Pixels(200, scale), rect.width * 0.23)
    local remaining = math.max(1, rect.width - rosterWidth - gap)
    local compact = remaining < Layout.Pixels(690, scale)
    local portraitWidth = compact and 0 or math.min(Layout.Pixels(260, scale), remaining * 0.32)
    local contentWidth = math.max(1, remaining - (portraitWidth > 0 and portraitWidth + gap or 0))
    local contentX = rosterWidth + gap
    self.roster.itemheight = math.max(Layout.Pixels(52, scale), fontHeight * 2 + 14)
    bounds(self.rosterLabel, 0, top, rosterWidth, rowHeight)
    bounds(self.roster, 0, top + rowHeight, rosterWidth, height - rowHeight)
    bounds(self.tabPanel, contentX, top, contentWidth, height)
    local viewHeight = math.max(1, height - self.tabPanel.tabHeight)
    for _, page in pairs(self.pages) do
        bounds(page, 0, self.tabPanel.tabHeight, contentWidth, viewHeight)
        page.uiScale = scale
    end
    self:layoutBio(contentWidth, rowHeight, gap)
    self:layoutAttributes(contentWidth, rowHeight, gap)
    self.appearanceTab:onResponsiveLayout()
    self:layoutLoadoutPage(contentWidth, viewHeight, rowHeight, gap)
    bounds(self.relationshipDetails, gap, gap, contentWidth - gap * 2, viewHeight - rowHeight - gap * 3)
    bounds(self.inspectorButton, gap, viewHeight - rowHeight - gap, contentWidth - gap * 2, rowHeight)
    bounds(self.details, gap, gap, contentWidth - gap * 2, viewHeight - rowHeight * 2 - gap * 3)
    bounds(self.resetDetailsButton, gap, viewHeight - rowHeight * 2 - gap * 2,
        contentWidth - gap * 2, rowHeight)
    bounds(self.removeButton, gap, viewHeight - rowHeight - gap, contentWidth - gap * 2, rowHeight)
    if Layout.Ellipsize and self.statusLabel.setName then
        self.statusLabel.tooltip = self.statusText
        self.statusLabel:setName(Layout.Ellipsize(self.statusText or "", UIFont.Small, remaining))
    end
    bounds(self.statusLabel, contentX, rect.height - rowHeight, remaining, rowHeight)
    local previewOnly = self.previewExpanded == true
    self.tabPanel:setVisible(self.draft ~= nil and not previewOnly)
    local px = contentX + contentWidth + gap
    if compact or previewOnly then px, portraitWidth = contentX, remaining end
    local portraitHeight = math.max(1, height - rowHeight - gap)
    bounds(self.portraitPanel, px, top, portraitWidth, portraitHeight)
    if self.portraitPanel.setPortraitBounds then
        self.portraitPanel:setPortraitBounds(px, top, portraitWidth, portraitHeight)
    end
    local showPortrait = self.draft ~= nil and (not compact or previewOnly)
    self.portraitPanel:setVisible(showPortrait)
    local buttonWidth = math.max(1, (portraitWidth - gap * 3) / 4)
    for index, button in ipairs(self.portraitControls or {}) do
        bounds(button, px + (index - 1) * (buttonWidth + gap), top + portraitHeight + gap,
            buttonWidth, rowHeight)
        button:setVisible(showPortrait)
    end
    local exploring = self.itemExplorer and self.itemExplorer:getIsVisible()
    if exploring then
        self.tabPanel:setVisible(false); self.roster:setVisible(false); self.rosterLabel:setVisible(false)
        self.portraitPanel:setVisible(false)
        for _, button in ipairs(self.portraitControls or {}) do button:setVisible(false) end
    else
        self.roster:setVisible(true); self.rosterLabel:setVisible(true)
    end
    for _, control in ipairs(self.toolbar) do control:setVisible(not exploring) end
    self.layout = { x = rect.x, y = top, leftWidth = contentWidth,
        portraitX = px, portraitY = top, portraitWidth = portraitWidth,
        portraitHeight = portraitHeight, compact = compact, stacked = compact,
        rosterWidth = rosterWidth }
end

return Window
