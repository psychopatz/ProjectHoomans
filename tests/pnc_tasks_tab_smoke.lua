local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "client" } })

getText = function(key) return key end
getItemNameFromFullType = function(fullType)
    return fullType == "Base.SpearCrafted" and "Crafted Spear" or fullType
end

local modalOptions
package.preload["PNC/UI/Factions/PNC_FactionMemberModal"] = function()
    return { Open = function(options) modalOptions = options end }
end

local cancelledId
PNC = {
    Client = { RequestColonyAction = function(action, options)
        T.equal(action, "work_cancel", "task action")
        cancelledId = options.workOrderId
        return true
    end },
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

T.contains(rows[1].label, "barracks", "construction target")
T.contains(rows[1].label, "40%", "construction progress")
T.contains(rows[1].detail, "Peter", "assigned worker")
T.contains(rows[1].detail, "ABSTRACT", "abstract execution mode")
T.truthy(rows[1].action == "cancel_work"
    and rows[1].workOrder.id == "build-1",
    "work rows expose their cancellation action")
T.truthy(Tasks.OnRow({}, rows[1]), "cancel row opens confirmation")
T.truthy(modalOptions and modalOptions.onConfirm,
    "cancel confirmation supplies its handler")
modalOptions.onConfirm(modalOptions.context)
T.equal(cancelledId, "build-1", "confirmed row cancels selected work order")
T.contains(rows[2].label, "Crafted Spear", "craft output")
T.contains(rows[2].detail, "UNASSIGNED", "queued task assignment")

local empty = Tasks.BuildRows({ snapshot = { tasks = {} } })
T.contains(empty[1].label, "NO AVAILABLE TASKS", "empty task state")

local needs = Tasks.BuildRows({ snapshot = { tasks = {}, people = {
    { id = "npc-2", name = "Riley", activity = "sleeping",
        needs = { hunger = 0.31, thirst = 0.42, fatigue = 0.52 },
        supply = { byKind = {
            FOOD = { phase = "ACQUIRE" },
            HYDRATION = { phase = "FAILED" },
        } } },
} } })
T.equal(#needs, 3, "needs tasks include eating, drinking, and sleeping")
T.truthy(needs[1].action == nil and needs[2].action == nil
    and needs[3].action == nil, "need rows remain non-cancellable")
local joined = needs[1].label .. " " .. needs[2].label .. " " .. needs[3].label
T.contains(joined, "EAT", "hunger task")
T.contains(joined, "DRINK", "thirst task")
T.contains(joined, "SLEEP", "active sleep task")

T.finish("pnc_tasks_tab_smoke")
