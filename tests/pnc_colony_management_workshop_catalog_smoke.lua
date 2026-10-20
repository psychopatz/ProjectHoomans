local T = require "tests/support/test"
T.stubClientUI()

local FILE = T.path("ProjectHoomans", "client", "PNC/")
    .. "UI/Workshop/PNC_WorkshopCatalog.lua"

getText = function(key) return key end
PNC = {
    InventoryUIModel = { Probe = function(fullType)
        return { name = fullType, category = "Test", texture = "icon" }
    end },
    FacilityDefinitions = {
        Get = function(id)
            if tostring(id) == "forge" then
                return { id = "forge", directWorkstation = true }
            end
        end,
    },
}
package.preload["PNC/UI/Inventory/PNC_InventoryUI_List"] = function()
    return {}
end
package.preload["PNC/UI/Inventory/PNC_InventoryUI_Model"] = function()
    return PNC.InventoryUIModel
end
local buildStationCalls = {}
PNC.CommandHub = { ChildController = {
    Open = function(_, _, options)
        buildStationCalls[#buildStationCalls + 1] = options.focusDefinitionId
        return true
    end,
} }
package.preload[
    "PNC/UI/SettlementManagement/PNC_SettlementManagement_FacilityActions"
] = function() return { BeginBuild = function() return true end } end

local function fakeList()
    return { items = {}, clear = function(self) self.items = {} end,
        addItem = function(self, _, row) self.items[#self.items + 1] = row end,
        setVisible = function() end }
end

local details = {}
local function fakeHeader()
    return {
        setContent = function(self, title, cells, columns)
            self.title, self.cells, self.columns = title, cells, columns
        end,
        setVisible = function() end,
    }
end
local Workshop = T.load(FILE)
local window = {
    tab = "workshop", workshopQuantities = {},
    snapshot = nil,
    workshopRecipeList = fakeList(), workshopSalvageList = fakeList(),
    workshopQueueList = fakeList(),
    workshopQueueHeader = fakeHeader(),
    workshopRecipeHeader = fakeHeader(),
    workshopSalvageHeader = fakeHeader(),
    workshopQueueColumns = {},
    workshopCatalogColumns = {},
    addDetail = function(_, label, detail)
        details[#details + 1] = { label = label, detail = detail }
    end,
}
local snapshot = {
    settlement = { facilities = {{ definitionId = "forge",
        constructionState = "BUILT", components = {
            { role = "work.craft" }, { role = "work.disassemble" },
        } }} },
    storage = { rows = {
        { recordIndex = 1, fullType = "Base.SpearCrafted", quantity = 2 },
        { recordIndex = 2, fullType = "Base.Apple", quantity = 80 },
    } },
    workshop = { knownRecipes = {{ id = 7, status = "AVAILABLE",
        requiredStation = { id = "forge", facilityId = "forge",
            role = "work.craft" },
        descriptor = { key = "spear", displayName = "Crafted Spear",
            requiresSpecificWorkstation = true,
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
T.truthy(#window.workshopRecipeList.items == 2,
    "workshop must show a skill header and recipe row")
T.truthy(window.workshopRecipeList.items[1].skillHeader == true,
    "crafting items are not grouped by production skill")
local recipe = window.workshopRecipeList.items[2]
T.truthy(recipe.name == "Crafted Spear"
    and recipe.catalogCells.quantity == "1"
    and recipe.catalogCells.availability == "AVAILABLE",
    "recipe row is missing quantity or stock availability")
T.truthy(#window.workshopSalvageList.items == 2
    and window.workshopSalvageList.items[2].fullType == "Base.SpearCrafted",
    "salvage list should only contain supported grouped specimens")
T.truthy(window.workshopSalvageList.items[2].catalogCells.availability
    == "1x Base.Plank", "salvage row should expose its potential yield")
T.truthy(Workshop.Rebuild(window, snapshot,
    function(_, fallback) return fallback end) == true)
T.equal(#window.workshopQueueList.items, 0,
    "completed workshop order is not an active queue row")
T.truthy(#details == 0,
    "completed construction history leaked into production queue")
T.truthy(window.workshopLaneAvailability.craft
    and window.workshopLaneAvailability.salvage,
    "workshop subtabs did not share their assigned crafting station")

snapshot.settlement.facilities = {}
T.truthy(Workshop.Rebuild(window, snapshot,
    function(_, fallback) return fallback end) == true)
local missingHeader = window.workshopRecipeList.items[2]
local missingRecipe = window.workshopRecipeList.items[3]
T.truthy(missingHeader.stationHeader
    and missingHeader.stationMissing
    and missingHeader.catalogCells.action == "BUILD STATION",
    "missing station header did not expose its build shortcut")
T.equal(missingRecipe.catalogCells.action, "",
    "missing station action was repeated on the recipe row")
Workshop.OnCatalogControl(window, missingHeader, "action", {
    command = "activate",
    enabled = true,
})
T.equal(buildStationCalls[1], "forge",
    "station shortcut did not focus the required direct workstation")
T.finish("pnc_colony_management_workshop_catalog_smoke")

T.finish("pnc_colony_management_workshop_catalog_smoke")
