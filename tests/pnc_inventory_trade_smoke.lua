local T = require "tests/support/test"

local CLIENT_ROOT = T.path("ProjectHoomans", "client", "")

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "client" },
    { "PsychopatzCore", "common" },
    { "PsychopatzCore", "client" },
    { "PsychopatzCore", "shared" },
})

PsychopatzCore = {
    UI = { Layout = {} },
}
PNC = {
    Core = { Now = function() return 1000 end },
    Equipment = {
        CreateItem = function(fullType)
            return {
                getDisplayName = function() return fullType end,
                getDisplayCategory = function() return "Item" end,
                getTex = function() return "texture:" .. fullType end,
                getActualWeight = function() return 1 end,
            }
        end,
    },
}
getTexture = function(path) return path end
package.preload["PNC/00_PNC_Init"] = function() return PNC end

T.load(CLIENT_ROOT .. "PNC/UI/Inventory/PNC_InventoryUI_Model.lua")
local Model = PNC.InventoryUIModel

local stockRows = Model.BuildTradeStockRows({
    { fullType = "Base.Bandage", quantity = 4, unitPrice = 12 },
    { fullType = "Base.Gun", quantity = 1, unitPrice = 200,
        guardEquipment = true },
    { fullType = "Base.Disabled", quantity = 1, unitPrice = 1,
        disabled = true },
})
T.equal(#stockRows, 1, "trade stock hides guard and disabled rows")
T.equal(stockRows[1].tradeSide, "buy", "stock row is a buy row")
T.equal(stockRows[1].availableQuantity, 4,
    "trade stock keeps available quantity")
T.equal(stockRows[1].catalogCells.unitPrice, "$12",
    "trade stock exposes unit price")
T.equal(Model.SetTradeRowQuantity(stockRows[1], 2), true,
    "trade row accepts a valid quantity")
T.equal(stockRows[1].catalogCells.action, "-  2  +",
    "trade row updates its quantity control")
T.equal(Model.SetTradeRowQuantity(stockRows[1], 8), false,
    "trade row rejects quantity above availability")

local function javaList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local function item(id, fullType, favorite, equipped)
    return {
        getID = function() return id end,
        getFullType = function() return fullType end,
        getDisplayName = function() return fullType end,
        getDisplayCategory = function() return "Item" end,
        getTex = function() return "texture:" .. fullType end,
        getActualWeight = function() return 1 end,
        isFavorite = function() return favorite == true end,
        isEquipped = function() return equipped == true end,
        getModData = function() return {} end,
    }
end

local ordinary = item("ordinary", "Base.Crisps", false, false)
local favorite = item("favorite", "Base.Bandage", true, false)
local equipped = item("equipped", "Base.Knife", false, true)
local stacked = item("stacked", "Base.Nails", false, false)
stacked.getCount = function() return 5 end
local player = {
    isEquipped = function() return false end,
    getPrimaryHandItem = function() return nil end,
    getSecondaryHandItem = function() return nil end,
    getWornItems = function() return javaList({}) end,
    getAttachedItems = function() return javaList({}) end,
}
local rows = Model.BuildTradePlayerRows({
    id = "root",
    container = {
        getItems = function()
            return javaList({ ordinary, favorite, equipped })
        end,
    },
}, player, {})
T.equal(#rows, 1, "trade player rows hide favorite and equipped items")
T.equal(rows[1].fullType, "Base.Crisps",
    "trade player rows retain ordinary items")
T.equal(rows[1].tradeSide, "sell", "player row is a sell row")

local stackedRows = Model.BuildTradePlayerRows({
    id = "root",
    container = {
        getItems = function() return javaList({ stacked }) end,
    },
}, player, {})
T.equal(#stackedRows, 0, "counted stacks are safely disabled for trade")

PNC.InventoryTransferEndpoint = {}
local Endpoint = T.load(
    "ProjectHoomans",
    "client",
    "PNC/UI/Inventory/PNC_InventoryTransferEndpoint/_Trade.lua"
)
local endpoint = Endpoint.Trade("trader-kestrel", {
    snapshot = {
        items = {
            { fullType = "Base.Bandage", quantity = 1,
                unitPrice = 30, sellPrice = 15 },
        },
        sellRows = {
            { fullType = "Base.Katana", quantity = 1,
                itemIDs = { "katana-1" }, unitPrice = 225 },
            { fullType = "Base.Katana", quantity = 1,
                itemIDs = { "katana-2" }, unitPrice = 100 },
        },
    },
})
T.equal(endpoint:priceFor("Base.Katana", "SELL"), 225,
    "non-stocked sell row uses the authoritative quote")
T.equal(endpoint:priceFor("Base.Katana", "SELL", { "katana-2" }), 100,
    "concrete sell row keeps its instance quote")
T.equal(endpoint:priceFor("Base.Katana", "SELL", { "missing" }), 0,
    "unmatched concrete sell identity remains unavailable")
T.equal(endpoint:priceFor("Base.Machete", "SELL"), 0,
    "unknown sell row remains unavailable")

-- The window must transmit only the identities selected from an aggregate
-- row, not every identity displayed in that row.
PsychopatzCore = { UI = { Layout = {} } }
package.preload["PNC/UI/Inventory/InventoryWindow/_Helpers"] = function()
    return { tr = function(_, fallback) return fallback end }
end
ISPNCInventoryWindow = {}
T.load(
    "ProjectHoomans",
    "client",
    "PNC/UI/Inventory/InventoryWindow/_Trade.lua"
)
local window = {
    tradeStockRows = {},
    tradePlayerRows = {
        {
            fullType = "Base.Katana",
            selectedQuantity = 1,
            itemIDs = { "katana-1", "katana-2" },
            itemIDQuantities = { 1, 1 },
        },
    },
}
local _, selectedSellRows = ISPNCInventoryWindow.tradeRequestRows(window)
T.equal(#selectedSellRows, 1, "trade request retains one selected sell row")
T.equal(#selectedSellRows[1].itemIDs, 1,
    "trade request sends only selected item identities")
T.equal(selectedSellRows[1].itemIDs[1], "katana-1",
    "trade request keeps deterministic aggregate selection order")

local totals = ISPNCInventoryWindow.getTradeTotals({
    tradePlayerRows = {
        { selectedQuantity = 1, unitPrice = 225 },
    },
    tradeStockRows = {
        { selectedQuantity = 2, unitPrice = 30 },
    },
})
T.equal(totals.buyTotal, 60, "trade totals calculate the buy side")
T.equal(totals.sellTotal, 225, "trade totals calculate the sell side")
T.equal(totals.netTotal, -165,
    "negative net clearly represents money paid to the player")

local submitted = nil
local acceptWindow = {
    tradeMode = true,
    tradePending = false,
    tradeStockRows = {},
    tradePlayerRows = {
        {
            fullType = "Base.Katana",
            selectedQuantity = 1,
            itemIDs = { "katana-1" },
            itemIDQuantities = { 1 },
        },
    },
    tradeRequestRows = ISPNCInventoryWindow.tradeRequestRows,
    tradeAcceptButton = {
        setEnable = function(self, enabled) self.enabled = enabled end,
    },
    transferEndpoint = {
        commit = function(_, buyRows, sellRows)
            submitted = { buyRows = buyRows, sellRows = sellRows }
            return true
        end,
    },
}
T.equal(ISPNCInventoryWindow.onTradeAccept(acceptWindow), true,
    "accept starts an asynchronous trade submission")
T.equal(acceptWindow.tradePending, true,
    "accept keeps the button pending until the server result")
T.equal(acceptWindow.statusText, "Submitting trade...",
    "accept exposes its pending status")
T.equal(#submitted.sellRows, 1,
    "accept forwards the selected sell basket")

local resultWindow = {
    tradeMode = true,
    tradePending = true,
    tradeDraft = { buy = {}, sell = {} },
    tradePlayerRows = {},
    tradeStockRows = {},
    transferEndpoint = {
        setSnapshot = function(self, snapshot) self.snapshot = snapshot end,
    },
    refreshTradeInventory = function(self, force) self.refreshed = force end,
}
T.equal(ISPNCInventoryWindow.applyTradeResult(resultWindow, {
    accepted = false,
    reason = "trader_budget_exhausted",
}), false, "rejected trade remains rejected in the UI")
T.equal(resultWindow.statusText,
    "Trade failed: trader budget exhausted",
    "server rejection is visible in the UI status")
T.equal(resultWindow.tradePending, false,
    "rejected trade clears the pending state")

local layout = PsychopatzCore.UI.Layout
layout.SetBounds = function() end
local layoutWindow = {
    width = 600,
    height = 360,
    playerList = {},
    npcList = {},
    titleBarHeight = function() return 20 end,
    resizeWidgetHeight = function() return 12 end,
    layoutCatalogHeaders = function() end,
}
ISPNCInventoryWindow.onTradeResponsiveLayout(layoutWindow)
T.equal(layoutWindow.statusY - layoutWindow.footerY, 38,
    "trade layout reserves a separate status row")
T.truthy(layoutWindow.statusY < layoutWindow.height,
    "trade status row stays inside the minimum window")

layout.Ellipsize = function(text) return text end
PsychopatzCore.UI.Window = { prerender = function() end }
UIFont = { Small = "small" }
T.load(
    "ProjectHoomans",
    "client",
    "PNC/UI/Inventory/InventoryWindow/_TradePresentation.lua"
)
local footerDraws = {}
local footerWindow = {
    width = 600,
    height = 360,
    playerPaneX = 8,
    npcPaneX = 308,
    paneWidth = 284,
    headingY = 28,
    footerY = 270,
    statusY = 308,
    contentSurfaceOpacity = 1,
    npcDisplayName = "Trader",
    tradeTotals = { buyTotal = 0, sellTotal = 1139, netTotal = -1139 },
    transferEndpoint = {
        snapshot = { budget = 0 },
        weight = function() return 24.8, 33.0 end,
    },
    statusText = "Trade failed: trader budget exhausted",
    tradeStatusKind = "failure",
    applyOpacityStyle = function() end,
    refreshInventory = function() end,
    drawRect = function() end,
    drawText = function(_, text, _, y)
        footerDraws[#footerDraws + 1] = { text = text, y = y }
    end,
    drawTextRight = function(_, text, _, y)
        footerDraws[#footerDraws + 1] = { text = text, y = y }
    end,
}
ISPNCInventoryWindow.prerenderTrade(footerWindow)
local footerText = {}
for _, draw in ipairs(footerDraws) do
    footerText[#footerText + 1] = tostring(draw.text)
end
local footerTextJoined = table.concat(footerText, " | ")
T.truthy(string.find(footerTextJoined, "PLAYER RECEIVES: $1139", 1, true),
    "footer explains a negative net as money received")
T.truthy(string.find(footerTextJoined, "BUDGET: $0", 1, true),
    "footer exposes the trader budget")
T.truthy(string.find(footerTextJoined,
    "Trade failed: trader budget exhausted", 1, true),
    "footer exposes the server rejection")

T.finish("pnc_inventory_trade_smoke")
