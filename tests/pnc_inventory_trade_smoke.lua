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

T.finish("pnc_inventory_trade_smoke")
