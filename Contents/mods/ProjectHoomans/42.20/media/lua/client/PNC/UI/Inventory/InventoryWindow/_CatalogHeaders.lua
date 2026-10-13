local Components = require "PNC/UI/Shared/PNC_ColonyUIComponents"
local Layout = PsychopatzCore.UI.Layout
local Helpers = require "PNC/UI/Inventory/InventoryWindow/_Helpers"
local tr = Helpers.tr

local HEADER_HEIGHT = 28
local INVENTORY_COLUMNS = {
    { key = "category", x = 0.64 },
}
local TRADE_COLUMNS = {
    { key = "category", x = 0.44 },
    { key = "availability", x = 0.61 },
    { key = "unitPrice", x = 0.72 },
    { key = "action", x = 0.84 },
}

local function createHeader(window, list, columns, minimums, save)
    local header = Components.CreateCatalogHeader(window, columns, {
        lists = { list },
        minWidths = minimums,
        onColumnResizeEnd = function()
            save()
        end,
    })
    header:setContent("ITEM", {}, columns)
    return header
end

local function setBounds(header, x, y, width)
    if not header then return end
    Layout.SetBounds(header, x, y - HEADER_HEIGHT, width, HEADER_HEIGHT)
    if header.layoutSplitters then header:layoutSplitters() end
end

function ISPNCInventoryWindow:initializeCatalogHeaders()
    if self.playerCatalogHeader then return end

    self.inventoryColumnState = Components.CreateCatalogColumnState({
        namespace = "ProjectHoomansInventoryUI",
        fileName = "ProjectHoomans_InventoryUI.txt",
        key = "inventoryColumns",
        columns = INVENTORY_COLUMNS,
    })
    self.tradeColumnState = Components.CreateCatalogColumnState({
        namespace = "ProjectHoomansInventoryUI",
        fileName = "ProjectHoomans_InventoryUI.txt",
        key = "tradeColumns",
        columns = TRADE_COLUMNS,
    })

    local inventoryColumns = self.inventoryColumnState.columns
    self.playerList.catalogColumns = inventoryColumns
    self.npcList.catalogColumns = inventoryColumns
    self.playerCatalogHeader = createHeader(
        self, self.playerList, inventoryColumns, { 150, 80 },
        function() self.inventoryColumnState:save() end
    )
    self.npcCatalogHeader = createHeader(
        self, self.npcList, inventoryColumns, { 150, 80 },
        function() self.inventoryColumnState:save() end
    )

    local tradeColumns = self.tradeColumnState.columns
    self.playerTradeHeader = createHeader(
        self, self.playerList, tradeColumns, { 110, 80, 70, 80, 80 },
        function() self.tradeColumnState:save() end
    )
    self.npcTradeHeader = createHeader(
        self, self.npcList, tradeColumns, { 110, 80, 70, 80, 80 },
        function() self.tradeColumnState:save() end
    )
    self:refreshCatalogHeaders()
    self:setCatalogHeaderVisibility()
end

function ISPNCInventoryWindow:refreshCatalogHeaders()
    if not self.playerCatalogHeader then return end
    local category = self.giftMode
        and tr("UI_PNC_Inventory_GiftPreference", "Like / Dislike")
        or tr("UI_PNC_Inventory_Category", "Category")
    local item = tr("UI_PNC_Inventory_Item", "Item")
    self.playerCatalogHeader:setContent(item, { category = category },
        self.inventoryColumnState.columns)
    self.npcCatalogHeader:setContent(item, {
        category = tr("UI_PNC_Inventory_Category", "Category"),
    }, self.inventoryColumnState.columns)

    local tradeCells = {
        category = tr("UI_PNC_Trading_Category", "Category"),
        availability = tr("UI_PNC_Trading_Available", "Available"),
        unitPrice = tr("UI_PNC_Trading_Price", "Price"),
        action = tr("UI_PNC_Trading_Offer", "Offer"),
    }
    self.playerTradeHeader:setContent(
        tr("UI_PNC_Trading_Item", "Item"), tradeCells,
        self.tradeColumnState.columns
    )
    self.npcTradeHeader:setContent(
        tr("UI_PNC_Trading_Item", "Item"), tradeCells,
        self.tradeColumnState.columns
    )
end

function ISPNCInventoryWindow:setCatalogHeaderVisibility()
    local trade = self.tradeMode == true
    for _, header in ipairs({
        self.playerCatalogHeader, self.npcCatalogHeader,
    }) do
        if header then header:setVisible(not trade) end
    end
    for _, header in ipairs({
        self.playerTradeHeader, self.npcTradeHeader,
    }) do
        if header then header:setVisible(trade) end
    end
end

function ISPNCInventoryWindow:layoutCatalogHeaders(
    top, itemWidth, listHeight, paneWidth, npcX
)
    setBounds(self.playerCatalogHeader, 8, top, itemWidth)
    setBounds(self.npcCatalogHeader, npcX, top, itemWidth)
    setBounds(self.playerTradeHeader, 8, top, itemWidth)
    setBounds(self.npcTradeHeader, npcX, top, itemWidth)
    self:refreshCatalogHeaders()
    self:setCatalogHeaderVisibility()
end

return ISPNCInventoryWindow
