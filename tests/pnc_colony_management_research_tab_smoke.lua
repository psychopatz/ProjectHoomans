local FILE = "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/"
    .. "UI/Communities/PNC_ColonyManagementResearchTab.lua"

getText = function(key) return key end

local ResearchTab = dofile(FILE)
local rows = {}
local window = {
    tab = "research",
    researchBlueprintIndex = 1,
    researchSpecimenIndex = 1,
    snapshot = { storage = { rows = {} } },
    addDetail = function(_, label, detail, color)
        rows[#rows + 1] = {
            label = tostring(label), detail = tostring(detail), color = color,
        }
    end,
}
local snapshot = {
    storage = { rows = {} },
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
assert(rows[1].detail:find("25%%"),
    "technology catalog row does not expose progress percentage")
local foundActiveProgress = false
for _, row in ipairs(rows) do
    if row.label:find("RESEARCH WORKING", 1, true)
        and row.label:find("25%%")
        and row.detail == "15.0 / 60.0 WP"
    then
        foundActiveProgress = true
    end
end
assert(foundActiveProgress,
    "active research row does not expose resumable progress")

print("pnc_colony_management_research_tab_smoke: ok")
