local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Options = require "PsychopatzCore/UI/PsychopatzCommandHubOptions"
local Helpers = require "PNC/UI/Inventory/InventoryWindow/_Helpers"
local inventoryNow = Helpers.inventoryNow
local tr = Helpers.tr
local getTooltipHost = Helpers.getTooltipHost
local getTooltipOptions = Helpers.getTooltipOptions
local INVENTORY_REFRESH_COOLDOWN_MS = Helpers.INVENTORY_REFRESH_COOLDOWN_MS
local INVENTORY_REFRESH_FEEDBACK_MS = Helpers.INVENTORY_REFRESH_FEEDBACK_MS

function ISPNCInventoryWindow:initialise()
    UI.Window.initialise(self)
    Options.ApplyOpacity(self, Options.GetOpacity())
end

function ISPNCInventoryWindow:applyOpacityStyle()
    local signature = Options.GetContentOpacitySignature()
    if self.lastContentOpacitySignature == signature then return false end

    local surfaceOpacity = Options.GetContentOpacity("surface")
    local detailOpacity = Options.GetContentOpacity("detail")
    self.contentSurfaceOpacity = surfaceOpacity
    self.contentDetailOpacity = detailOpacity
    self.contentOpacity = detailOpacity

    for _, list in ipairs({
        self.playerList,
        self.npcList,
        self.playerContainerList,
        self.npcContainerList,
    }) do
        Options.ApplySurfaceOpacity(list, "detail")
        if list and list.setContentOpacity then
            list:setContentOpacity(detailOpacity)
        end
    end

    self.lastContentOpacitySignature = signature
    return true
end

function ISPNCInventoryWindow:createChildren()
    UI.Window.createChildren(self)
    self.playerContainerList = ISPNCInventoryContainerList:new(
        268, 88, 40, 348, self, "player"
    )
    self.playerContainerList:initialise()
    self.playerContainerList:instantiate()
    self:addChild(self.playerContainerList)

    self.npcContainerList = ISPNCInventoryContainerList:new(
        576, 88, 40, 348, self, "npc"
    )
    self.npcContainerList:initialise()
    self.npcContainerList:instantiate()
    self:addChild(self.npcContainerList)

    self.playerList = ISPNCInventoryList:new(8, 76, 300, 360, self, "player")
    self.playerList:initialise()
    self.playerList:instantiate()
    self:addChild(self.playerList)

    self.npcList = ISPNCInventoryList:new(316, 76, 300, 360, self, "npc")
    self.npcList:initialise()
    self.npcList:instantiate()
    self:addChild(self.npcList)

    self.giveAllButton = ISButton:new(8, 440, 92, 22,
        tr("UI_PNC_Inventory_GiveAll", "Give All >"),
        self, ISPNCInventoryWindow.onGiveAll)
    self.giveAllButton:initialise()
    self.giveAllButton:instantiate()
    self:addChild(self.giveAllButton)

    self.refreshNPCButton = ISButton:new(108, 440, 180, 22,
        tr("UI_PNC_Inventory_Refresh", "Refresh NPC"),
        self, ISPNCInventoryWindow.onRefreshNPCInventory)
    self.refreshNPCButton:initialise()
    self.refreshNPCButton:instantiate()
    self.refreshNPCButton:setVisible(false)
    self:addChild(self.refreshNPCButton)

    self.takeAllButton = ISButton:new(316, 440, 92, 22,
        tr("UI_PNC_Inventory_TakeAll", "< Take All"),
        self, ISPNCInventoryWindow.onTakeAll)
    self.takeAllButton:initialise()
    self.takeAllButton:instantiate()
    self:addChild(self.takeAllButton)
    self.depositStorageButton = ISButton:new(
        416, 440, 180, 22,
        tr("UI_PNC_Storage_DepositAllNPC", "Deposit All to Storage"),
        self, ISPNCInventoryWindow.onDepositAllStorage
    )
    self.depositStorageButton:initialise()
    self.depositStorageButton:instantiate()
    self.depositStorageButton:setVisible(true)
    self:addChild(self.depositStorageButton)
    getTooltipHost().Install(self, getTooltipOptions())
    self:onResponsiveLayout()
    self:applyOpacityStyle()
    self:refreshInventory(true)
end

function ISPNCInventoryWindow:onResponsiveLayout()
    if not self.playerList or not self.npcList
        or not self.playerContainerList or not self.npcContainerList
    then
        return
    end
    local titleHeight = self:titleBarHeight()
    local top = titleHeight + 70
    local bottom = 56 + self:resizeWidgetHeight()
    local gap = 8
    local paneWidth = math.max(180, math.floor((self.width - gap * 3) / 2))
    local railWidth = 40
    local railGap = 4
    local itemWidth = math.max(132, paneWidth - railWidth - railGap)
    local listHeight = math.max(120, self.height - top - bottom)
    local buttonY = top + listHeight + 4
    local npcX = gap * 2 + paneWidth
    Layout.SetBounds(self.playerList, gap, top, itemWidth, listHeight)
    Layout.SetBounds(
        self.playerContainerList,
        gap + itemWidth + railGap,
        top,
        railWidth,
        listHeight
    )
    Layout.SetBounds(self.npcList, npcX, top, itemWidth, listHeight)
    Layout.SetBounds(
        self.npcContainerList,
        npcX + itemWidth + railGap,
        top,
        railWidth,
        listHeight
    )
    Layout.SetBounds(self.giveAllButton, gap, buttonY, 92, 22)
    Layout.SetBounds(self.refreshNPCButton, gap + 100, buttonY,
        math.max(80, paneWidth - 100), 22)
    Layout.SetBounds(self.takeAllButton, npcX, buttonY, 92, 22)
    Layout.SetBounds(self.depositStorageButton, npcX + 100, buttonY,
        math.max(80, paneWidth - 100), 22)
    self.playerPaneX = gap
    self.npcPaneX = npcX
    self.paneWidth = paneWidth
    self.headingY = titleHeight + 8
    self.containerLabelY = titleHeight + 29
    self.statusY = buttonY + 27
end

function ISPNCInventoryWindow:updateInventoryRefreshButton(now)
    local button = self.refreshNPCButton
    local isNPC = self.transferEndpoint
        and self.transferEndpoint.kind == "npc"
        and self.npcId ~= nil
    if not button then return end
    now = tonumber(now) or inventoryNow()
    local pending = self.inventoryRefreshPending == true
    local last = tonumber(self.lastInventoryRefreshAt)
    local coolingDown = last ~= nil
        and now - last < INVENTORY_REFRESH_COOLDOWN_MS
    button:setVisible(isNPC)
    button:setTitle(pending
        and tr("UI_PNC_Inventory_Refreshing", "Refreshing...")
        or tr("UI_PNC_Inventory_Refresh", "Refresh NPC"))
    button:setEnable(isNPC and not pending and not coolingDown)
end

function ISPNCInventoryWindow:finishInventoryRefresh(success, now)
    now = tonumber(now) or inventoryNow()
    self.inventoryRefreshPending = false
    self.inventoryRefreshStartedAt = nil
    self.inventoryRefreshFeedback = success == true
        and tr("UI_PNC_Inventory_RefreshComplete", "Inventory refreshed")
        or tr("UI_PNC_Inventory_RefreshFailed", "Inventory refresh failed")
    self.inventoryRefreshFeedbackUntil = now + INVENTORY_REFRESH_FEEDBACK_MS
    self:updateInventoryRefreshButton(now)
end

return ISPNCInventoryWindow
