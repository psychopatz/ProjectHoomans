-- Responsive layout for the Provision Settings window.

require "PsychopatzCore/UI/PsychopatzUI"
local RulePanel = require "PNC/UI/Provision/PNC_ProvisionRulePanel"
local Layout = PsychopatzCore.UI.Layout

function ISPNCProvisionSettingsWindow:layoutRows()
    local scale = self.uiScale or Layout.Scale()
    local y = Layout.Pixels(8, scale)
    local categoryIndex = 1
    local currentCategory
    local width = math.max(Layout.Pixels(260, scale),
        self.scroll:getWidth() - Layout.Pixels(18, scale))
    for _, row in ipairs(self.ruleRows or {}) do
        if row.definition.category ~= currentCategory then
            local category = self.categoryLabels[categoryIndex]
            Layout.SetBounds(category.widget, Layout.Pixels(8, scale), y,
                math.max(1, width - Layout.Pixels(16, scale)),
                Layout.Pixels(24, scale))
            y = y + Layout.Pixels(31, scale)
            categoryIndex = categoryIndex + 1
            currentCategory = row.definition.category
        end
        y = RulePanel.Layout(row, width, y, scale)
        y = y + Layout.Pixels(8, scale)
    end
    self.scroll.contentHeight = y + Layout.Pixels(8, scale)
    self.scroll:setScrollHeight(self.scroll.contentHeight)
end

function ISPNCProvisionSettingsWindow:onResponsiveLayout()
    local scale = self.uiScale or Layout.Scale()
    local rect = self:getContentRect({ top = 30, bottom = 12 })
    local labelWidth = Layout.Pixels(68, scale)
    local comboOffset = Layout.Pixels(72, scale)
    local footerHeight = Layout.Pixels(66, scale)
    local contentOffset = Layout.Pixels(36, scale)
    local resetWidth = Layout.Pixels(140, scale)
    local cancelWidth = Layout.Pixels(88, scale)
    local applyWidth = Layout.Pixels(94, scale)
    local rightButtons = cancelWidth + Layout.Pixels(8, scale) + applyWidth
    Layout.SetBounds(self.policyLabel, rect.x,
        rect.y + Layout.Pixels(5, scale), labelWidth,
        Layout.Pixels(24, scale))
    Layout.SetBounds(self.policyCombo, rect.x + comboOffset, rect.y,
        math.min(Layout.Pixels(260, scale),
            math.max(1, rect.width - comboOffset)),
        Layout.Pixels(26, scale))
    Layout.SetBounds(self.scroll, rect.x, rect.y + contentOffset, rect.width,
        math.max(1, rect.height - footerHeight - contentOffset))
    local statusY = rect.y + rect.height - footerHeight
        + Layout.Pixels(5, scale)
    local buttonY = rect.y + rect.height - Layout.Pixels(30, scale)
    Layout.SetBounds(self.resetButton, rect.x, buttonY,
        resetWidth, Layout.Pixels(28, scale))
    Layout.SetBounds(self.cancelButton,
        rect.x + rect.width - rightButtons, buttonY,
        cancelWidth, Layout.Pixels(28, scale))
    Layout.SetBounds(self.applyButton,
        rect.x + rect.width - applyWidth, buttonY,
        applyWidth, Layout.Pixels(28, scale))
    Layout.SetBounds(self.statusLabel, rect.x, statusY, rect.width,
        Layout.Pixels(20, scale))
    self:layoutRows()
end

return ISPNCProvisionSettingsWindow
