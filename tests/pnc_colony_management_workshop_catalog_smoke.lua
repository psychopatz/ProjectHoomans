local FILE = "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/"
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

local function fakeList()
    return { items = {}, clear = function(self) self.items = {} end,
        addItem = function(self, _, row) self.items[#self.items + 1] = row end }
end

local details = {}
local window = {
    tab = "workshop", workshopQuantities = {},
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

assert(dofile(FILE).Rebuild(window, snapshot,
    function(_, fallback) return fallback end) == true)
assert(#window.workshopRecipeList.items == 2,
    "workshop must show one header and one recipe row")
local recipe = window.workshopRecipeList.items[2]
assert(recipe.name == "Crafted Spear"
    and recipe.catalogCells.quantity == "-  1  +"
    and recipe.catalogCells.availability == "AVAILABLE",
    "recipe row is missing quantity or stock availability")
assert(#window.workshopSalvageList.items == 2
    and window.workshopSalvageList.items[2].fullType == "Base.SpearCrafted",
    "salvage list should only contain supported grouped specimens")
assert(window.workshopSalvageList.items[2].catalogCells.availability
    == "1x Base.Plank", "salvage row should expose its potential yield")
assert(dofile(FILE).Rebuild(window, snapshot,
    function(_, fallback) return fallback end) == true)
assert(#window.workshopQueueList.items == 1,
    "workshop queue refresh must not accumulate headers")
assert(#details == 0,
    "completed construction history leaked into production queue")
assert(window.workshopLaneAvailability.craft
    and window.workshopLaneAvailability.salvage,
    "workshop subtabs did not discover their assigned components")

print("pnc_colony_management_workshop_catalog_smoke: ok")
