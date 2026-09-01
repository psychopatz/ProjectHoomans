PNC = PNC or {}
PNC.CommandHub = PNC.CommandHub or {}

local Presentation = require "PNC/UI/CommandHub/PNC_CommandHub_WorkWindow_Presentation"
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Theme = UI.Theme

function ISPNCCommandHubWorkWindow:onResponsiveLayout()
    -- Keep the section headers below the native title bar and its accent
    -- rule.  This is intentionally part of the responsive content rect so
    -- scaling and resizing preserve the same safe inset.
    local rect = self:getContentRect({ top = 30, bottom = 12 })
    local scale = self.uiScale or Layout.Scale()
    local px = function(value) return Layout.Pixels(value, scale) end
    local gap = px(10)
    local header = px(38)
    local peopleWidth = math.min(px(285), math.max(px(220),
        math.floor(rect.width * 0.38)))
    local jobsX = rect.x + peopleWidth + gap
    local jobsWidth = math.max(px(180), rect.width - peopleWidth - gap)
    local bodyY = rect.y + header
    local bodyHeight = math.max(px(160), rect.height - header)
    Layout.SetBounds(self.peoplePanel, rect.x, bodyY,
        peopleWidth, bodyHeight)
    Layout.SetBounds(self.authorizationPanel, jobsX, bodyY,
        jobsWidth, bodyHeight)
    Layout.SetBounds(self.peopleList, rect.x, bodyY,
        peopleWidth, bodyHeight)
    local rowHeight = px(30)
    local y = bodyY + px(42)
    for _, definition in ipairs(self.workRegistry.All()) do
        local checkbox = self.jobCheckboxes[definition.id]
        if checkbox then
            Layout.SetBounds(checkbox, jobsX + px(10), y,
                math.max(px(140), jobsWidth - px(20)), rowHeight)
            y = y + rowHeight + px(4)
        end
    end
    self.layout = {
        rect = rect, jobsX = jobsX, jobsWidth = jobsWidth,
        bodyY = bodyY, bodyHeight = bodyHeight,
    }
end

function ISPNCCommandHubWorkWindow:render()
    PsychopatzWindow.render(self)
    if not self.layout then return end
    local rect = self.layout.rect
    local jobsX, jobsWidth = self.layout.jobsX, self.layout.jobsWidth
    local bodyY = self.layout.bodyY
    UI.DrawSectionTitle(self,
        Presentation.Translate("UI_PNC_Work_Colonists", "COLONISTS"),
        rect.x, rect.y, self.peopleList:getWidth())
    UI.DrawSectionTitle(self,
        Presentation.Translate("UI_PNC_Work_Authorized", "AUTHORIZED WORK"),
        jobsX, rect.y, jobsWidth)
    local person = self:selectedPerson()
    if person then
        self:drawText(Presentation.PersonName(person), jobsX + 10, bodyY + 8,
            Theme.colors.text.r, Theme.colors.text.g,
            Theme.colors.text.b, Theme.colors.text.a, UIFont.Small)
    else
        self:drawText(Presentation.Translate("UI_PNC_Work_SelectColonist",
            "SELECT A COLONIST"), jobsX + 10, bodyY + 8,
            Theme.colors.textMuted.r, Theme.colors.textMuted.g,
            Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
    end
    if #self.people <= 0 then
        self:drawText(Presentation.Translate("UI_PNC_Work_NoColonists",
            "NO COLONISTS AVAILABLE"), rect.x + 12, bodyY + 12,
            Theme.colors.textMuted.r, Theme.colors.textMuted.g,
            Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
    end
end

return true
