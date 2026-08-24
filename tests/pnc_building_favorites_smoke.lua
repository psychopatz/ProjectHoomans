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

local player = { data = {}, transmitted = 0 }
function player:getModData() return self.data end
function player:transmitModData() self.transmitted = self.transmitted + 1 end
getSpecificPlayer = function() return player end

BaseCraftingLogic = {
    getFavouriteModDataString = function(name)
        return "recipeFavourite:" .. tostring(name)
    end,
}
PNC = { Client = {}, BuildRecipeCatalog = {
    Get = function(name)
        return { nativeRecipe = {
            getName = function() return tostring(name) end,
        } }
    end,
} }

local Building = T.load("ProjectHoomans", "client",
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagementBuildingTab.lua")

local recipes = {
    { objectInfoName = "WallA", recipeKey = "WallA", recipeName = "WallA",
        displayName = "Wall A", category = "Carpentry", materials = {} },
    { objectInfoName = "WallB", recipeKey = "WallB", recipeName = "WallB",
        displayName = "Wall B", category = "Carpentry", materials = {} },
}
local window = {
    tab = "building", buildCategory = "ALL",
    buildCategoryList = newList(), buildRecipeList = newList(),
    buildQueueList = newList(), buildMaterialList = newList(),
}

Building.Rebuild(window, { building = { recipes = recipes, queue = {} } })
T.falsy(Building.IsRecipeFavorite(recipes[1]),
    "recipe starts un-favorited")

window.buildSelectedRecipe = recipes[1]
local ok, value = Building.ToggleRecipeFavorite(window)
T.truthy(ok, "favorite toggle succeeds")
T.truthy(value, "toggle returns the new favorite state")
T.truthy(Building.IsRecipeFavorite(recipes[1]),
    "favorite is read from the native recipe key")
T.truthy(player.data["recipeFavourite:WallA"],
    "base-game recipe favorite ModData key is written")
T.equal(player.transmitted, 1,
    "favorite change is transmitted through the base-game pipeline")

window.buildFavoritesOnly = true
Building.Rebuild(window, { building = { recipes = recipes, queue = {} } })
T.equal(#window.buildRecipeList.items, 2,
    "favorites filter keeps the header and only the favorite recipe")
T.equal(window.buildRecipeList.items[2].item.recipe.objectInfoName, "WallA",
    "favorites filter returns the favorite recipe")

T.finish("pnc_building_favorites_smoke")
