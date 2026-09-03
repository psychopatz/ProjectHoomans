local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
})

PsychopatzCore = { RuntimeRole = { AllowsServerCode = function() return true end } }
local npc2 = { id = "npc-2", name = "Riley",
    affiliation = { communityID = "colony-1" },
    runtime = { facilityActivity = {
        capability = "sleep", phase = "WORKING", taskLeaseId = "lease",
    } } }
local npc3 = { id = "npc-3", name = "Morgan",
    affiliation = { communityID = "colony-1" },
    runtime = { facilityActivity = {
        capability = "food.dine", phase = "WORKING", taskLeaseId = "",
    } } }
local cancelledLease
local stoppedActivity
local cancelledMedical
PNC = {
    Core = { Now = function() return 70000 end },
    Registry = { Get = function(id)
        return id == "npc-2" and npc2 or id == "npc-3" and npc3 or nil
    end, ForEach = function(callback)
        callback(npc2); callback(npc3)
    end },
    TaskLeaseService = { ByID = {
        lease = { leaseId = "lease", taskId = "need:npc-2:sleep",
            npcId = "npc-2", kind = "SLEEP", sourceDomain = "needs",
            phase = "TRAVEL", startedAt = 65000, lastProgressAt = 66000 },
    }, Get = function(id) return id == "lease"
        and PNC.TaskLeaseService.ByID.lease or nil end },
    CompanionCommands = { IsOwnedByPlayer = function() return true end },
    FacilityJobs = { Stop = function(record)
        stoppedActivity = record.id; return true
    end },
    Tasking = { Commands = { CancelLease = function(id)
        cancelledLease = id; return true
    end } },
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

local medicalTask = {
    id = "medical:1", operation = "MEDICAL_CARE",
    status = "WAITING_FOR_DOCTOR", phase = "WAITING_FOR_DOCTOR",
    patientKind = "npc", patientId = "npc-3",
    communityId = "colony-1", factionId = "faction-1",
    woundParts = { "Hand_L", "ForeArm_L" }, currentWoundIndex = 1,
    priority = 50, lastProgressAt = 69000,
}
PNC.MedicalCareService = {
    TERMINAL = { COMPLETED = true, CANCELLED = true,
        FAILED = true, QUARANTINED = true },
    List = function() return { medicalTask } end,
    Get = function(id) return id == medicalTask.id and medicalTask or nil end,
    Cancel = function(id)
        cancelledMedical = id
        medicalTask.status = "CANCELLED"
        return true
    end,
}

local Requests = T.load("ProjectHoomans", "server",
    "PNC/Tasking/PNC_TaskRequestService.lua")
local rows = Requests.Queries.BuildSnapshot("colony-1", 70000)
T.equal(#rows, 4, "durable, medical, leased, and active activities share one read model")
T.equal(rows[1].requestId, "work:1", "work order remains canonical ID")
T.equal(rows[1].lifecycleState, "WORKING", "work lifecycle is normalized")
T.truthy(rows[1].stalled, "stalled is derived from meaningful progress")
T.equal(rows[2].requestId, "need:npc-2:sleep", "lease appears as transient task")
T.falsy(rows[2].durable, "transient task is not persisted as a request")
T.equal(rows[3].requestId, "activity:npc-3",
    "lease-free active activity appears as a transient task")
T.equal(rows[4].requestId, "medical:1", "medical request keeps canonical ID")
T.equal(rows[4].taskGroup, "medical", "medical request is grouped for the UI")
T.equal(rows[4].lifecycleState, "WAITING_WORKER",
    "medical lifecycle is normalized for the shared task view")
T.equal(rows[4].cancelAction, "cancel_medical",
    "unclaimed medical request uses its durable cancellation action")
T.truthy(Requests.Commands.CancelForPlayer({}, "work:1", "test"),
    "authorized cancel routes to state owner")
T.equal(cancelled, "work:1", "request adapter delegates mutation")
T.truthy(Requests.Commands.CancelTransientForPlayer({},
    "need:npc-2:sleep", "test"), "transient task cancellation is authorized")
T.equal(cancelledLease, "lease", "transient task cancellation targets its lease")
T.truthy(Requests.Commands.CancelTransientForPlayer({},
    "activity:npc-3", "test"), "lease-free activity cancellation is authorized")
T.equal(stoppedActivity, "npc-3",
    "lease-free activity cancellation stops the activity owner")
T.truthy(Requests.Commands.CancelMedicalForPlayer({}, "medical:1", "test"),
    "authorized medical cancellation routes to the medical owner")
T.equal(cancelledMedical, "medical:1",
    "medical cancellation targets the durable request")

T.finish("pnc_task_request_contract_smoke")
