local LUA_ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/"
package.path = LUA_ROOT .. "client/?.lua;" .. package.path

local function contains(value, expected, message)
    if not string.find(tostring(value), tostring(expected), 1, true) then
        error((message or "missing text") .. ": " .. tostring(value), 2)
    end
end

getText = function(key) return key end
getItemNameFromFullType = function(fullType)
    return fullType == "Base.SpearCrafted" and "Crafted Spear" or fullType
end

PNC = {
    FacilityDefinitions = {
        Get = function(id)
            return id == "barracks" and {
                displayNameKey = "UI_PNC_Facility_Barracks",
            } or nil
        end,
    },
    RecipeKnowledgeRegistry = {
        Queries = {
            Resolve = function(id)
                return id == 9 and { descriptor = { outputs = {
                    { itemTypes = { "Base.SpearCrafted" } },
                } } } or nil
            end,
        },
    },
}

local Tasks = require(
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_TasksTab"
)
local rows = Tasks.BuildRows({ snapshot = { tasks = {
    {
        id = "build-1", operation = "CONSTRUCT", status = "WORKING",
        percent = 40, workerId = "npc-1", workerName = "Peter",
        executionMode = "ABSTRACT", facilityDefinitionId = "barracks",
    },
    {
        id = "craft-1", operation = "CRAFT", status = "QUEUED",
        percent = 0, recipeId = 9,
    },
} } })

contains(rows[1].label, "barracks", "construction target")
contains(rows[1].label, "40%", "construction progress")
contains(rows[1].detail, "Peter", "assigned worker")
contains(rows[1].detail, "ABSTRACT", "abstract execution mode")
contains(rows[2].label, "Crafted Spear", "craft output")
contains(rows[2].detail, "UNASSIGNED", "queued task assignment")

local empty = Tasks.BuildRows({ snapshot = { tasks = {} } })
contains(empty[1].label, "NO AVAILABLE TASKS", "empty task state")

local needs = Tasks.BuildRows({ snapshot = { tasks = {}, people = {
    { id = "npc-2", name = "Riley", activity = "sleeping",
        needs = { hunger = 0.31, thirst = 0.42, fatigue = 0.52 },
        supply = { byKind = {
            FOOD = { phase = "ACQUIRE" },
            HYDRATION = { phase = "FAILED" },
        } } },
} } })
assert(#needs == 3, "needs tasks did not include eating, drinking, and sleeping")
local joined = needs[1].label .. " " .. needs[2].label .. " " .. needs[3].label
contains(joined, "EAT", "hunger task")
contains(joined, "DRINK", "thirst task")
contains(joined, "SLEEP", "active sleep task")

print("pnc_tasks_tab_smoke: ok")
