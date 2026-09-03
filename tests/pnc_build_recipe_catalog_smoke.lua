local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local function list(items)
    return {
        size = function() return #items end,
        get = function(_, index) return items[index + 1] end,
    }
end

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, item in pairs(value) do output[key] = copy(item) end
    return output
end

PNC = { Core = { DeepCopy = copy } }
local input = {
    getPossibleInputItems = function()
        return list({ { getFullName = function() return "Base.Plank" end } })
    end,
    isItemCount = function() return true end,
    getIntAmount = function() return 2 end,
    isKeep = function() return false end,
    isTool = function() return false end,
}
local tool = {
    getPossibleInputItems = function()
        return list({ { getFullName = function() return "Base.Hammer" end } })
    end,
    isItemCount = function() return true end,
    getIntAmount = function() return 1 end,
    isKeep = function() return true end,
    isTool = function() return true end,
}
local craftRecipe = {
    getName = function() return "BuildTest" end,
    getTranslationName = function() return "Test Wall" end,
    getBuildCategory = function() return "Carpentry" end,
    getTime = function() return 120 end,
    getInputs = function() return list({ input, tool }) end,
    getRequiredSkillCount = function() return 0 end,
    getXPAwardCount = function() return 1 end,
    getXPAward = function()
        return {
            getPerk = function()
                return { getId = function() return "Woodwork" end }
            end,
            getAmount = function() return 4.5 end,
        }
    end,
}
local entityRecipe = {
    getCraftRecipe = function() return craftRecipe end,
}
local previewFace = {
    getWidth = function() return 2 end,
    getHeight = function() return 1 end,
    getzLayers = function() return 1 end,
    getMasterX = function() return 0 end,
    getMasterY = function() return 0 end,
    getMasterZ = function() return 0 end,
    getTileInfo = function(_, x)
        return { getSpriteName = function()
            return x == 0 and "test_wall_a" or "test_wall_b"
        end }
    end,
}
local info = {
    getName = function() return "TestWall" end,
    getRecipe = function() return entityRecipe end,
    getFace = function(_, face) return face == "single" and previewFace or nil end,
    getMainSpriteNameUI = function() return "test_wall_icon" end,
    getIconTexture = function() return "native_test_texture" end,
}
SpriteConfigManager = {
    GetObjectInfoList = function() return list({ info }) end,
    GetObjectInfo = function(name)
        return name == "TestWall" and info or nil
    end,
}

local Catalog = T.load("ProjectHoomans", "shared",
    "PNC/Core/Production/PNC_BuildRecipeCatalog.lua")
local rows = Catalog.Build()
T.equal(#rows, 1, "entity recipe discovered")
T.equal(rows[1].objectInfoName, "TestWall", "object identity persisted")
T.equal(rows[1].materials, nil, "native objects stay out of public catalog")
T.equal(rows[1].requirements[1].itemTypes[1], "Base.Plank",
    "stockpile input type discovered")
T.equal(rows[1].requirements[1].amount, 2, "input amount discovered")
T.falsy(rows[1].requirements[1].consumed == false,
    "consumed input remains consumable")
T.equal(rows[1].requirements[2].consumed, false,
    "tool input is retained")
T.equal(rows[1].xpAwards[1].skillId, "Woodwork",
    "recipe XP skill is discovered")
T.equal(rows[1].xpAwards[1].amount, 4.5,
    "recipe XP amount is discovered")
T.equal(Catalog.Get("TestWall").nativeObjectInfo, info,
    "runtime object resolves separately")
T.equal(Catalog.Get("Base.TestWall").nativeObjectInfo, info,
    "full entity names resolve to short object-info names")
T.equal(Catalog.Get("TestWall").iconTexture, "native_test_texture",
    "native UI texture stays available in the runtime descriptor")
T.equal(#Catalog.Get("TestWall").previewTiles.tiles, 2,
    "multi-tile native preview geometry is retained at runtime")
T.equal(rows[1].previewTiles, nil,
    "native preview objects stay out of the public catalog snapshot")
T.equal(Catalog.Queries.FindForAliases({ "missing", "Test Wall" }),
    Catalog.Get("TestWall"), "display aliases resolve native descriptors")
T.equal(Catalog.Queries.FindNativeObjectInfo("Base.TestWall"), info,
    "native object fallback resolves the full entity name")
T.finish("pnc_build_recipe_catalog_smoke")
