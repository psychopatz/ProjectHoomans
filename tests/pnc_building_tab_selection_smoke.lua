local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "client" } })

package.preload["ISUI/ISTextEntryBox"] = function()
    return true
end

local function newList()
    local list = { items = {}, selected = 0, yScroll = 0 }
    function list:clear()
        self.items = {}
        self.selected = 0
        self.yScroll = 0
    end
    function list:addItem(name, item)
        self.items[#self.items + 1] = { text = name, item = item }
    end
    function list:selectedRow()
        local entry = self.items[self.selected or 0]
        return entry and entry.item or nil
    end
    return list
end

ISPNCInventoryList = {
    new = function() return newList() end,
}
package.preload["PNC/UI/Inventory/PNC_InventoryUI_List"] = function()
    return ISPNCInventoryList
end
package.preload["PNC/UI/Inventory/PNC_InventoryUI_Model"] = function()
    return { Probe = function() return {} end }
end
package.preload["PNC/UI/Communities/ColonyManagement/PNC_BuildingPlacement"] = function()
    return { Cancel = function() end }
end

PNC = { Client = {} }
local Building = T.load("ProjectHoomans", "client",
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagementBuildingTab.lua")

local recipes = {
    { objectInfoName = "WallA", recipeKey = "WallA", displayName = "Wall A",
        category = "Carpentry", materials = {} },
    { objectInfoName = "WallB", recipeKey = "WallB", displayName = "Wall B",
        category = "Carpentry", materials = {} },
    { objectInfoName = "Fence", recipeKey = "Fence", displayName = "Fence",
        category = "Outdoors", materials = {} },
}
local queue = {
    { id = "order-a", displayName = "Wall A", percent = 40,
        status = "WORKING", materials = {
            { itemTypes = { "Base.Plank" }, amount = 2, available = 2,
                ready = true },
        } },
    { id = "order-b", displayName = "Wall B", percent = 10,
        status = "QUEUED", materials = {} },
}

local window = {
    tab = "building", buildCategory = "ALL",
    buildCategoryList = newList(), buildRecipeList = newList(),
    buildQueueList = newList(), buildMaterialList = newList(),
}
Building.Rebuild(window, { building = { recipes = recipes, queue = queue } })

window.buildCategory = "Carpentry"
window.buildCategoryList.selected = 3
window.buildSelectedRecipe = recipes[2]
window.buildRecipeList.selected = 3
window.buildRecipeList.yScroll = 64
window.buildQueueList.selected = 2
window.buildQueueList.yScroll = 32

Building.Rebuild(window, { building = { recipes = recipes, queue = queue } })
T.equal(window.buildCategoryList:selectedRow().category, "Carpentry",
    "category selection survives snapshot rebuild")
T.equal(window.buildRecipeList:selectedRow().recipe.objectInfoName, "WallB",
    "recipe selection survives snapshot rebuild")
T.equal(window.buildRecipeList.yScroll, 64,
    "recipe scroll position survives snapshot rebuild")
T.equal(window.buildQueueList:selectedRow().order.id, "order-a",
    "queue selection survives snapshot rebuild")
T.equal(window.buildQueueList.yScroll, 32,
    "queue scroll position survives snapshot rebuild")
T.equal(window.buildMaterialList.items[2].item.name, "Base.Plank",
    "materials follow the selected queue order after rebuild")

local debugRequest
PNC.Client.RequestColonyAction = function(action, args)
    debugRequest = { action = action, args = args }
end
window.buildDebugAvailable = true
recipes[1].materials = {{ itemTypes = { "Base.Plank" }, amount = 1,
    available = 0, ready = false }}
Building.Rebuild(window, { building = { recipes = recipes, queue = queue } })
local missingRow
for _, entry in ipairs(window.buildRecipeList.items or {}) do
    if entry.item and entry.item.recipe == recipes[1] then
        missingRow = entry.item
        break
    end
end
T.equal(missingRow.catalogCells.action, "GIVE",
    "debug-enabled missing building exposes material shortcut")
Building.OnRecipeCell(window, missingRow, "action")
T.equal(debugRequest.action, "building_debug_get_items",
    "building material shortcut uses existing debug action")
T.equal(debugRequest.args.recipeKey, "WallA",
    "building material shortcut targets selected recipe")

T.finish("pnc_building_tab_selection_smoke")
