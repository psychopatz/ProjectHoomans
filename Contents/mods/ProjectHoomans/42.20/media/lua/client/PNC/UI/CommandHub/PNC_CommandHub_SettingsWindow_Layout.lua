require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.CommandHub = PNC.CommandHub or {}

local UI = PsychopatzCore.UI
local Layout = UI.Layout

function ISPNCCommandHubSettingsWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 30, bottom = 48 })
    local scale = self.uiScale or Layout.Scale()
    local px = function(value) return Layout.Pixels(value, scale) end
    local rowHeight = px(34)
    local controlHeight = px(26)
    local y = rect.y + px(24)
    Layout.SetBounds(self.helpLabel, rect.x, rect.y, rect.width, px(18))
    local opacity = self.fields.opacity
    opacity.row:place(rect.x, y, rect.width, rowHeight, {
        scale = scale,
        labelWidth = 110,
        valueWidth = 48,
        gap = 8,
        controlHeight = controlHeight,
    })
    y = y + rowHeight + px(8)
    self.fields.surfaceLift.row:place(rect.x, y, rect.width, rowHeight, {
        scale = scale,
        labelWidth = 110,
        valueWidth = 48,
        gap = 8,
        controlHeight = controlHeight,
    })
    y = y + rowHeight + px(8)
    self.fields.detailLift.row:place(rect.x, y, rect.width, rowHeight, {
        scale = scale,
        labelWidth = 110,
        valueWidth = 48,
        gap = 8,
        controlHeight = controlHeight,
    })
    y = y + rowHeight + px(8)
    self.fields.titlebarScale.row:place(rect.x, y, rect.width, rowHeight, {
        scale = scale,
        labelWidth = 110,
        valueWidth = 48,
        gap = 8,
        controlHeight = controlHeight,
    })
    y = y + rowHeight + px(8)
    self.fields.nameplateTextScale.row:place(rect.x, y, rect.width,
        rowHeight, {
            scale = scale,
            labelWidth = 130,
            valueWidth = 48,
            gap = 8,
            controlHeight = controlHeight,
        })
    y = y + rowHeight + px(8)
    self.fields.nameplateBarScale.row:place(rect.x, y, rect.width,
        rowHeight, {
            scale = scale,
            labelWidth = 130,
            valueWidth = 48,
            gap = 8,
            controlHeight = controlHeight,
        })
    y = y + rowHeight + px(8)
    self.fields.relationshipFeedbackScale.row:place(rect.x, y, rect.width,
        rowHeight, {
            scale = scale,
            labelWidth = 145,
            valueWidth = 48,
            gap = 8,
            controlHeight = controlHeight,
        })
    y = y + rowHeight + px(8)
    Layout.SetBounds(self.themeButton, rect.x, y, rect.width, controlHeight)
    y = y + controlHeight + px(8)
    Layout.SetBounds(self.branchButton, rect.x, y,
        math.max(px(140), rect.width), controlHeight)
    local buttonHeight = px(26)
    local buttonY = rect.y + rect.height - buttonHeight
    local statusHeight = px(18)
    Layout.SetBounds(self.statusLabel, rect.x,
        buttonY - statusHeight - px(5), rect.width, statusHeight)
    Layout.SetBounds(self.resetButton, rect.x, buttonY, px(92), buttonHeight)
    Layout.SetBounds(self.closeButton,
        rect.x + rect.width - px(174), buttonY, px(80), buttonHeight)
    Layout.SetBounds(self.applyButton,
        rect.x + rect.width - px(88), buttonY, px(88), buttonHeight)
end

return PNC.CommandHub.SettingsUI
