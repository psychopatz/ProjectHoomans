local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
})

PsychopatzCore = { RuntimeRole = { AllowsServerCode = function() return true end } }
PNC = {
    Core = { Now = function() return 70000 end },
    Registry = { Get = function(id)
        return id == "npc-2" and { id = id, name = "Riley",
            communityId = "colony-1" } or nil
    end },
    TaskLeaseService = { ByID = {
        lease = { leaseId = "lease", taskId = "need:npc-2:sleep",
            npcId = "npc-2", kind = "SLEEP", sourceDomain = "needs",
            phase = "TRAVEL", startedAt = 65000, lastProgressAt = 66000 },
    } },
}
T.load("ProjectHoomans", "shared",
    "PNC/Core/Production/PNC_WorkDefinitions.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Tasking/PNC_TaskRequestDefinitions.lua")

local cancelled
PNC.WorkService = {
    Queries = {
        Get = function(id) return id == "work:1" and {
            id = id, colonyId = "colony-1", factionId = "faction-1",
        } or nil end,
        BuildTaskSnapshot = function()
            return {{ id = "work:1", status = "WORKING", operation = "CRAFT",
                createdAt = 1000, lastProgressAt = 2000 }}
        end,
    },
    Commands = {
        Cancel = function(id) cancelled = id; return true end,
        Pause = function() return true end,
        Resume = function() return true end,
    },
}
PNC.ProductionContext = { ForPlayer = function()
    return { colony = { id = "colony-1" }, faction = { id = "faction-1" } }
end }

local Requests = T.load("ProjectHoomans", "server",
    "PNC/Tasking/PNC_TaskRequestService.lua")
local rows = Requests.Queries.BuildSnapshot("colony-1", 70000)
T.equal(#rows, 2, "durable and transient work share one read model")
T.equal(rows[1].requestId, "work:1", "work order remains canonical ID")
T.equal(rows[1].lifecycleState, "WORKING", "work lifecycle is normalized")
T.truthy(rows[1].stalled, "stalled is derived from meaningful progress")
T.equal(rows[2].requestId, "need:npc-2:sleep", "lease appears as transient task")
T.falsy(rows[2].durable, "transient task is not persisted as a request")
T.truthy(Requests.Commands.CancelForPlayer({}, "work:1", "test"),
    "authorized cancel routes to state owner")
T.equal(cancelled, "work:1", "request adapter delegates mutation")

T.finish("pnc_task_request_contract_smoke")
