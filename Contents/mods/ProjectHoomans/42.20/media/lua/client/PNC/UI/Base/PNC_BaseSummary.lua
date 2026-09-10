require "ISUI/ISPanel"
require "PsychopatzCore/UI/PsychopatzUI"

local FacilityState = require "PNC/Core/Settlement/PNC_FacilityState"
local SummaryPanel = ISPanel:derive("PNCBaseSummaryPanel")
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    if not value or value == key then return fallback end
    return value
end

function SummaryPanel:render()
    ISPanel.render(self)
    local snapshot = self.owner and self.owner.snapshot or {}
    local settlement = snapshot.settlement
    if not settlement then
        self:drawText(tr("UI_PNC_Base_NoSettlement", "NO COLONY BASE CLAIMED"),
            12, 13, Theme.colors.warning.r, Theme.colors.warning.g,
            Theme.colors.warning.b, Theme.colors.warning.a, UIFont.Small)
        self:drawText(tr("UI_PNC_Base_NoSettlementHelp",
            "Claim territory before placing colony buildings."),
            12, 32, Theme.colors.textMuted.r, Theme.colors.textMuted.g,
            Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
        local status = self.owner and self.owner.baseTerritoryStatus
        if status and status ~= "" then
            self:drawText(Layout.Ellipsize(status, UIFont.Small,
                self.width - 24), 12, 47, Theme.colors.accent.r,
                Theme.colors.accent.g, Theme.colors.accent.b,
                Theme.colors.accent.a, UIFont.Small)
        end
        return
    end
    local facilities = settlement.facilities or {}
    local active, stockpile = 0, false
    for _, facility in ipairs(facilities) do
        if facility.activeTask then active = active + 1 end
        if tostring(facility.definitionId or "") == "stockpile"
            and FacilityState.IsBuilt(facility)
        then
            stockpile = true
        end
    end
    local values = {
        { tr("UI_PNC_Base_SummaryHQ", "HQ"),
            tr("UI_PNC_Base_SummaryLevel", "LEVEL") .. " "
                .. tostring(settlement.hqLevel or 1) },
        { tr("UI_PNC_Base_Buildings", "BUILDINGS"), tostring(#facilities) },
        { tr("UI_PNC_Base_Stockpile", "STOCKPILE"), stockpile
            and tr("UI_PNC_Base_Ready", "READY")
            or tr("UI_PNC_Base_Missing", "MISSING") },
        { tr("UI_PNC_Base_Projects", "PROJECTS"), tostring(active) },
    }
    local cellWidth = math.max(110, math.floor(self.width / #values))
    for index, value in ipairs(values) do
        local x = (index - 1) * cellWidth + 12
        local color = value[1] == "STOCKPILE" and not stockpile
            and Theme.colors.warning or Theme.colors.accent
        self:drawText(value[1], x, 7, Theme.colors.textMuted.r,
            Theme.colors.textMuted.g, Theme.colors.textMuted.b,
            Theme.colors.textMuted.a, UIFont.Small)
        self:drawText(Layout.Ellipsize(value[2], UIFont.Medium,
            cellWidth - 20), x, 25, color.r, color.g, color.b,
            color.a or 1, UIFont.Medium)
    end
    local status = self.owner and self.owner.baseTerritoryStatus
    if status and status ~= "" then
        self:drawText(Layout.Ellipsize(status, UIFont.Small,
            self.width - 24), 12, 47, Theme.colors.accent.r,
            Theme.colors.accent.g, Theme.colors.accent.b,
            Theme.colors.accent.a, UIFont.Small)
    end
end

return SummaryPanel
