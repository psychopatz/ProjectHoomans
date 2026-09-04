local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "shared" },
})

getText = function(key) return key end

local now = 1000
local modalOptions
local sentAction
local sentOptions

PNC = {
    Core = { Now = function() return now end },
    Client = {
        RequestColonyAction = function(action, options)
            sentAction, sentOptions = action, options
            return true
        end,
    },
}

package.preload["PNC/UI/Factions/PNC_FactionMemberModal"] = function()
    return { Open = function(options) modalOptions = options end }
end

local Task = T.load("ProjectHoomans", "client",
    "PNC/UI/Colonist/PNC_ColonistTask.lua")

local person = {
    id = "npc-1",
    name = "Riley",
    role = "colonist",
    taskBrain = {
        freshness = "FRESH",
        decision = "CURRENT_TASK_CONTINUES",
        lastCause = "NPC_NEEDS_CHANGED",
        eventType = "NEEDS_CHANGED",
        current = nil,
        candidates = {
            {
                taskId = "work:corpse-1",
                npcId = "npc-1",
                kind = "CORPSE_HAUL",
                operation = "CORPSE_HAUL",
                sourceDomain = "work",
                sourceRef = "work:corpse-1",
                precedence = "HIGH_WORK",
                workPriority = 1,
                urgency = 0.90,
                cancelAction = "work_cancel",
                cancelRequestId = "work:corpse-1",
                cancellable = true,
                cancelRevision = 4,
            },
            {
                taskId = "need:eat:npc-1",
                npcId = "npc-1",
                kind = "EAT",
                operation = "EAT",
                sourceDomain = "NeedFacility",
                sourceRef = "eat",
                precedence = "NORMAL_NEED",
                urgency = 0.40,
                cancellable = false,
            },
        },
        candidateCount = 2,
        hasMore = false,
        providerFailures = {},
        providerDiagnostics = {
            work = {
                totalOrders = 3, assignableOrders = 2,
                eligibleOrders = 0,
                statusCounts = { WAITING_FOR_WORKER = 2, COMPLETED = 1 },
                rejectionCounts = { WORKER_NOT_AT_HOME = 2 },
                samples = {
                    { orderId = "work:corpse-2", operation = "CORPSE_HAUL",
                        status = "WAITING_FOR_WORKER",
                        reason = "WORKER_NOT_AT_HOME" },
                },
            },
        },
    },
}

local window = {
    pendingTaskBrainCancellations = {},
    snapshot = {},
}
local rows = Task.BuildRows({ selectedPerson = person, window = window })
local corpseRow
local needRow
for _, row in ipairs(rows) do
    if row.task and row.task.taskId == "work:corpse-1" then
        corpseRow = row
    elseif row.task and row.task.taskId == "need:eat:npc-1" then
        needRow = row
    end
end

T.truthy(corpseRow, "target task tab omitted the corpse-haul candidate")
T.contains(corpseRow.label, "RANK 1",
    "target task tab did not expose the brain rank")
T.contains(corpseRow.label, "CORPSE HAUL",
    "target task tab did not expose the task operation")
T.contains(corpseRow.detail, "WORK PRIORITY 1",
    "target task tab did not expose work priority separately")
T.equal(corpseRow.action, "work_cancel",
    "durable work task did not expose cancellation")
T.truthy(needRow, "target task tab omitted the derived needs candidate")
T.falsy(needRow.action,
    "derived needs candidate was incorrectly presented as cancellable")
T.contains(needRow.detail, "DERIVED / NOT QUEUED",
    "derived candidate did not explain why it cannot be cancelled")

local providerRow
local rejectionRow
for _, row in ipairs(rows) do
    if row.key == "task_brain_provider:work" then providerRow = row end
    if row.key == "task_brain_provider_rejection:work:WORKER_NOT_AT_HOME" then
        rejectionRow = row
    end
end
T.truthy(providerRow, "task tab omitted work-provider diagnostics")
T.contains(providerRow.detail, "QUEUED/WAITING 2",
    "provider diagnostics omitted the assignable queue count")
T.contains(providerRow.detail, "ELIGIBLE 0",
    "provider diagnostics omitted the eligible count")
T.truthy(rejectionRow, "task tab omitted the worker gate reason")
T.contains(rejectionRow.label, "WORKER NOT AT HOME",
    "task tab did not humanize the worker gate reason")
local sampleRow
for _, row in ipairs(rows) do
    if row.key == "task_brain_provider_sample:work:work:corpse-2" then
        sampleRow = row
    end
end
T.truthy(sampleRow, "task tab omitted the blocked order sample")
T.contains(sampleRow.label, "CORPSE HAUL",
    "task tab did not identify the blocked operation")

T.truthy(Task.OnRow(window, corpseRow),
    "target task tab did not open cancellation confirmation")
modalOptions.onConfirm(modalOptions.context)
T.equal(sentAction, "work_cancel",
    "target task tab used the wrong cancellation authority")
T.equal(sentOptions.workOrderId, "work:corpse-1",
    "target task tab omitted the canonical work order ID")
T.equal(sentOptions.npcID, "npc-1",
    "target task tab omitted the selected NPC identity")
T.equal(sentOptions.taskBrainNpcID, "npc-1",
    "target task tab did not scope the post-action brain snapshot")
T.equal(sentOptions.expectedRevision, 4,
    "target task tab omitted the source revision")

local pendingRows = Task.BuildRows({ selectedPerson = person, window = window })
local pendingCorpse
for _, row in ipairs(pendingRows) do
    if row.task and row.task.taskId == "work:corpse-1" then
        pendingCorpse = row
    end
end
T.falsy(pendingCorpse.action,
    "target task tab offered a second cancellation while pending")
T.equal(pendingCorpse.actionLabel, "CANCELLING...",
    "target task tab did not show the pending cancellation state")

window.snapshot = { actionResult = {
    action = "work_cancel", requestId = "work:corpse-1",
    ok = false, reason = "TASK_STALE",
} }
local failedRows = Task.BuildRows({ selectedPerson = person, window = window })
local retriedCorpse
for _, row in ipairs(failedRows) do
    if row.task and row.task.taskId == "work:corpse-1" then
        retriedCorpse = row
    end
end
T.equal(retriedCorpse.action, "work_cancel",
    "failed cancellation did not restore the cancel action")

T.finish("pnc_colonist_task_smoke")
