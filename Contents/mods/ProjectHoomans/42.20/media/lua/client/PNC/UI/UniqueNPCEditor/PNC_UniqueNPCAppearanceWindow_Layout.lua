local Window = ISPNCUniqueNPCAppearanceWindow
local Internal = Window.Internal or {}
local Layout = Internal.Layout

function Window:onResponsiveLayout()
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
    for _, row in ipairs(self.rows) do
        Layout.SetBounds(row.labelControl, 0, y, labelWidth, rowHeight)
        Layout.SetBounds(row.policy, labelWidth + gap, y, policyWidth, rowHeight)
        Layout.SetBounds(row.item, itemX, y, itemWidth, rowHeight)
        y = y + rowHeight
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
end

