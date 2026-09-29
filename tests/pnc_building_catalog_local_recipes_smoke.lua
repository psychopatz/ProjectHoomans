-- The Buildings tab lists every buildable object the engine knows about,
-- including modded ones, minus the facility-backed recipes that already live in
-- the FACILITIES tab. The lightweight base projection deliberately ships only
-- the blueprint queue, so the client rebuilds the catalog from the shared
-- SpriteConfigManager-backed catalog and prices it against the stockpile rows.
local T = require "tests/support/test"

T.addPackagePaths()

package.preload["PNC/UI/Inventory/PNC_InventoryUI_List"] = function()
    return {}
end
package.preload["PNC/UI/Inventory/PNC_InventoryUI_Model"] = function()
    return { Probe = function(fullType) return { name = tostring(fullType) } end }
end
package.preload["PNC/UI/Base/PNC_BaseBuildingPlacement"] = function()
    return {}
end
package.preload["PNC/UI/Base/PNC_BaseBuildingQueueOverlay"] = function()
    return {}
end
package.preload["PNC/UI/Base/PNC_BaseBuildingQueueActions"] = function()
    return {}
end

-- Native build catalog: a normal wall, a facility-backed table, and a modded
-- gate. All three come from the engine list in a real session.
local descriptors = {
    { id = "Base.Wall", recipeKey = "Base.Wall",
        objectInfoName = "Base.Wall", displayName = "Wooden Wall",
        recipeName = "Wooden Wall", category = "Carpentry",
        buildWork = 40, requiredSkills = {},
        requirements = { { itemTypes = { "Base.Plank" }, amount = 2 } } },
    { id = "Base.Log_Table", recipeKey = "Base.Log_Table",
        objectInfoName = "Base.Log_Table", displayName = "Research Table",
        recipeName = "Research Table", category = "Furniture",
        buildWork = 60, requiredSkills = {},
        requirements = { { itemTypes = { "Base.Log" }, amount = 2 } } },
    { id = "MyMod.StoneGate", recipeKey = "MyMod.StoneGate",
        objectInfoName = "MyMod.StoneGate", displayName = "Stone Gate",
        recipeName = "Stone Gate", category = "Masonry",
        buildWork = 120, requiredSkills = {},
        requirements = { { itemTypes = { "Base.Stone" }, amount = 4 } } },
}

PNC = {
    BuildRecipeCatalog = {
        Generation = 7,
        Build = function() return descriptors end,
    },
    FacilityDefinitions = {
        ByID = {
            research_facility = { buildRecipeObjectInfoName = "Base.Log_Table" },
        },
    },
    Network = { ClientState = { colonyManagement = { storage = { rows = {
        { fullType = "Base.Plank", quantity = 5 },
        { fullType = "Base.Log", quantity = 1 },
    } } } } },
}
PsychopatzCore = { UI = { Theme = {}, Layout = {} } }

local Catalog = T.load("ProjectHoomans", "client",
    "PNC/UI/Base/PNC_BaseBuildingCatalog.lua")
local window = { snapshot = {} }

-- No shipped recipes: build locally from the shared catalog.
local recipes = Catalog.CatalogRecipes(window, {})
T.equal(#recipes, 2, "facility-backed recipes are excluded from Buildings")
local byKey = {}
for _, recipe in ipairs(recipes) do byKey[recipe.objectInfoName] = recipe end
T.truthy(byKey["Base.Wall"], "vanilla build recipes are listed")
T.truthy(byKey["MyMod.StoneGate"], "modded build recipes are listed")
T.falsy(byKey["Base.Log_Table"],
    "facility-backed recipe stays out of the Buildings tab")

T.truthy(byKey["Base.Wall"].materials[1].ready,
    "affordable recipe is marked ready from stockpile rows")
T.equal(byKey["Base.Wall"].materials[1].available, 5,
    "recipe availability reads the stockpile projection")
T.falsy(byKey["MyMod.StoneGate"].materials[1].ready,
    "recipe without stock is not ready")
T.equal(byKey["MyMod.StoneGate"].materials[1].amount, 4,
    "recipe requirement amount is preserved")

-- Fallback storage: the management projection is used when the base snapshot
-- has not landed yet.
PNC.Network.ClientState.colonyManagement.storage.rows = {}
recipes = Catalog.CatalogRecipes(window, {})
T.equal(#recipes, 2, "catalog still resolves without stockpile rows")
for _, recipe in ipairs(recipes) do
    T.falsy(recipe.materials[1].ready,
        "no stockpile means nothing is priced as ready")
end

-- A server that does ship recipes still wins, and is still filtered.
local shipped = {
    { objectInfoName = "Base.Wall", displayName = "Wooden Wall",
        category = "Carpentry", materials = {} },
    { objectInfoName = "Base.Log_Table", displayName = "Research Table",
        category = "Furniture", materials = {} },
}
recipes = Catalog.CatalogRecipes(window, { recipes = shipped })
T.equal(#recipes, 1, "shipped recipes are filtered too")
T.equal(recipes[1].objectInfoName, "Base.Wall",
    "shipped vanilla recipe is kept")

T.finish("pnc_building_catalog_local_recipes_smoke")
