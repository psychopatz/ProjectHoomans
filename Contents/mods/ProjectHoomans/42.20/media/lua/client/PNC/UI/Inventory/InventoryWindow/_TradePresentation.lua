local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Helpers = require "PNC/UI/Inventory/InventoryWindow/_Helpers"
local tr = Helpers.tr

function ISPNCInventoryWindow:prerenderTrade()
    self:applyOpacityStyle()
    self:refreshInventory(false)
    UI.Window.prerender(self)
    local playerX = self.playerPaneX or 8
    local traderX = self.npcPaneX or math.floor(self.width / 2)
    local paneWidth = self.paneWidth or math.floor((self.width - 24) / 2)
    local headingY = self.headingY or self:titleBarHeight() + 8
    local opacity = self.contentSurfaceOpacity or 1
    self:drawRect(playerX, headingY - 3, paneWidth, 21,
        0.55 * opacity, 0.09, 0.12, 0.16)
    self:drawRect(traderX, headingY - 3, paneWidth, 21,
        0.55 * opacity, 0.17, 0.12, 0.08)
    self:drawText(
        tr("UI_PNC_Trading_PlayerHeading", "YOUR OFFER"),
        playerX + 4, headingY, 0.72, 0.86, 1.00, 1, UIFont.Small
    )
    self:drawText(
        Layout.Ellipsize(string.upper(tostring(self.npcDisplayName
            or "CARAVAN TRADER")), UIFont.Small, paneWidth - 8),
        traderX + 4, headingY, 1.00, 0.82, 0.62, 1, UIFont.Small
    )
    local totals = self.tradeTotals or self:getTradeTotals()
    local footerY = self.statusY or (self.height - 44)
    local traderUsed, traderMax = 0, 0
    if self.transferEndpoint and self.transferEndpoint.weight then
        traderUsed, traderMax = self.transferEndpoint:weight()
    end
    self:drawText(
        tr("UI_PNC_Trading_TotalCost", "TOTAL COST") .. ": $"
            .. tostring(totals.buyTotal),
        playerX + 4, footerY, 0.96, 0.96, 0.96, 1, UIFont.Small
    )
    self:drawText(
        tr("UI_PNC_Trading_TotalValue", "TOTAL VALUE") .. ": $"
            .. tostring(totals.sellTotal),
        traderX + 4, footerY, 0.55, 0.94, 0.68, 1, UIFont.Small
    )
    self:drawTextRight(
        tr("UI_PNC_Trading_Net", "NET") .. ": $" .. tostring(totals.netTotal)
            .. "    " .. tr("UI_PNC_Trading_Capacity", "Capacity") .. ": "
            .. string.format("%.1f / %.1f", traderUsed, traderMax),
        traderX + paneWidth - 4, footerY,
        totals.netTotal > 0 and 0.98 or 0.55,
        totals.netTotal > 0 and 0.72 or 0.94,
        totals.netTotal > 0 and 0.32 or 0.68,
        1, UIFont.Small
    )
    if self.statusText and self.statusText ~= "" then
        self:drawText(Layout.Ellipsize(tostring(self.statusText), UIFont.Small,
            self.width - 16), 8, footerY + 20,
            0.92, 0.82, 0.64, 1, UIFont.Small)
    end
end

return ISPNCInventoryWindow
