require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.CommandHub = PNC.CommandHub or {}

local UI = PsychopatzCore.UI
local Layout = UI.Layout

function ISPNCCommandHubSettingsWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 30, bottom = 50 })
    local scale = self.uiScale or Layout.Scale()
    local px = function(value) return Layout.Pixels(value, scale) end
    local rowHeight = px(29)
    local controlHeight = px(26)
    local y = rect.y + px(24)
    Layout.SetBounds(self.helpLabel, rect.x, rect.y, rect.width, px(18))
    for index, id in ipairs({ "x", "y", "width", "height", "opacity" }) do
        local field = self.fields[id]
        local rowY = y + (index - 1) * rowHeight
        field.row:place(rect.x, rowY, rect.width, rowHeight, {
            scale = scale,
            labelWidth = 170,
            valueWidth = field.slider and 48 or 0,
            gap = 8,
            controlHeight = 26,
        })
    end
    local branchY = y + 5 * rowHeight + px(4)
    Layout.SetBounds(self.branchButton, rect.x, branchY,
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
