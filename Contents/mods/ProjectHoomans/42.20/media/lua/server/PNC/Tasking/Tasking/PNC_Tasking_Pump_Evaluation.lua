-- Bounded event inbox reevaluation for the task pump.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Tasking = PNC.Tasking
local ScalingDiagnostics = PNC.PerformanceScalingDiagnostics
local H = Tasking.Internal
local Events = Tasking.Events
local Inbox = Tasking.Inbox
local budgetExhausted = H.PumpBudgetExhausted

local function reevaluate(at, pumpStartedAt, budget)
    local processed = 0
        local reevaluationTimerName
        local reevaluationTimerStart
        if ScalingDiagnostics then
            reevaluationTimerName, reevaluationTimerStart =
                ScalingDiagnostics.BeginTiming("Tasking.Reevaluate", at)
        end
        local maximum = math.max(1, math.floor(tonumber(budget)
            or Tasking.MAX_REEVALUATIONS_PER_PUMP))
        while processed < maximum and Inbox.Count() > 0 do
            local entry = Inbox.Pop()
            if entry then
                Tasking.Diagnostics.counters.eventProcesses =
                    Tasking.Diagnostics.counters.eventProcesses + 1
                local event = entry.latestEvent
                if event then event.causes = Inbox.Causes(entry) end
                local ok, result, reason = H.SafeCall(
                    "task_reevaluate", Tasking.Commands.Reevaluate, {
                        npcId = entry.npcId, eventId = entry.latestEventId,
                        domain = entry.latestEvent
                            and entry.latestEvent.source or nil,
                    }, entry.npcId, entry.cause, event)
                if not ok then
                    Events.Emit("TASK_REEVALUATION_FAILED", {
                        npcId = entry.npcId, source = "Tasking.Pump",
                        entityId = entry.latestEventId,
                        payload = { error = reason, causes = Inbox.Causes(entry) },
                    })
                elseif result == false and reason == "TASK_CLEANUP_FAILED" then
                    Events.Emit("TASK_REEVALUATION_RETRY", {
                        npcId = entry.npcId, source = "Tasking.Pump",
                        entityId = entry.latestEventId,
                        payload = { reason = reason },
                    })
                end
                processed = processed + 1
            end
            if budgetExhausted(pumpStartedAt) then break end
        end
        if reevaluationTimerName then
            ScalingDiagnostics.EndTiming(
                reevaluationTimerName, reevaluationTimerStart)
        end
    return processed
end

H.PumpReevaluate = reevaluate

