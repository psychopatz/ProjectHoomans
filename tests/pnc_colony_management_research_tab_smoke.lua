local T = require "tests/support/test"

local FILE = T.path("ProjectHoomans", "client", "PNC/")
    .. "UI/Communities/PNC_ColonyManagementResearchTab.lua"

getText = function(key) return key end

PNC = { InventoryUIModel = { Probe = function() return {} end } }
local function fakeList()
    return { items = {}, clear = function(self) self.items = {} end,
        addItem = function(self, _, row) self.items[#self.items + 1] = row end }
end
package.preload["PNC/UI/Inventory/PNC_InventoryUI_List"] = function()
    return {}
end
package.preload["PNC/UI/Inventory/PNC_InventoryUI_Model"] = function()
    return PNC.InventoryUIModel
end

local ResearchTab = T.load(FILE)
local rows = {}
local window = {
    tab = "research",
    researchBlueprintIndex = 1,
    researchSpecimenIndex = 1,
    snapshot = { storage = { rows = {} } },
    researchCatalog = fakeList(),
    researchQueueList = fakeList(),
    addDetail = function(_, label, detail, color)
        rows[#rows + 1] = {
            label = tostring(label), detail = tostring(detail), color = color,
        }
    end,
}
local snapshot = {
    storage = { rows = {} },
    settlement = { id = "base-1", hqLevel = 1, maxHQLevel = 3,
        facilities = {{ definitionId = "research_facility",
        constructionState = "BUILT", components = {
            { role = "work.research" },
        } }} },
    research = {
        entries = {{
            id = "facility:workshop", labelKey = "Basic Workshop",
            requiredWork = 60, known = false,
        }, {
            id = "utility:water_collector:1", labelKey = "Water Collection I",
            requiredWork = 65, known = false,
            researchCapability = "work.research",
        }},
        learnedRecipeIds = {},
        orders = {{
            id = "work:1", operation = "RESEARCH", status = "WORKING",
            progress = 15, requiredWork = 60, workerId = "npc:1",
            payload = {
                mode = "technology", technologyId = "facility:workshop",
            },
        }},
    },
}

local rebuilt = ResearchTab.Rebuild(window, snapshot,
    function(_, fallback) return fallback end)
T.truthy(rebuilt == true, "research tab did not rebuild")
T.truthy(window.researchCatalog.items[2].catalogCells.state == "RESEARCHING 25%",
    "technology catalog row does not expose progress percentage")
T.truthy(window.researchCatalog.items[2].catalogCells.state == "RESEARCHING 25%",
    "active research row does not expose resumable progress")
T.truthy(window.researchCatalog.items[3].catalogCells.state == "NOT LEARNED",
    "water technology should be researchable through the research lane")
T.truthy(window.researchLaneAvailability.base
    and window.researchLaneAvailability.blueprint
    and window.researchLaneAvailability.books,
    "all research lanes should share the Log Table")
ResearchTab.Rebuild(window, snapshot, function(_, fallback) return fallback end)
T.truthy(#window.researchQueueList.items == 2,
    "research queue refresh must not accumulate headers")
T.finish("pnc_colony_management_research_tab_smoke")

T.finish("pnc_colony_management_research_tab_smoke")
