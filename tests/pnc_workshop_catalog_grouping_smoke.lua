local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "client" },
})

package.preload["PNC/UI/Inventory/PNC_InventoryUI_Model"] = function()
    return {
        Probe = function(fullType)
            return { name = tostring(fullType), texture = nil }
        end,
    }
end

package.preload["PNC/Core/Settlement/PNC_FacilityState"] = function()
    return { IsBuilt = function() return true end }
end

PNC = {
    WorkDefinitions = {
        CRAFTING_SKILL_ORDER = { "CARVING", "BLACKSMITH" },
        GetStation = function(_, operation)
            if operation == "CRAFT" then
                return {
                    id = "workshop", facilityId = "workshop",
                    role = "work.craft", labelKey = "CRAFTING STATION",
                }
            end
            return nil
        end,
        GetProductionSkillId = function(descriptor)
            return descriptor and descriptor.productionSkillId
        end,
        GetProductionSkillLabel = function(skillId)
            return tostring(skillId)
        end,
    },
    WorkshopCatalogRebuild = {},
}

local Helpers = T.load("ProjectHoomans", "client",
    "PNC/UI/Workshop/PNC_WorkshopCatalog_Rebuild_Helpers.lua")
T.load("ProjectHoomans", "client",
    "PNC/UI/Workshop/PNC_WorkshopCatalog_Rebuild_Rows.lua")
local Internal = Helpers.Internal

local function station(id, label)
    return {
        id = id, facilityId = id, role = "work.craft",
        labelKey = label or id,
    }
end

local function recipe(id, skillId, requiredStation)
    return {
        id = id, status = "AVAILABLE", requiredStation = requiredStation,
        descriptor = {
            displayName = id, productionSkillId = skillId, inputs = {},
            outputs = { { itemTypes = { "Base." .. id } } },
        },
    }
end

local function list()
    return {
        items = {},
        clear = function(self) self.items = {} end,
        addItem = function(self, key, item)
            self.items[#self.items + 1] = { key = key, item = item }
        end,
    }
end

local function translation(_, fallback) return fallback end

local carving = recipe("Carve Bat", "CARVING", nil)
local forgeWorkshop = recipe("Forge Hinge", "BLACKSMITH", station("workshop",
    "CRAFTING STATION"))
local forgeAdvanced = recipe("Forge Buckle", "BLACKSMITH", station("forge",
    "ADVANCED FORGE"))
forgeAdvanced.descriptor.requiresSpecificWorkstation = true
local recipes = { forgeAdvanced, carving, forgeWorkshop }

T.falsy(Internal.StationGroupingRequired({ carving }, "CRAFT", "CARVING"),
    "single default station must not create a nested station group")
T.truthy(Internal.StationGroupingRequired(recipes, "CRAFT", "BLACKSMITH"),
    "multiple stations must retain station grouping")

local window = {
    tab = "workshop", workshopQuantities = {},
    workshopCollapsedGroups = {}, workshopRecipeList = list(),
}
Internal.RebuildCraftRows(window, recipes, translation, function() return true end)

local rows = window.workshopRecipeList.items
T.equal(#rows, 7, "runtime-shaped catalog produced expected row count")
T.equal(rows[1].item.skillHeader, true, "carving skill header emitted")
T.equal(rows[2].item.rowKind, "recipe",
    "single-station carving rows sit directly under the skill")
T.falsy(rows[2].item.stationHeader,
    "single-station carving row is not a station header")
T.equal(rows[3].item.skillHeader, true, "blacksmith skill header emitted")
T.equal(rows[4].item.stationHeader, true,
    "blacksmith keeps its first meaningful station group")
T.equal(rows[5].item.rowKind, "recipe", "first blacksmith recipe emitted")
T.equal(rows[6].item.stationHeader, true,
    "blacksmith keeps its second meaningful station group")
T.equal(rows[7].item.rowKind, "recipe", "second blacksmith recipe emitted")

local missingWindow = {
    tab = "workshop", workshopQuantities = {},
    workshopCollapsedGroups = {}, workshopRecipeList = list(),
}
Internal.RebuildCraftRows(missingWindow, recipes, translation,
    function(stationValue)
        return stationValue and stationValue.id ~= "forge"
    end)
local missingRows = missingWindow.workshopRecipeList.items
local missingHeader = missingRows[4].item
local missingRecipe = missingRows[5].item
T.truthy(missingHeader.stationHeader
    and string.find(missingHeader.name, "MISSING STATION", 1, true),
    "missing station status was not promoted to its nested header")
T.truthy(missingHeader.catalogControls
    and missingHeader.catalogControls.action
    and missingHeader.catalogControls.action[1].title == "BUILD STATION",
    "missing station header did not expose one build action")
T.equal(missingRecipe.catalogCells.action, "",
    "missing station action was repeated on every recipe row")
T.falsy(missingRecipe.catalogControls.action,
    "missing station recipe still created a duplicate action button")

local singleMissingWindow = {
    tab = "workshop", workshopQuantities = {},
    workshopCollapsedGroups = {}, workshopRecipeList = list(),
}
Internal.RebuildCraftRows(singleMissingWindow, { forgeAdvanced }, translation,
    function() return false end)
local singleMissingRows = singleMissingWindow.workshopRecipeList.items
T.equal(#singleMissingRows, 3,
    "a single missing station must still get an actionable nested header")
T.truthy(singleMissingRows[2].item.stationHeader
    and singleMissingRows[2].item.stationMissing,
    "single missing station header was omitted")

return T.finish("pnc_workshop_catalog_grouping_smoke")
