local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local gameStart
local createPlayer
Events = {
    OnGameStart = { Add = function(callback) gameStart = callback end },
    OnServerStarted = { Add = function() end },
    OnCreatePlayer = { Add = function(callback) createPlayer = callback end },
}

PNC = {}
getSpecificPlayer = function() return nil end
ScriptManager = {
    instance = {
        getAllCraftRecipes = function()
            error("native recipe manager not ready")
        end,
    },
}

local Catalog = T.load("ProjectHoomans", "shared",
    "PNC/Core/Production/PNC_RecipeCatalog.lua")

T.truthy(gameStart, "recipe catalog did not register its startup hook")
T.truthy(createPlayer, "recipe catalog did not register its player hook")
T.falsy(gameStart(), "recipe catalog built before player initialization")
T.equal(Catalog.Diagnostics.lastBuildFailure, "PLAYER_UNAVAILABLE",
    "recipe catalog did not defer on an unavailable player")
T.falsy(Catalog.Ready, "deferred recipe catalog was marked ready")

getSpecificPlayer = function() return {} end
T.falsy(createPlayer(),
    "recipe catalog did not contain a native enumeration failure")
T.equal(Catalog.Diagnostics.lastBuildFailure,
    "CRAFT_RECIPES_ENUMERATION_FAILED",
    "recipe catalog exposed a native enumeration error")

ScriptManager.instance.getAllCraftRecipes = function() return {} end

T.truthy(createPlayer(), "recipe catalog did not build after player creation")
T.truthy(Catalog.Ready, "recipe catalog remained unavailable after retry")
T.falsy(Catalog.Diagnostics.lastBuildFailure,
    "successful recipe catalog build retained a failure state")

return T.finish("pnc_recipe_catalog_lifecycle_smoke")
