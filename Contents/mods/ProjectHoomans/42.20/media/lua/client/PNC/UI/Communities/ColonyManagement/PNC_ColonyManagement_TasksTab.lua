-- Stable public entry point for the colony task queue UI.
-- Keep callers on this path while presentation and controls evolve separately.
local Queue = require
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_TaskQueue"

local Tasks = {}

Tasks.Create = Queue.Create
Tasks.Apply = Queue.Apply
Tasks.AfterRows = Queue.AfterRows
Tasks.BuildRows = Queue.BuildRows
Tasks.OnRow = Queue.OnRow

return Tasks
