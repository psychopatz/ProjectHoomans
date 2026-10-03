-- Server-authoritative task pump composition root.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Tasking = PNC.Tasking
local Priority = PNC.TaskPriority
local Leases = PNC.TaskLeaseService
local ScalingDiagnostics = PNC.PerformanceScalingDiagnostics
local H = Tasking.Internal
local Events = Tasking.Events
local Inbox = Tasking.Inbox

require "PNC/Tasking/Tasking/PNC_Tasking_Pump_Context"
require "PNC/Tasking/Tasking/PNC_Tasking_Pump_Reconciliation"
require "PNC/Tasking/Tasking/PNC_Tasking_Pump_Evaluation"
require "PNC/Tasking/Tasking/PNC_Tasking_Pump_Execution"

function H.Pump(at, budget)
        at = tonumber(at) or PNC.Core.Now()
        if at < Tasking.NextPumpAt then return 0 end
        Tasking.NextPumpAt = at + Tasking.PUMP_INTERVAL_MS
    local pumpStartedAt = H.PumpClockNow(at)
        local timerName
        local timerStart
        if ScalingDiagnostics then
            timerName, timerStart = ScalingDiagnostics.BeginTiming(
                "Tasking.Pump", at)
            ScalingDiagnostics.Increment("Tasking.PumpCalls")
            ScalingDiagnostics.SetGauge("Tasking.ActiveLeases", #Leases.Active)
            ScalingDiagnostics.SetGauge("Tasking.EventInboxSize", Inbox.Count())
        end
        H.PumpReconcileOrphanedActivities(at)
        if Tasking.Initialized ~= true then
            Tasking.Initialized = true
            if PNC.Registry and PNC.Registry.ForEach then
                PNC.Registry.ForEach(function(record)
                    if record and record.alive ~= false then
                        Events.Emit("TASKING_INITIALIZED", {
                            record = record, source = "Tasking.Initialization",
                        })
                    end
                end)
            end
        end
    local processed = H.PumpReevaluate(at, pumpStartedAt, budget)
    local executorSteps = H.PumpExecutors(at, pumpStartedAt)
        local actionPlans = PNC.Semantics
            and PNC.Semantics.ActionPlanService or nil
        if actionPlans and type(actionPlans.Pump) == "function" then
            H.SafeCall("semantic_action_plan_pump", actionPlans.Pump, {
                domain = "semantic_action_plan",
            }, at)
        end
        if ScalingDiagnostics then
            ScalingDiagnostics.Increment("Tasking.ReevaluationsProcessed", processed)
            ScalingDiagnostics.Increment("Tasking.ExecutorSteps", executorSteps)
            ScalingDiagnostics.SetGauge("Tasking.ActiveLeases", #Leases.Active)
            ScalingDiagnostics.SetGauge("Tasking.EventInboxSize", Inbox.Count())
        end
        if timerName then ScalingDiagnostics.EndTiming(timerName, timerStart) end
        return processed
end

function Tasking.Commands.Pump(at, budget)
    return H.Pump(at, budget)
end

return Tasking
