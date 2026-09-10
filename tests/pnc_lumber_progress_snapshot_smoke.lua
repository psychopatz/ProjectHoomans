local T = require "tests/support/test"

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, item in pairs(value) do output[key] = copy(item) end
    return output
end

package.preload["PsychopatzCore/Inventory/PsychopatzInventory"] =
    function() return {} end
package.preload["PsychopatzCore/Inventory/PsychopatzInventoryConstants"] =
    function() return { TYPE_ID = 1 } end

local order = {
    id = "work:lumber", operation = "LUMBER", workerId = "npc:lumber",
    status = "WORKING", requiredWork = 1, progress = 0, payload = {},
}
local record = {
    id = "npc:lumber", runtime = {
        workOrderId = order.id,
        lumber = {
            treeKey = "4:4:0", phase = "CHOPPING",
            activityItemFullType = "Base.Axe",
            remainingWork = 65, maxWork = 100,
        },
    },
}

PNC = {
    Core = { DeepCopy = copy },
    WorkDefinitions = { STATUS = {} },
    WorkRepository = {
        Get = function(id) return id == order.id and order or nil end,
    },
    Registry = {
        Get = function(id) return id == record.id and record or nil end,
    },
    WorkService = {
        Internal = {
            terminal = function() return false end,
            copy = copy,
            workLocationState = function() return nil end,
            locationPolicy = function() return nil end,
        },
        Queries = {
            List = function() return { order } end,
        },
    },
}

local Snapshots = T.load("ProjectHoomans", "server",
    "PNC/Production/WorkService/PNC_WorkService_Snapshots.lua")
local action = Snapshots.BuildActionInformation(record)
T.equal(action.progress, 35,
    "lumber action progress comes from the tree ledger")
T.equal(action.requiredWork, 100,
    "lumber action required work uses the tree maximum")
T.equal(action.percent, 35,
    "lumber action percentage is visible while chopping")
T.equal(action.treeRemainingWork, 65,
    "lumber action exposes remaining tree work")
T.equal(action.treeKey, "4:4:0", "lumber action exposes its tree key")

local task = Snapshots.Queries.BuildTaskSnapshot()
T.equal(task[1].percent, 35,
    "task snapshot uses the same tree percentage as the nameplate")
T.equal(task[1].activityItemFullType, "Base.Axe",
    "task snapshot reports the active lumber axe")

record.runtime.lumber.remainingWork = 0
record.runtime.lumber.phase = "OUTPUT_APPROACH"
local completedTreeAction = Snapshots.BuildActionInformation(record)
T.equal(completedTreeAction.percent, 100,
    "tree remains complete while output is being delivered")

T.finish("pnc_lumber_progress_snapshot_smoke")
