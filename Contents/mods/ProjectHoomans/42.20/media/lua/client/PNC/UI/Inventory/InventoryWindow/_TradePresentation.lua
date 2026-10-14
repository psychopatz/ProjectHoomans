local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Helpers = require "PNC/UI/Inventory/InventoryWindow/_Helpers"
local tr = Helpers.tr

local function integer(value)
    value = tonumber(value)
    return value and math.floor(value) or 0
end

local function money(value)
    return "$" .. tostring(integer(value))
end

local function netLabel(netTotal)
    netTotal = integer(netTotal)
    if netTotal < 0 then
        return tr("UI_PNC_Trading_PlayerReceives", "PLAYER RECEIVES")
            .. ": " .. money(-netTotal), 0.55, 0.94, 0.68
    elseif netTotal > 0 then
        return tr("UI_PNC_Trading_PlayerPays", "PLAYER PAYS")
            .. ": " .. money(netTotal), 0.98, 0.72, 0.32
    end
    return tr("UI_PNC_Trading_Net", "NET") .. ": " .. money(0),
        0.90, 0.90, 0.90
end

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
    local footerY = self.footerY
        or ((self.statusY or (self.height - 44)) - 38)
    local statusY = self.statusY or (footerY + 38)
    local traderUsed, traderMax = 0, 0
    if self.transferEndpoint and self.transferEndpoint.weight then
        traderUsed, traderMax = self.transferEndpoint:weight()
    end
    local snapshot = self.transferEndpoint
        and self.transferEndpoint.snapshot or {}
    local budget = tonumber(snapshot and snapshot.budget)
    local budgetText = budget and money(budget) or "N/A"
    local directionText, directionR, directionG, directionB =
        netLabel(totals.netTotal)
    local capacityText = tr("UI_PNC_Trading_Capacity", "Capacity") .. ": "
        .. string.format("%.1f / %.1f", traderUsed, traderMax)
    local budgetAndCapacity = Layout.Ellipsize(
        tr("UI_PNC_Trading_Budget", "BUDGET") .. ": " .. budgetText
            .. "    " .. capacityText,
        UIFont.Small, paneWidth - 8
    )

    -- Keep the footer distinct from the world scene and the status row.
    self:drawRect(playerX, footerY - 6, paneWidth * 2 + 8, 1,
        0.72 * opacity, 0.45, 0.66, 0.72)
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
    self:drawText(directionText, playerX + 4, footerY + 18,
        directionR, directionG, directionB, 1, UIFont.Small)
    self:drawTextRight(
        budgetAndCapacity, traderX + paneWidth - 4, footerY + 18,
        0.90, 0.90, 0.90,
        1, UIFont.Small
    )
    if self.statusText and self.statusText ~= "" then
        self:drawText(Layout.Ellipsize(tostring(self.statusText), UIFont.Small,
            self.width - 16), 8, statusY,
            self.tradeStatusKind == "success" and 0.55 or 0.92,
            self.tradeStatusKind == "success" and 0.94 or 0.82,
            self.tradeStatusKind == "success" and 0.68 or 0.64,
            1, UIFont.Small)
    end
end

return ISPNCInventoryWindow
