local T = require "tests/support/test"

local FILE = T.path("ProjectHoomans", "client", "PNC/")
    .. "UI/Communities/PNC_ColonyManagementWorkshopTab.lua"

getText = function(key) return key end
PNC = {
    InventoryUIModel = { Probe = function(fullType)
        return { name = fullType, category = "Test", texture = "icon" }
    end },
}
package.preload["PNC/UI/Inventory/PNC_InventoryUI_List"] = function()
    return {}
end
package.preload["PNC/UI/Inventory/PNC_InventoryUI_Model"] = function()
    return PNC.InventoryUIModel
end
local buildStationCalls = {}
package.preload[
    "PNC/UI/Communities/ColonyManagement/PNC_FacilityBuildModal"
] = function()
    return { Open = function(_, _, _, _, focusDefinitionId)
        buildStationCalls[#buildStationCalls + 1] = focusDefinitionId
    end }
end
package.preload[
    "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_FacilityActions"
] = function() return { BeginBuild = function() return true end } end

local function fakeList()
    return { items = {}, clear = function(self) self.items = {} end,
        addItem = function(self, _, row) self.items[#self.items + 1] = row end }
end

local details = {}
local Workshop = T.load(FILE)
local window = {
    tab = "workshop", workshopQuantities = {},
    snapshot = nil,
    workshopRecipeList = fakeList(), workshopSalvageList = fakeList(),
    workshopQueueList = fakeList(),
    addDetail = function(_, label, detail)
        details[#details + 1] = { label = label, detail = detail }
    end,
}
local snapshot = {
    settlement = { facilities = {{ definitionId = "workshop",
        constructionState = "BUILT", components = {
            { role = "work.craft" }, { role = "work.disassemble" },
        } }} },
    storage = { rows = {
        { recordIndex = 1, fullType = "Base.SpearCrafted", quantity = 2 },
        { recordIndex = 2, fullType = "Base.Apple", quantity = 80 },
    } },
    workshop = { knownRecipes = {{ id = 7, status = "AVAILABLE",
        descriptor = { key = "spear", displayName = "Crafted Spear",
            inputs = {{ itemTypes = { "Base.Plank" }, amount = 1 }},
            outputs = {{ itemTypes = { "Base.SpearCrafted" }, amount = 1 }} },
        availability = { 3 } }}, disassemblyCandidates = {
        { fullType = "Base.SpearCrafted", recordIndex = 1, quantity = 2,
            potentialYield = {{ fullType = "Base.Plank", maximum = 1 }} },
    }, orders = {
        { operation = "CONSTRUCT", status = "COMPLETED" },
    } },
}
window.snapshot = snapshot

T.truthy(Workshop.Rebuild(window, snapshot,
    function(_, fallback) return fallback end) == true)
T.truthy(#window.workshopRecipeList.items == 3,
    "workshop must show a catalog header, station group, and recipe row")
T.truthy(window.workshopRecipeList.items[2].stationHeader == true,
    "crafting items are not grouped by station")
local recipe = window.workshopRecipeList.items[3]
T.truthy(recipe.name == "Crafted Spear"
    and recipe.catalogCells.quantity == "-  1  +"
    and recipe.catalogCells.availability == "AVAILABLE",
    "recipe row is missing quantity or stock availability")
T.truthy(#window.workshopSalvageList.items == 3
    and window.workshopSalvageList.items[3].fullType == "Base.SpearCrafted",
    "salvage list should only contain supported grouped specimens")
T.truthy(window.workshopSalvageList.items[3].catalogCells.availability
    == "1x Base.Plank", "salvage row should expose its potential yield")
T.truthy(Workshop.Rebuild(window, snapshot,
    function(_, fallback) return fallback end) == true)
T.truthy(#window.workshopQueueList.items == 1,
    "workshop queue refresh must not accumulate headers")
T.truthy(#details == 0,
    "completed construction history leaked into production queue")
T.truthy(window.workshopLaneAvailability.craft
    and window.workshopLaneAvailability.salvage,
    "workshop subtabs did not share their assigned crafting station")

snapshot.settlement.facilities = {}
T.truthy(Workshop.Rebuild(window, snapshot,
    function(_, fallback) return fallback end) == true)
local missingRecipe = window.workshopRecipeList.items[3]
T.truthy(missingRecipe.stationMissing
    and missingRecipe.enabled == true
    and missingRecipe.catalogCells.action == "BUILD STATION",
    "missing station did not expose its build shortcut")
Workshop.OnCatalogCell(window, missingRecipe, "action", 0, 100)
T.equal(buildStationCalls[1], "workshop",
    "station shortcut did not focus the required building")
T.finish("pnc_colony_management_workshop_catalog_smoke")

T.finish("pnc_colony_management_workshop_catalog_smoke")
