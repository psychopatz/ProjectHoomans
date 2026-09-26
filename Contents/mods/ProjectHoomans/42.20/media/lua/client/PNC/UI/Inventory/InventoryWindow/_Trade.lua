local Model = PNC.InventoryUIModel
local TransferEndpoint = PNC.InventoryTransferEndpoint
local Helpers = require "PNC/UI/Inventory/InventoryWindow/_Helpers"
local tr = Helpers.tr
local Layout = PsychopatzCore.UI.Layout

local TRADE_COLUMNS = {
    { key = "category", x = 0.44 },
    { key = "availability", x = 0.61 },
    { key = "unitPrice", x = 0.72 },
    { key = "action", x = 0.84 },
}

local function number(value, fallback)
    value = tonumber(value)
    return value or fallback or 0
end

local function rowQuantity(row)
    return math.max(0, math.floor(number(row and row.availableQuantity, 0)))
end

local function setListMode(list, window)
    if not list then return end
    list.selectOnly = true
    list.catalogColumns = TRADE_COLUMNS
    list.onCatalogCell = function(target, row, key, offset, width)
        if target and target.onTradeCatalogCell then
            return target:onTradeCatalogCell(row, key, offset, width)
        end
        return false
    end
    list.ownerWindow = window
end

local function configureButton(button, visible, enabled)
    if not button then return end
    button:setVisible(visible == true)
    button:setEnable(enabled ~= false)
end

function ISPNCInventoryWindow:onTradeResponsiveLayout()
    if not self.playerList or not self.npcList then return end
    local titleHeight = self:titleBarHeight()
    local top = titleHeight + 74
    local bottom = 56 + self:resizeWidgetHeight()
    local gap = 8
    local paneWidth = math.max(180, math.floor((self.width - gap * 3) / 2))
    local listHeight = math.max(120, self.height - top - bottom)
    local buttonY = top + listHeight + 4
    local traderX = gap * 2 + paneWidth
    Layout.SetBounds(self.playerList, gap, top, paneWidth, listHeight)
    Layout.SetBounds(self.npcList, traderX, top, paneWidth, listHeight)
    Layout.SetBounds(self.tradeResetButton, gap, buttonY, 92, 22)
    Layout.SetBounds(self.tradeAcceptButton, gap + 100, buttonY,
        math.max(80, paneWidth - 100), 22)
    Layout.SetBounds(self.tradeCancelButton, traderX, buttonY,
        paneWidth, 22)
    self.playerPaneX = gap
    self.npcPaneX = traderX
    self.paneWidth = paneWidth
    self.headingY = titleHeight + 8
    self.containerLabelY = titleHeight + 31
    self.statusY = buttonY + 27
end

function ISPNCInventoryWindow:onTradeModeChanged(active)
    self.tradeMode = active == true
    if not self.tradeMode then
        self.tradeDraft = nil
        self.tradePending = false
        for _, list in ipairs({ self.playerList, self.npcList }) do
            if list then
                list.selectOnly = false
                list.catalogColumns = nil
                list.onCatalogCell = nil
            end
        end
        if self.playerContainerList then self.playerContainerList:setVisible(true) end
        if self.npcContainerList then self.npcContainerList:setVisible(true) end
        if self.giveAllButton then self.giveAllButton:setVisible(true) end
        if self.takeAllButton then self.takeAllButton:setVisible(true) end
        if self.depositStorageButton then
            self.depositStorageButton:setVisible(
                self.transferEndpoint and self.transferEndpoint.kind == "npc"
            )
        end
        configureButton(self.tradeResetButton, false, false)
        configureButton(self.tradeAcceptButton, false, false)
        configureButton(self.tradeCancelButton, false, false)
        return
    end
    self.tradeDraft = self.tradeDraft or { buy = {}, sell = {} }
    setListMode(self.playerList, self)
    setListMode(self.npcList, self)
    if self.playerContainerList then self.playerContainerList:setVisible(false) end
    if self.npcContainerList then self.npcContainerList:setVisible(false) end
    if self.giveAllButton then self.giveAllButton:setVisible(false) end
    if self.refreshNPCButton then self.refreshNPCButton:setVisible(false) end
    if self.takeAllButton then self.takeAllButton:setVisible(false) end
    if self.depositStorageButton then self.depositStorageButton:setVisible(false) end
    configureButton(self.tradeResetButton, true, true)
    configureButton(self.tradeAcceptButton, true, false)
    configureButton(self.tradeCancelButton, true, true)
    if self.onResponsiveLayout then self:onResponsiveLayout() end
end

local function applyDraft(row, draft)
    local key = tostring(row and row.tradeKey or "")
    local quantity = math.max(0, math.floor(number(draft and draft[key], 0)))
    local maximum = rowQuantity(row)
    row.selectedQuantity = math.min(maximum, quantity)
    row.catalogCells = row.catalogCells or {}
    row.catalogCells.action = "-  " .. tostring(row.selectedQuantity) .. "  +"
end

local function playerSellPrice(endpoint, row)
    if endpoint and endpoint.priceFor then
        return endpoint:priceFor(row.fullType, "SELL")
    end
    return number(row.unitPrice, 0)
end

local function buildPlayerRows(window, player, container)
    local endpoint = window.transferEndpoint
    local rows = Model.BuildTradePlayerRows(
        container,
        player,
        window.expandedPlayerGroups,
        nil
    )
    for index = 1, #rows do
        local row = rows[index]
        row.unitPrice = math.max(0, math.floor(number(
            playerSellPrice(endpoint, row), 0
        )))
        row.catalogCells = row.catalogCells or {}
        row.catalogCells.unitPrice = "$" .. tostring(row.unitPrice)
        row.catalogColors = row.catalogColors or {}
        row.catalogColors.unitPrice = "success"
        applyDraft(row, window.tradeDraft and window.tradeDraft.sell)
    end
    return rows
end

local function refreshList(list, rows)
    list:clear()
    for index = 1, #(rows or {}) do
        local row = rows[index]
        list:addItem(row.name, row)
    end
end

function ISPNCInventoryWindow:refreshTradeInventory(force)
    local player = getSpecificPlayer and getSpecificPlayer(0)
        or getPlayer and getPlayer() or nil
    local endpoint = self.transferEndpoint
    if not endpoint or endpoint.kind ~= "trade" then return end
    self.tradeDraft = self.tradeDraft or { buy = {}, sell = {} }
    self.playerContainers = Model.BuildPlayerContainers(player)
    self.selectedPlayerContainer = self.selectedPlayerContainer or "root"
    local playerContainer = Model.FindContainer(
        self.playerContainers, self.selectedPlayerContainer
    )
    if not playerContainer then
        self.selectedPlayerContainer = "root"
        playerContainer = Model.FindContainer(self.playerContainers, "root")
    end
    local playerRows = buildPlayerRows(self, player, playerContainer)
    local stockRows = endpoint:rows()
    for index = 1, #stockRows do
        applyDraft(stockRows[index], self.tradeDraft.buy)
    end
    self.tradePlayerRows = playerRows
    self.tradeStockRows = stockRows
    self.playerRowsCache = playerRows
    self.npcContainers = endpoint:containers()
    refreshList(self.playerList, playerRows)
    refreshList(self.npcList, stockRows)
    self.npcDisplayName = tostring(endpoint.snapshot
        and (endpoint.snapshot.displayName or endpoint.snapshot.traderName)
        or "Caravan Trader")
    if self.setTitle then
        self:setTitle(tr("UI_PNC_Trading_Title", "Trading") .. " - "
            .. self.npcDisplayName)
    end
    self.tradeTotals = self:getTradeTotals()
    if self.tradeAcceptButton then
        local hasRows = self.tradeTotals.buyQuantity > 0
            or self.tradeTotals.sellQuantity > 0
        self.tradeAcceptButton:setEnable(not self.tradePending and hasRows)
    end
    self.contextSignature = tostring(endpoint:revision()) .. "|"
        .. tostring(#playerRows) .. "|" .. tostring(#stockRows) .. "|"
        .. tostring(self.tradeTotals.buyTotal) .. "|"
        .. tostring(self.tradeTotals.sellTotal)
end

function ISPNCInventoryWindow:getTradeTotals()
    local output = {
        buyQuantity = 0, sellQuantity = 0,
        buyTotal = 0, sellTotal = 0,
    }
    for _, row in ipairs(self.tradePlayerRows or {}) do
        local quantity = math.max(0, math.floor(number(
            row.selectedQuantity, 0
        )))
        output.sellQuantity = output.sellQuantity + quantity
        output.sellTotal = output.sellTotal
            + quantity * math.max(0, math.floor(number(row.unitPrice, 0)))
    end
    for _, row in ipairs(self.tradeStockRows or {}) do
        local quantity = math.max(0, math.floor(number(
            row.selectedQuantity, 0
        )))
        output.buyQuantity = output.buyQuantity + quantity
        output.buyTotal = output.buyTotal
            + quantity * math.max(0, math.floor(number(row.unitPrice, 0)))
    end
    output.netTotal = output.buyTotal - output.sellTotal
    return output
end

function ISPNCInventoryWindow:changeTradeQuantity(row, delta)
    if not self.tradeMode or type(row) ~= "table" then return false end
    local side = row.tradeSide == "sell" and "sell" or "buy"
    local key = tostring(row.tradeKey or row.fullType or row.id or "")
    if key == "" then return false end
    self.tradeDraft = self.tradeDraft or { buy = {}, sell = {} }
    local current = math.floor(number(self.tradeDraft[side][key], 0))
    local nextQuantity = math.max(0, math.min(
        rowQuantity(row), current + math.floor(number(delta, 0))
    ))
    self.tradeDraft[side][key] = nextQuantity
    self.contextSignature = nil
    self:refreshTradeInventory(true)
    return true
end

function ISPNCInventoryWindow:onTradeCatalogCell(row, key, offset, width)
    if not row or row.catalogHeader == true then return false end
    if key == "action" then
        local half = math.max(1, number(width, 1) / 2)
        return self:changeTradeQuantity(row, number(offset, 0) < half and -1 or 1)
    end
    return self:changeTradeQuantity(row, 1)
end

function ISPNCInventoryWindow:onInventoryRowClick(role, row)
    if self.tradeMode then return self:changeTradeQuantity(row, 1) end
    if row and row.groupHeader then
        return self:toggleInventoryGroup(role, row.groupKey)
    end
    return self:requestTransfer(
        role == "player" and "player_to_npc" or "npc_to_player", row
    )
end

function ISPNCInventoryWindow:tradeRequestRows()
    local buyRows = {}
    local sellRows = {}
    for _, row in ipairs(self.tradeStockRows or {}) do
        if row.selectedQuantity and row.selectedQuantity > 0 then
            buyRows[#buyRows + 1] = {
                fullType = row.fullType,
                quantity = row.selectedQuantity,
            }
        end
    end
    for _, row in ipairs(self.tradePlayerRows or {}) do
        if row.selectedQuantity and row.selectedQuantity > 0 then
            sellRows[#sellRows + 1] = {
                fullType = row.fullType,
                quantity = row.selectedQuantity,
                itemIDs = row.itemIDs or { row.id },
            }
        end
    end
    return buyRows, sellRows
end

function ISPNCInventoryWindow:onTradeAccept()
    if not self.tradeMode or self.tradePending then return false end
    local buyRows, sellRows = self:tradeRequestRows()
    if #buyRows < 1 and #sellRows < 1 then return false end
    self.tradePending = true
    self.statusText = tr("UI_PNC_Trading_Submitting", "Submitting trade...")
    self.tradeAcceptButton:setEnable(false)
    local ok, reason = self.transferEndpoint:commit(buyRows, sellRows)
    if ok ~= true then
        self.tradePending = false
        self.statusText = tr("UI_PNC_Trading_Failed", "Trade failed") .. ": "
            .. tostring(reason or "unavailable"):gsub("_", " ")
        self:refreshTradeInventory(true)
        return false, reason
    end
    return true
end

function ISPNCInventoryWindow:onTradeReset()
    if not self.tradeMode then return false end
    self.tradeDraft = { buy = {}, sell = {} }
    self.tradePending = false
    self.statusText = nil
    self.contextSignature = nil
    self:refreshTradeInventory(true)
    return true
end

function ISPNCInventoryWindow:onTradeCancel()
    if not self.tradeMode then return false end
    self:close()
    return true
end

function ISPNCInventoryWindow:applyTradeResult(result)
    if not self.tradeMode then return false end
    result = type(result) == "table" and result or {}
    self.tradePending = false
    if result.snapshot and self.transferEndpoint
        and self.transferEndpoint.setSnapshot
    then
        self.transferEndpoint:setSnapshot(result.snapshot)
    end
    if result.accepted == true then
        self.tradeDraft = { buy = {}, sell = {} }
        self.statusText = tr("UI_PNC_Trading_Complete", "Trade complete")
    else
        self.statusText = tr("UI_PNC_Trading_Failed", "Trade failed") .. ": "
            .. tostring(result.reason or "rejected"):gsub("_", " ")
    end
    self.contextSignature = nil
    self:refreshTradeInventory(true)
    return result.accepted == true
end

function ISPNCInventoryWindow:showTradeContext()
    return false
end

return ISPNCInventoryWindow
