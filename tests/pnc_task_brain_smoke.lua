local T = require "tests/support/test"
T.addPackagePaths()

local function copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local output = {}
    seen[value] = output
    for key, entry in pairs(value) do
        output[copy(key, seen)] = copy(entry, seen)
    end
    return output
end

local now = 1000
local lease = {
    leaseId = "lease-1", taskId = "need_facility:sleep:npc-1",
    npcId = "npc-1", sourceDomain = "NeedFacility", sourceRef = "sleep",
    kind = "SLEEP", precedence = "NORMAL_NEED", urgency = 0.7,
    phase = "WORKING", revision = 4,
}

PNC = {
    Core = { Now = function() return now end, DeepCopy = copy },
    TaskRequestDefinitions = {
        NON_INTERRUPTIBLE_PHASE = { ATOMIC_COMMIT = true, COMPLETING = true },
    },
    Tasking = {
        Queries = {},
        Internal = { Copy = copy },
        Diagnostics = {
            byNPC = {
                ["npc-1"] = {
                    generatedAt = 900, recordRevision = 3,
                    lastCause = "NPC_NEEDS_CHANGED",
                    lastReason = "CURRENT_TASK_CONTINUES",
                    candidates = {
                        { taskId = "work:1", npcId = "npc-1",
                            kind = "CONSTRUCT", sourceDomain = "work",
                            sourceRef = "work:1", precedence = "HIGH_WORK",
                            urgency = 0.8, workPriority = 1, revision = 9 },
                        { taskId = "need_facility:eat:npc-1", npcId = "npc-1",
                            kind = "EAT", sourceDomain = "NeedFacility",
                            sourceRef = "eat", precedence = "NORMAL_NEED",
                            urgency = 0.5, revision = 1 },
                    },
                    providerFailures = {},
                },
            },
        },
    },
    TaskLeaseService = {
        ForNPC = function(npcId)
            return tostring(npcId) == "npc-1" and lease or nil
        end,
    },
    Registry = {
        Get = function(npcId)
            return tostring(npcId) == "npc-1"
                and { id = "npc-1", recordRevision = 3,
                    affiliation = { communityID = "c1" } } or nil
        end,
    },
    WorkService = {
        Queries = {
            Get = function(id)
                return tostring(id) == "work:1"
                    and { id = "work:1", revision = 9,
                        colonyId = "c1", factionId = "f1" } or nil
            end,
        },
    },
}

T.load("ProjectHoomans", "server",
    "PNC/Tasking/Tasking/PNC_Tasking_Queries.lua")

local brain = PNC.Tasking.Queries.BuildBrain("npc-1")
T.equal(brain.freshness, "FRESH", "fresh cached brain")
T.equal(brain.decision, "CURRENT_TASK_CONTINUES", "arbiter decision")
T.equal(brain.winner.taskId, "work:1", "rank one candidate")
T.equal(brain.winner.rank, 1, "candidate rank is explicit")
T.equal(brain.winner.cancelAction, "work_cancel",
    "durable work candidate uses work cancellation")
T.equal(brain.winner.cancelRevision, 9,
    "work cancellation carries source revision")
T.equal(brain.current.cancelAction, "task_cancel",
    "active transient lease uses lease cancellation")
T.equal(brain.current.cancelRevision, 4,
    "transient cancellation carries lease revision")
T.falsy(brain.candidates[2].cancelAction,
    "derived need candidate is not presented as a queue cancellation")
T.equal(brain.candidateCount, 2, "full candidate count is preserved")

local limited = PNC.Tasking.Queries.BuildBrain("npc-1", 1)
T.equal(#limited.candidates, 1, "brain payload is bounded")
T.truthy(limited.hasMore, "bounded brain reports omitted candidates")

local cancelledOrder
local cancelledLease
local cancelledMedical
local reevaluatedNPC
PNC.ProductionContext = {
    ForPlayer = function()
        return { colony = { id = "c1" }, faction = { id = "f1" } }
    end,
}
PNC.WorkService.Commands = {
    Cancel = function(id)
        cancelledOrder = id
        return true, "CANCELLED"
    end,
}
PNC.MedicalCareService = {
    TERMINAL = {},
    Get = function(id)
        return tostring(id) == "medical:1"
            and { id = "medical:1", revision = 7, actorId = "npc-1",
                communityId = "c1", factionId = "f1" }
            or nil
    end,
    Cancel = function(id)
        cancelledMedical = id
        return true, "CANCELLED"
    end,
}
PNC.CompanionCommands = {
    IsOwnedByPlayer = function() return true end,
}
PNC.Tasking.Commands = {
    CancelLease = function(id)
        cancelledLease = id
        return true, "CANCELLING"
    end,
    ReevaluateAfterCancellation = function(npcId)
        reevaluatedNPC = npcId
        return true, "TASK_REEVALUATION_REQUESTED"
    end,
}
PNC.TaskLeaseService.ByID = { [lease.leaseId] = lease }
T.load("ProjectHoomans", "server", "PNC/Tasking/PNC_TaskRequestService.lua")
local requestService = PNC.TaskRequestService
local staleOK, staleReason = requestService.Commands.CancelForPlayer(
    {}, "work:1", "player_cancelled", {
        taskId = "work:1", sourceRef = "work:1", expectedRevision = 8,
    })
T.falsy(staleOK, "stale work cancellation is rejected")
T.equal(staleReason, "TASK_STALE", "stale work reason")
local workOK = requestService.Commands.CancelForPlayer({}, "work:1",
    "player_cancelled", {
        taskId = "work:1", sourceRef = "work:1", expectedRevision = 9,
    })
T.truthy(workOK, "current work cancellation is accepted")
T.equal(cancelledOrder, "work:1", "work cancellation uses canonical order")
local medicalOK = requestService.Commands.CancelMedicalForPlayer({},
    "medical:1", "player_cancelled", {
        sourceRef = "medical:1", npcID = "npc-1", expectedRevision = 7,
    })
T.truthy(medicalOK, "medical cancellation is accepted")
T.equal(cancelledMedical, "medical:1",
    "medical cancellation uses canonical request")
local transientOK = requestService.Commands.CancelTransientForPlayer({},
    lease.taskId, "player_cancelled", {
        npcID = "npc-1", taskId = lease.taskId,
        sourceDomain = "NeedFacility", sourceRef = "sleep",
        expectedRevision = 4,
    })
T.truthy(transientOK, "current lease cancellation is accepted")
T.equal(cancelledLease, "lease-1", "lease cancellation uses lease identity")
T.equal(reevaluatedNPC, "npc-1",
    "transient cancellation immediately wakes the selected NPC")

getText = function(key) return key end
local modalOptions
package.preload["PNC/UI/Factions/PNC_FactionMemberModal"] = function()
    return { Open = function(options) modalOptions = options end }
end
local sentAction
local sentOptions
PNC.Client = {
    RequestColonyAction = function(action, options)
        sentAction, sentOptions = action, options
        return true
    end,
}
local BrainPresentation = require(
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_TaskBrainPresentation"
)
local person = {
    id = "npc-1", name = "Riley", role = "companion", taskBrain = brain,
}
local window = { pendingTaskBrainCancellations = {} }
local rows = BrainPresentation.BuildRows(person, window)
local workRow
for _, row in ipairs(rows) do
    if row.task and row.task.taskId == "work:1" then workRow = row end
end
T.truthy(workRow and workRow.action == "work_cancel",
    "brain row exposes durable cancellation")
T.truthy(BrainPresentation.OnRow(window, workRow),
    "brain cancellation opens confirmation")
modalOptions.onConfirm(modalOptions.context)
T.equal(sentAction, "work_cancel", "brain routes through work authority")
T.equal(sentOptions.workOrderId, "work:1", "brain sends canonical order ID")
T.equal(sentOptions.npcID, "npc-1", "brain sends selected NPC identity")
T.equal(sentOptions.expectedRevision, 9,
    "brain sends expected source revision")

local pendingRows = BrainPresentation.BuildRows(person, window)
local pendingWorkRow
for _, row in ipairs(pendingRows) do
    if row.task and row.task.taskId == "work:1" then
        pendingWorkRow = row
    end
end
T.falsy(pendingWorkRow and pendingWorkRow.action,
    "submitted cancellation is not offered twice while pending")

window.snapshot = { actionResult = { action = "work_cancel",
    requestId = "work:1", ok = false, reason = "TASK_STALE" } }
local failedRows = BrainPresentation.BuildRows(person, window)
local retriedWorkRow
for _, row in ipairs(failedRows) do
    if row.task and row.task.taskId == "work:1" then
        retriedWorkRow = row
    end
end
T.equal(retriedWorkRow and retriedWorkRow.action, "work_cancel",
    "failed cancellation clears the pending UI state")

T.finish("pnc_task_brain_smoke")
