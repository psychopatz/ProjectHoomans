local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Model = PNC.InventoryUIModel
local Helpers = require "PNC/UI/Inventory/InventoryWindow/_Helpers"
local inventoryNow = Helpers.inventoryNow
local tr = Helpers.tr
local getTooltipHost = Helpers.getTooltipHost

local function selectedContainerLabel(containers, selected)
    local entry = Model.FindContainer(containers, selected)
    return entry and entry.label or "Inventory"
end

function ISPNCInventoryWindow:prerender()
    local now = inventoryNow()
    if self.inventoryRefreshPending == true
        and now - (tonumber(self.inventoryRefreshStartedAt) or now)
            >= INVENTORY_REFRESH_TIMEOUT_MS
    then
        self:finishInventoryRefresh(false, now)
    end
    self:applyOpacityStyle()
    self:refreshInventory(false)
    self:updateInventoryTooltip()
    UI.Window.prerender(self)
    local player = getSpecificPlayer and getSpecificPlayer(0) or getPlayer and getPlayer() or nil
    local headingY = self.headingY or self:titleBarHeight() + 8
    local containerY = self.containerLabelY or headingY + 21
    local playerX = self.playerPaneX or 8
    local npcX = self.npcPaneX or math.floor(self.width / 2)
    local paneWidth = self.paneWidth or math.floor((self.width - 24) / 2)
    local surfaceOpacity = self.contentSurfaceOpacity or 1
    self:drawRect(playerX, headingY - 3, paneWidth, 19,
        0.50 * surfaceOpacity, 0.10, 0.12, 0.14)
    self:drawRect(npcX, headingY - 3, paneWidth, 19,
        0.50 * surfaceOpacity, 0.14, 0.11, 0.08)
    self:drawText(
        tr("UI_PNC_Inventory_PlayerHeading", "YOUR INVENTORY"),
        playerX + 4, headingY, 0.72, 0.86, 1.00, 1, UIFont.Small
    )
    self:drawText(
        Layout.Ellipsize(
            self.transferEndpoint and self.transferEndpoint.kind == "storage"
                and string.upper(tostring(self.npcDisplayName or "Storage"))
                or string.upper(tostring(self.npcDisplayName or "Companion"))
                    .. "'S INVENTORY",
            UIFont.Small,
            paneWidth - 8
        ),
        npcX + 4, headingY, 1.00, 0.82, 0.62, 1, UIFont.Small
    )
    local playerUsed, playerMax = Model.GetPlayerContainerWeight(
        Model.FindContainer(self.playerContainers, self.selectedPlayerContainer),
        player
    )
    local npcUsed, npcMax = 0, 0
    if self.transferEndpoint then
        npcUsed, npcMax = self.transferEndpoint:weight()
    end
    local playerContainerText = tr("UI_PNC_Inventory_Container", "Container") .. ": "
        .. selectedContainerLabel(self.playerContainers, self.selectedPlayerContainer)
    local npcContainerText = tr("UI_PNC_Inventory_Container", "Container") .. ": "
        .. selectedContainerLabel(self.npcContainers, self.selectedNPCContainer)
    self:drawText(
        Layout.Ellipsize(playerContainerText, UIFont.Small, paneWidth - 100),
        playerX + 4, containerY, 0.90, 0.90, 0.90, 1, UIFont.Small
    )
    self:drawTextRight(
        string.format("%.1f / %.1f", playerUsed, playerMax),
        playerX + paneWidth - 4, containerY,
        0.90, 0.90, 0.90, 1, UIFont.Small
    )
    self:drawText(
        Layout.Ellipsize(npcContainerText, UIFont.Small, paneWidth - 100),
        npcX + 4, containerY, 0.90, 0.90, 0.90, 1, UIFont.Small
    )
    self:drawTextRight(
        string.format("%.1f / %.1f", npcUsed, npcMax),
        npcX + paneWidth - 4, containerY,
        0.90, 0.90, 0.90, 1, UIFont.Small
    )
    local listY = self.playerList and self.playerList:getY() or containerY + 38
    self:drawText(tr("UI_PNC_Inventory_Item", "Item"), self.playerList:getX() + 40, listY - 19,
        0.85, 0.85, 0.85, 1, UIFont.Small)
    if self.giftMode then
        self:drawText(
            tr("UI_PNC_Inventory_GiftScore", "Gift score (A / R / F)"),
            self.playerList:getX() + math.floor(self.playerList.width * 0.64),
            listY - 19,
            0.55, 0.88, 0.68, 1, UIFont.Small
        )
    else
        self:drawText(tr("UI_PNC_Inventory_Category", "Category"),
            self.playerList:getX() + math.floor(self.playerList.width * 0.64),
            listY - 19, 0.85, 0.85, 0.85, 1, UIFont.Small)
    end
    self:drawText(tr("UI_PNC_Inventory_Item", "Item"), self.npcList:getX() + 40, listY - 19,
        0.85, 0.85, 0.85, 1, UIFont.Small)
    self:drawText(tr("UI_PNC_Inventory_Category", "Category"),
        self.npcList:getX() + math.floor(self.npcList.width * 0.64),
        listY - 19, 0.85, 0.85, 0.85, 1, UIFont.Small)
    self:drawTextCentre(
        tr("UI_PNC_Inventory_Bags", "Bags"),
        self.playerContainerList:getX() + math.floor(self.playerContainerList.width / 2),
        listY - 19, 0.85, 0.85, 0.85, 1, UIFont.Small
    )
    self:drawTextCentre(
        tr("UI_PNC_Inventory_Bags", "Bags"),
        self.npcContainerList:getX() + math.floor(self.npcContainerList.width / 2),
        listY - 19, 0.85, 0.85, 0.85, 1, UIFont.Small
    )
    local refreshFeedback = self.inventoryRefreshFeedback
        and self.inventoryRefreshFeedbackUntil
        and now < self.inventoryRefreshFeedbackUntil
        and self.inventoryRefreshFeedback or nil
    if refreshFeedback then
        self:drawTextCentre(refreshFeedback, self.width / 2,
            self.statusY or self.height - 42,
            0.75, 0.82, 0.90, 1, UIFont.Small)
    elseif self.statusText then
        self:drawTextCentre(self.statusText, self.width / 2, self.statusY or self.height - 42,
            0.75, 0.82, 0.90, 1, UIFont.Small)
    else
        self:drawTextCentre(
            tr("UI_PNC_Inventory_DragHint",
                "Bag icons select containers. Drag between sides; right-click NPC items."),
            self.width / 2, self.statusY or self.height - 42,
            0.64, 0.64, 0.64, 1, UIFont.Small
        )
    end
    if self.dragState and self.dragState.row then
        self:drawText(
            tostring(self.dragState.row.name),
            (getMouseX() or 0) - self:getAbsoluteX() + 12,
            (getMouseY() or 0) - self:getAbsoluteY() + 12,
            1, 1, 1, 0.85, UIFont.Small
        )
    end
end

function ISPNCInventoryWindow:onMouseDown(x, y)
    if UI.Window.onMouseDown then
        return UI.Window.onMouseDown(self, x, y)
    end
    return false
end

return ISPNCInventoryWindow
