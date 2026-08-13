local FILE = "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/"
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

local ResearchTab = dofile(FILE)
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
            { role = "work.research" }, { role = "work.blueprint" },
            { role = "work.reverse" },
        } }} },
    research = {
        entries = {{
            id = "facility:workshop", labelKey = "Basic Workshop",
            requiredWork = 60, known = false,
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
assert(rebuilt == true, "research tab did not rebuild")
assert(window.researchCatalog.items[2].catalogCells.state == "RESEARCHING 25%",
    "technology catalog row does not expose progress percentage")
assert(window.researchCatalog.items[2].catalogCells.state == "RESEARCHING 25%",
    "active research row does not expose resumable progress")
ResearchTab.Rebuild(window, snapshot, function(_, fallback) return fallback end)
assert(#window.researchQueueList.items == 2,
    "research queue refresh must not accumulate headers")

print("pnc_colony_management_research_tab_smoke: ok")
