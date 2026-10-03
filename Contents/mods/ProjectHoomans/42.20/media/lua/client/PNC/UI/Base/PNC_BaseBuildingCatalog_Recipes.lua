local Data = require "PNC/UI/Base/PNC_BaseBuildingData"
local BuildAudit = require "PNC/Core/Diagnostics/PNC_BuildAudit"

local Recipes = {}

-- Facility-backed native objects belong to the FACILITIES tab. Keep the
-- Buildings tab complete for ordinary and modded recipes while excluding the
-- identities already managed by the NPC facility system.
local function facilityRecipeIdentities()
    local identities = {}
    local definitions = PNC.FacilityDefinitions
    for _, definition in pairs(definitions and definitions.ByID or {}) do
        if definition.legacyOnly ~= true then
            local objectInfoName = definition.buildRecipeObjectInfoName
                or definition.entityScript
            if objectInfoName and tostring(objectInfoName) ~= "" then
                identities[tostring(objectInfoName)] = true
            end
        end
    end
    return identities
end

function Recipes.FilterFacilityRecipes(recipes)
    local identities = facilityRecipeIdentities()
    local output = {}
    for _, recipe in ipairs(recipes or {}) do
        local objectInfoName = recipe and (recipe.objectInfoName
            or recipe.recipeKey or recipe.id) or nil
        if not objectInfoName or not identities[tostring(objectInfoName)] then
            output[#output + 1] = recipe
        end
    end
    return output
end

function Recipes.NativeRecipe(recipe)
    local objectInfoName = recipe
        and (recipe.objectInfoName or recipe.recipeKey) or nil
    local catalog = PNC.BuildRecipeCatalog
    local descriptor = objectInfoName and catalog and catalog.Get
        and catalog.Get(objectInfoName) or nil
    return descriptor and descriptor.nativeRecipe or nil
end

function Recipes.Descriptor(recipe)
    local key = recipe and (recipe.objectInfoName or recipe.recipeKey
        or recipe.id) or nil
    local catalog = PNC.BuildRecipeCatalog
    if not key or not catalog then return nil end
    if catalog.Get then
        local descriptor = catalog.Get(key)
        if descriptor then return descriptor end
    end
    if catalog.Queries and catalog.Queries.FindForAliases then
        return catalog.Queries.FindForAliases({ key,
            recipe.recipeName, recipe.displayName })
    end
    return nil
end

function Recipes.IsFavorite(recipe)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local native = Recipes.NativeRecipe(recipe)
    local key
    if not BaseCraftingLogic
        or type(BaseCraftingLogic.getFavouriteModDataString) ~= "function"
    then
        return false
    end
    if native and native.getName then key = native:getName() end
    if key == nil and recipe then
        key = recipe.recipeName or recipe.objectInfoName or recipe.recipeKey
    end
    if key == nil or not player or not player.getModData then return false end
    local ok, favoriteKey = pcall(
        BaseCraftingLogic.getFavouriteModDataString, tostring(key))
    if not ok or not favoriteKey then return false end
    local data = player:getModData()
    return data and data[favoriteKey] == true or false
end

function Recipes.SetFavorite(recipe, value)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local native = Recipes.NativeRecipe(recipe)
    local key
    if not BaseCraftingLogic
        or type(BaseCraftingLogic.getFavouriteModDataString) ~= "function"
    then
        return false
    end
    if native and native.getName then key = native:getName() end
    if key == nil and recipe then
        key = recipe.recipeName or recipe.objectInfoName or recipe.recipeKey
    end
    if key == nil or not player or not player.getModData then return false end
    local ok, favoriteKey = pcall(
        BaseCraftingLogic.getFavouriteModDataString, tostring(key))
    if not ok or not favoriteKey then return false end
    local data = player:getModData()
    if not data then return false end
    data[favoriteKey] = value == true
    if player.transmitModData then player:transmitModData() end
    return true
end

-- The Buildings tab can consume the server snapshot when available. Older
-- projections rebuild the same rows from the shared client catalog and the
-- stockpile state already used by the facility requirements pane.
function Recipes.Catalog(window, building)
    building = building or {}
    local shipped = building.recipes
    if type(shipped) == "table" and #shipped > 0 then
        return Recipes.FilterFacilityRecipes(shipped)
    end
    local catalog = PNC.BuildRecipeCatalog
    if not catalog or type(catalog.Build) ~= "function" then return {} end
    local ok, descriptors = pcall(catalog.Build)
    if not ok or type(descriptors) ~= "table" then
        if BuildAudit.Enabled() then
            BuildAudit.Log("recipe_catalog_failed", {
                "stage=local_build",
                "reason=" .. tostring(descriptors),
            })
        end
        return {}
    end
    local storage = Data.Stockpile(window)
    local rows = {}
    for _, descriptor in ipairs(descriptors) do
        rows[#rows + 1] = {
            id = descriptor.id,
            recipeKey = descriptor.recipeKey,
            objectInfoName = descriptor.objectInfoName,
            displayName = descriptor.displayName,
            recipeName = descriptor.recipeName,
            category = descriptor.category,
            iconName = descriptor.iconName,
            buildWork = descriptor.buildWork,
            requiredSkills = descriptor.requiredSkills,
            requirements = descriptor.requirements,
            materials = Data.MaterialAvailability(storage,
                descriptor.requirements),
        }
    end
    if BuildAudit.Enabled() then
        BuildAudit.Log("recipe_catalog", {
            "source=client",
            "recipes=" .. tostring(#rows),
            "stockpile=" .. tostring(storage ~= nil),
        })
    end
    return Recipes.FilterFacilityRecipes(rows)
end

return Recipes
