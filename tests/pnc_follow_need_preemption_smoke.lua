local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "server" } })

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}
local serial = 0
local record = {
    id = "npc:following", alive = true, runtime = {},
    orderSpec = { kind = "follow" },
}
PNC = {
    Const = {
        ORDER_FOLLOW = "follow",
        ORDER_CAMP = "camp",
        ORDER_GUARD = "guard",
    },
    Core = {
        Now = function() return 1000 end,
        GenerateID = function(prefix)
            serial = serial + 1
            return prefix .. ":" .. tostring(serial)
        end,
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, item in pairs(value) do output[key] = item end
            return output
        end,
    },
    Registry = {
        Get = function() return record end,
        ForEach = function() end,
    },
}
Events = { OnTick = { Add = function() end } }

local Priority = T.load("ProjectHoomans", "server",
    "PNC/Tasking/PNC_TaskPriority.lua")
local Intent = T.load("ProjectHoomans", "server",
    "PNC/Tasking/PNC_TaskIntent.lua")
local Leases = T.load("ProjectHoomans", "server",
    "PNC/Tasking/PNC_TaskLeaseService.lua")
package.preload["PNC/Tasking/PNC_TaskPriority"] = function() return Priority end
package.preload["PNC/Tasking/PNC_TaskIntent"] = function() return Intent end
package.preload["PNC/Tasking/PNC_TaskLeaseService"] = function() return Leases end
package.preload["PNC/Tasking/PNC_TaskExecutors"] = function() return {} end
package.preload[
    "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityTriggers"
] = function() return {} end

local releaseCalls, starts = 0, 0
PNC.WorkService = { Commands = { ReleaseWorker = function()
    releaseCalls = releaseCalls + 1
    return false
end } }
local Tasking = T.load("ProjectHoomans", "server", "PNC/Tasking/PNC_Tasking.lua")
Tasking.Commands.RegisterProvider("NeedTest", {
    GetCandidates = function()
        return {{
            taskId = "drink:npc:following", npcId = record.id,
            kind = "DRINK", sourceDomain = "NeedTest", sourceRef = "water",
            precedence = "NORMAL_NEED", urgency = 0.45,
            capability = "water.nearby",
        }}
    end,
    Validate = function() return true end,
    Assign = function()
        return { executionMode = "LIVE", target = { x = 2, y = 2, z = 0 } }
    end,
    Start = function()
        starts = starts + 1
        return true
    end,
    CanContinue = function() return true end,
})

local ok = Tasking.Commands.Reevaluate(record.id, "NEED_STATE_CHANGED")
T.truthy(ok, "a normal need can suspend passive follow formation")
T.equal(starts, 1, "the drink task starts while the owner is stationary")
T.equal(releaseCalls, 0,
    "follow preemption does not use the unrelated work-release path")
T.truthy(Tasking.Queries.GetLease(record.id), "the need owns a task lease")

local firstLease = Tasking.Queries.GetLease(record.id)
T.truthy(firstLease and Leases.Release(firstLease.leaseId, "test_reset"),
    "test reset released the first need lease")
record.orderSpec = { kind = "camp" }
local campOK = Tasking.Commands.Reevaluate(record.id, "CAMP_NEED_STATE_CHANGED")
T.truthy(campOK, "a normal need can suspend passive camp anchoring")
T.equal(starts, 2, "the drink task starts while the NPC is camped")
T.equal(releaseCalls, 0,
    "camp preemption does not use the unrelated work-release path")

T.finish("pnc_follow_need_preemption_smoke")
