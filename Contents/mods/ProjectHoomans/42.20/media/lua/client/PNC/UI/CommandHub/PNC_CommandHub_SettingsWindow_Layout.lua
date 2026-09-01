require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.CommandHub = PNC.CommandHub or {}

local UI = PsychopatzCore.UI
local Layout = UI.Layout

function ISPNCCommandHubSettingsWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 30, bottom = 50 })
    local scale = self.uiScale or Layout.Scale()
    local px = function(value) return Layout.Pixels(value, scale) end
    local labelWidth = math.min(px(170), math.floor(rect.width * 0.5))
    local rowHeight = px(29)
    local controlHeight = px(26)
    local valueWidth = px(48)
    local gap = px(8)
    local y = rect.y + px(24)
    self.helpLabel:setX(rect.x)
    self.helpLabel:setY(rect.y)
    self.helpLabel:setWidth(rect.width)
    self.helpLabel:setHeight(px(18))
    for index, id in ipairs({ "x", "y", "width", "height", "opacity" }) do
        local field = self.fields[id]
        local rowY = y + (index - 1) * rowHeight
        field.label:setX(rect.x)
        field.label:setY(rowY + px(5))
        if field.slider then
            field.slider.uiScale = scale
            local sliderWidth = math.max(px(100),
                rect.width - labelWidth - valueWidth - gap)
            Layout.SetBounds(field.slider, rect.x + labelWidth, rowY,
                sliderWidth, controlHeight)
            field.valueLabel:setX(rect.x + labelWidth + sliderWidth + gap)
            field.valueLabel:setY(rowY + px(5))
            field.valueLabel:setWidth(valueWidth)
            field.valueLabel:setHeight(px(18))
        else
            Layout.SetBounds(field.entry, rect.x + labelWidth, rowY,
                math.max(px(80), rect.width - labelWidth), controlHeight)
        end
    end
    local branchY = y + 5 * rowHeight + px(4)
    Layout.SetBounds(self.branchButton, rect.x, branchY,
        math.max(px(140), rect.width), controlHeight)
    local buttonHeight = px(26)
    local buttonY = rect.y + rect.height - buttonHeight
    local statusHeight = px(18)
    self.statusLabel:setX(rect.x)
    self.statusLabel:setY(buttonY - statusHeight - px(5))
    self.statusLabel:setWidth(rect.width)
    self.statusLabel:setHeight(statusHeight)
    Layout.SetBounds(self.resetButton, rect.x, buttonY, px(92), buttonHeight)
    Layout.SetBounds(self.closeButton,
        rect.x + rect.width - px(174), buttonY, px(80), buttonHeight)
    Layout.SetBounds(self.applyButton,
        rect.x + rect.width - px(88), buttonY, px(88), buttonHeight)
end

return PNC.CommandHub.SettingsUI
