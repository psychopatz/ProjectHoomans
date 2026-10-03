-- Behavior tick job dispatch provider.

PNC = PNC or {}
PNC.BehaviorSystem = PNC.BehaviorSystem or {}

local Behavior = PNC.BehaviorSystem
local H = Behavior.Internal and Behavior.Internal.TickDispatch
if type(H) ~= "table" then
    return Behavior
end

local JobSystem = H.JobSystem
local Animation = H.Animation
local Common = H.Common
local Registry = H.Registry
local Companion = H.Companion
local Hostile = H.Hostile
local ScalingDiagnostics = H.ScalingDiagnostics
local finishFollowerReconcile = H.finishFollowerReconcile

function H.Run(record, zombie, now, previousJob)
    local job
    local companionHandled
    job = JobSystem.Select(record)
    if ScalingDiagnostics then
        if previousJob == job then
            ScalingDiagnostics.Increment(
                "NPCDecisions.BehaviorSameJobReselections"
            )
        elseif previousJob ~= nil then
            ScalingDiagnostics.Increment(
                "NPCDecisions.BehaviorJobSwitches"
            )
        end
    end
    record.activeJob = job
    record.activeBehavior = job

    if Registry.Tick(record, zombie, job, now) then
        return
    end

    companionHandled = Companion.Tick(record, zombie, job)
    finishFollowerReconcile(record, job, companionHandled, now)
    if companionHandled then
        return
    end

    if Hostile.Tick(record, zombie, job) then
        return
    end

    Common.ClearCombatTarget(record, "idle")
    if zombie then
        Animation.Apply(zombie, record, "Idle")
    end
end

return Behavior
