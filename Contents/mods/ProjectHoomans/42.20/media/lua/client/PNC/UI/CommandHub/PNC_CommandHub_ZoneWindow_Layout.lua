require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.CommandHub = PNC.CommandHub or {}

local Registry = require "PNC/UI/CommandHub/PNC_CommandHub_ZoneRegistry"
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Theme = UI.Theme

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function sectionTitle(section)
    return tr(section.titleKey, section.titleFallback or "ZONE")
end

function ISPNCCommandHubZoneWindow:onResponsiveLayout()
    local scale = self.uiScale or Layout.Scale()
    local px = function(value) return Layout.Pixels(value, scale) end
    local rect = self:getContentRect({ padding = 12 })
    local buttonHeight = px(27)
    local font = Theme.Font(scale)
    local headerHeight = math.max(px(14), Theme.FontHeight(font))
    local summaryHeight = math.max(px(14), Theme.FontHeight(UIFont.Small))
    local sectionY = rect.y + headerHeight + px(8)
    local buttonGap = px(8)
    local summaryGap = px(6)
    local sectionGap = px(12)
    local controls = {}
    local definition = Registry.Get(self.definitionID)
    local cursor = sectionY

    for _, section in ipairs(definition and definition.sections or {}) do
        local value = self.controls[section.id]
        if value then
            local headerY = cursor
            local buttonY = headerY + headerHeight + buttonGap
            local columnGap = px(8)
            local buttons = value.buttons or {}
            local columns = #buttons >= 2 and 2 or 1
            local buttonWidth = columns == 1 and rect.width
                or math.floor((rect.width - columnGap) / columns)
            for index, button in ipairs(buttons) do
                local column = (index - 1) % columns
                local row = math.floor((index - 1) / columns)
                Layout.SetBounds(button,
                    rect.x + column * (buttonWidth + columnGap),
                    buttonY + row * (buttonHeight + buttonGap),
                    buttonWidth, buttonHeight)
            end
            local summaryY = buttonY + buttonHeight + summaryGap
            controls[#controls + 1] = {
                definition = section, x = rect.x, width = rect.width,
                headerY = headerY, buttonY = buttonY, summaryY = summaryY,
            }
            local rows = math.ceil(#buttons / columns)
            cursor = buttonY + rows * buttonHeight
                + math.max(0, rows - 1) * buttonGap
                + summaryGap + summaryHeight + sectionGap
        end
    end
    local statusHeight = math.max(px(14), Theme.FontHeight(UIFont.Small))
    local contentBottom = cursor - sectionGap
    local requiredHeight = contentBottom + statusHeight + px(8)
        + self:footerHeight()
    if self:getHeight() < requiredHeight then
        local maximum = self.maximumHeight or requiredHeight
        self:setHeight(math.min(maximum, requiredHeight))
        rect = self:getContentRect({ padding = 12 })
    end
    self.layout = {
        rect = rect,
        sectionY = sectionY,
        sections = controls,
        helpY = rect.y,
        statusY = math.max(rect.y + rect.height - statusHeight,
            contentBottom),
    }
    self:syncResizeWidgets()
end

function ISPNCCommandHubZoneWindow:render()
    PsychopatzAttachedWindow.render(self)
    local layout = self.layout
    local definition = Registry.Get(self.definitionID)
    if not layout or not definition then return end
    local muted = Theme.colors.textMuted
    local text = Theme.colors.text
    local accent = Theme.colors.accent
    self:drawText(tr(definition.helpKey, definition.helpFallback or ""),
        layout.rect.x, layout.helpY, muted.r, muted.g, muted.b, muted.a,
        UIFont.Small)
    for _, value in ipairs(layout.sections) do
        local section = value.definition
        UI.DrawSectionTitle(self, sectionTitle(section), value.x,
            value.headerY,
            value.width)
        local zone = self:getZoneState()
        local summary = section.summary and section.summary(zone)
            or (zone and tr("UI_PNC_CommandHub_Zone_Configured", "CONFIGURED")
                or tr("UI_PNC_CommandHub_Zone_NotConfigured", "NOT CONFIGURED"))
        local color = self:isConfigured(section) and accent or muted
        self:drawText(summary, value.x + Layout.Pixels(8, self.uiScale),
            value.summaryY, color.r, color.g,
            color.b, color.a, UIFont.Small)
    end
    if self.statusText and self.statusText ~= "" then
        self:drawText(self.statusText, layout.rect.x, layout.statusY,
            text.r, text.g, text.b, text.a, UIFont.Small)
    end
end

return true
