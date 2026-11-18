local Window = ISPNCUniqueNPCAppearanceWindow
local Internal = Window.Internal or {}
local Layout = Internal.Layout
local tr = Internal.tr

function ISPNCUniqueNPCAppearanceWindow:syncAdvancedVisibility()
    local companion = self.parentEditor
        and self.parentEditor.presentationMode == "companion"
    local visible = not companion or self.advancedVisible == true
    local showIdentityAppearance = companion == true or self.integrated == true
    if self.hairLabel then self.hairLabel:setVisible(showIdentityAppearance) end
    if self.hairCombo then self.hairCombo:setVisible(showIdentityAppearance) end
    if self.beardLabel then self.beardLabel:setVisible(showIdentityAppearance) end
    if self.beardCombo then self.beardCombo:setVisible(showIdentityAppearance) end
    if self.advancedLabel and self.advancedLabel.setVisible then
        self.advancedLabel:setVisible(visible and companion)
    end
    for _, row in ipairs(self.rows or {}) do
        if row.labelControl then row.labelControl:setVisible(visible) end
        if row.policy then row.policy:setVisible(visible) end
        if row.item then row.item:setVisible(visible) end
    end
    if self.advancedClothingButton and self.advancedClothingButton.setTitle then
        self.advancedClothingButton:setTitle(visible
            and tr("UI_PNC_NPCAuthoring_HideAdvancedClothing",
                "HIDE ADVANCED CLOTHING")
            or tr("UI_PNC_NPCAuthoring_AdvancedClothing",
                "ADVANCED CLOTHING OVERRIDES"))
    end
end

function Window:onResponsiveLayout()
    if self.integrated then return self:layoutIntegratedAppearance() end
    local scale = self.uiScale or 1
    local margin = Layout.Pixels(8, scale)
    local rect = {
        x = margin, y = margin,
        width = math.max(1, self.width - margin * 2),
        height = math.max(1, self.height - margin * 2),
    }
    local top = Layout.Flow(self.topControls, {
        x = rect.x, y = rect.y, width = rect.width,
    }, { scale = scale, minWidth = 90, gap = 6 })
    local contentY = top.bottom + Layout.Pixels(8, scale)
    local contentHeight = math.max(120,
        rect.y + rect.height - contentY)
    Layout.SetBounds(self.content, rect.x, contentY,
        rect.width, contentHeight)
    local rowHeight = Layout.Pixels(29, scale)
    local labelWidth = Layout.Pixels(150, scale)
    local gap = Layout.Pixels(6, scale)
    local policyWidth = Layout.Pixels(150, scale)
    local scrollWidth = self.content.vscroll and
        (self.content.vscroll.getWidth and self.content.vscroll:getWidth()
            or self.content.vscroll.width) or Layout.Pixels(18, scale)
    local innerWidth = math.max(Layout.Pixels(360, scale),
        rect.width - scrollWidth - gap)
    local itemX = labelWidth + policyWidth + gap * 2
    local itemWidth = math.max(Layout.Pixels(120, scale),
        innerWidth - labelWidth - policyWidth - gap * 2)
    local y = 8
    Layout.SetBounds(self.outfitLabel, 0, y, labelWidth, rowHeight)
    Layout.SetBounds(self.outfitCombo, labelWidth + gap, y,
        innerWidth - labelWidth - gap, rowHeight)
    y = y + rowHeight + gap
    Layout.SetBounds(self.voiceLabel, 0, y, labelWidth, rowHeight)
    Layout.SetBounds(self.voiceCombo, labelWidth + gap, y,
        innerWidth - labelWidth - gap, rowHeight)
    y = y + rowHeight + gap
    Layout.SetBounds(self.voiceSampleLabel, 0, y, labelWidth, rowHeight)
    Layout.SetBounds(self.voiceSampleCombo, labelWidth + gap, y,
        innerWidth - labelWidth - gap, rowHeight)
    y = y + rowHeight + gap
    Layout.SetBounds(self.voicePitchLabel, 0, y, labelWidth, rowHeight)
    Layout.SetBounds(self.voicePitch, labelWidth + gap, y,
        math.max(Layout.Pixels(100, scale),
            innerWidth - labelWidth - gap - Layout.Pixels(46, scale)), rowHeight)
    Layout.SetBounds(self.voicePitchValue, innerWidth - Layout.Pixels(40, scale),
        y, Layout.Pixels(36, scale), rowHeight)
    y = y + rowHeight + gap
    Layout.SetBounds(self.skinLabel, 0, y, labelWidth, rowHeight)
    Layout.SetBounds(self.skinModeCombo, labelWidth + gap, y,
        Layout.Pixels(180, scale), rowHeight)
    Layout.SetBounds(self.skinSwatch,
        labelWidth + gap + Layout.Pixels(192, scale), y,
        Layout.Pixels(29, scale), rowHeight)
    Layout.SetBounds(self.skinValue,
        labelWidth + gap + Layout.Pixels(230, scale), y,
        math.max(Layout.Pixels(120, scale),
            innerWidth - labelWidth - Layout.Pixels(230, scale)),
        rowHeight)
    y = y + rowHeight + gap
    local showIdentityAppearance = self.parentEditor
        and self.parentEditor.presentationMode == "companion"
    if showIdentityAppearance and self.hairLabel and self.hairCombo then
        Layout.SetBounds(self.hairLabel, 0, y, labelWidth, rowHeight)
        Layout.SetBounds(self.hairCombo, labelWidth + gap, y,
            innerWidth - labelWidth - gap, rowHeight)
        y = y + rowHeight + gap
    end
    if showIdentityAppearance and self.beardLabel and self.beardCombo then
        Layout.SetBounds(self.beardLabel, 0, y, labelWidth, rowHeight)
        Layout.SetBounds(self.beardCombo, labelWidth + gap, y,
            innerWidth - labelWidth - gap, rowHeight)
        y = y + rowHeight + gap
    end
    if not showIdentityAppearance then
        if self.hairLabel then Layout.SetBounds(self.hairLabel, 0, 0, 0, 0) end
        if self.hairCombo then Layout.SetBounds(self.hairCombo, 0, 0, 0, 0) end
        if self.beardLabel then Layout.SetBounds(self.beardLabel, 0, 0, 0, 0) end
        if self.beardCombo then Layout.SetBounds(self.beardCombo, 0, 0, 0, 0) end
    end
    local advancedStart = y
    if self.advancedLabel then
        Layout.SetBounds(self.advancedLabel, 0, y, innerWidth, rowHeight)
        y = y + rowHeight + gap
    end
    local advancedVisible = not (self.parentEditor
        and self.parentEditor.presentationMode == "companion")
        or self.advancedVisible == true
    for _, row in ipairs(self.rows) do
        Layout.SetBounds(row.labelControl, 0, y, labelWidth, rowHeight)
        Layout.SetBounds(row.policy, labelWidth + gap, y, policyWidth, rowHeight)
        Layout.SetBounds(row.item, itemX, y, itemWidth, rowHeight)
        if not advancedVisible then
            Layout.SetBounds(row.labelControl, 0, 0, 0, 0)
            Layout.SetBounds(row.policy, 0, 0, 0, 0)
            Layout.SetBounds(row.item, 0, 0, 0, 0)
        else
            y = y + rowHeight
        end
    end
    self.content.contentHeight = math.max(contentHeight, y + rowHeight + gap)
    self.content:setScrollHeight(self.content.contentHeight)
    self.content.maxScroll = math.max(0,
        self.content.contentHeight - self.content.height)
    if self.content.vscroll then
        local barWidth = self.content.vscroll.getWidth
            and self.content.vscroll:getWidth() or self.content.vscroll.width or 16
        self.content.vscroll:setX(self.content.width - barWidth)
        self.content.vscroll:setHeight(self.content.height)
    end
    if self.content.onResize then self.content:onResize() end
    self:syncAdvancedVisibility()
    PNC.NPCAuthoringFields.NativeMetrics(self)
    self.layout = {
        x = rect.x, y = rect.y, width = rect.width, height = rect.height,
        contentHeight = self.content.contentHeight,
        normalBottom = advancedStart,
        advancedStart = advancedStart,
        advancedEnd = y,
        advancedVisible = advancedVisible,
        scrollBounded = self.content.contentHeight >= self.content.height,
    }
end


-- Labels stack above fields so inherited-value explanations and large fonts
-- never compete for a fixed horizontal label width.
function Window:layoutIntegratedAppearance()
    local gap = Layout.Pixels(10, self.uiScale)
    local h = math.max(Layout.Pixels(28, self.uiScale),
        (getTextManager and getTextManager():getFontHeight(UIFont.Small) or 16) + 10)
    local top = Layout.Flow(self.topControls, { x = gap, y = gap,
        width = math.max(1, self.width - gap * 2) },
        { scale = self.uiScale, minWidth = 80, gap = 6 })
    Layout.SetBounds(self.content, gap, top.bottom + gap,
        math.max(1, self.width - gap * 2), math.max(1, self.height - top.bottom - gap * 2))
    local available = math.max(1, self.content.width - 20)
    local columns = available >= Layout.Pixels(580, self.uiScale) and 2 or 1
    local width = math.min(Layout.Pixels(340, self.uiScale), (available - gap) / columns)
    local fields = {
        { self.skinLabel, self.skinModeCombo }, { self.hairLabel, self.hairCombo },
        { self.beardLabel, self.beardCombo }, { self.hairColorLabel, self.hairColorCombo },
        { self.voiceLabel, self.voiceCombo }, { self.voiceSampleLabel, self.voiceSampleCombo },
        { self.voicePitchLabel, self.voicePitch },
    }
    for index, field in ipairs(fields) do
        local label, control = field[1], field[2]
        if label and control then
            local x = (index - 1) % columns * (width + gap)
            local y = math.floor((index - 1) / columns) * (h * 2 + gap * 2)
            label:setVisible(true)
            Layout.SetBounds(label, x, y, width, h)
            PNC.NPCAuthoringFields.Bounds(control, x, y + h, width, h)
        end
    end
    Layout.SetBounds(self.skinSwatch, math.max(0, width - h), 0, h, h)
    self.skinValue:setVisible(false)
    self.voicePitchValue:setVisible(false)
    self.advancedLabel:setVisible(false)
    local height = math.ceil(#fields / columns) * (h * 2 + gap * 2)
    self.content.contentHeight = height
    self.content.maxScroll = math.max(0, height - self.content.height)
    self.content:setScrollHeight(height)
    self.content:setYScroll(math.max(-self.content.maxScroll, math.min(0, self.content:getYScroll())))
    self.content:onResize()
    PNC.NPCAuthoringFields.NativeMetrics(self)
    self.layout = { contentHeight = height, scrollBounded = true, advancedVisible = false }
end
