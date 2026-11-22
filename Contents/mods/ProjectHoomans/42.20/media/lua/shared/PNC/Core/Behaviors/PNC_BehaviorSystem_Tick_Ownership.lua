-- Ordered live-behavior ownership gates used before ordinary dispatch.

PNC = PNC or {}
PNC.BehaviorSystem = PNC.BehaviorSystem or {}

local Behavior = PNC.BehaviorSystem
local H = Behavior.Internal and Behavior.Internal.TickOwnership
if type(H) ~= "table" then
    return Behavior
end

local LiveBodyControl = H.LiveBodyControl
local Combat = H.Combat
local ThreatGuard = H.ThreatGuard
local AnimationScenes = H.AnimationScenes
local Treatment = H.Treatment
local puppetOperaOwnsBehavior = H.puppetOperaOwnsBehavior

function H.Run(record, zombie, now)
    if LiveBodyControl and LiveBodyControl.TickGroundedRecovery
        and LiveBodyControl.TickGroundedRecovery(record, zombie, now)
    then
        return true
    end

    if Combat and Combat.TickCommittedAction
        and Combat.TickCommittedAction(record, zombie)
    then
        return true
    end

    if ThreatGuard and ThreatGuard.Tick
        and ThreatGuard.Tick(record, zombie, now)
    then
        return true
    end

    if AnimationScenes and AnimationScenes.InterruptForSafety then
        AnimationScenes.InterruptForSafety(
            record,
            zombie,
            now
        )
    end

    if puppetOperaOwnsBehavior(record) then
        return true
    end

    local leases = PNC.TaskLeaseService
    local runtime = record and record.runtime or nil
    local executors = PNC.AutonomyExecutors or {}
    local roamingAmbient = executors.RoamAmbient
    local ambientState = runtime and runtime.roamAmbient or nil
    if ambientState and ambientState.taskLeaseId ~= nil then
        local activeLease = leases and leases.Get
            and leases.Get(ambientState.taskLeaseId) or nil
        if not activeLease then
            if roamingAmbient and roamingAmbient.Stop then
                roamingAmbient.Stop(
                    record, zombie, "task_lease_released", "movement")
            else
                runtime.roamAmbient = nil
            end
        else
            return true
        end
    end

    if roamingAmbient and roamingAmbient.Tick
        and roamingAmbient.Tick(record, zombie, now)
    then
        return true
    end

    local roamingSeat = executors.RoamingSeat
    local seatState = runtime and runtime.roamingSeat or nil
    if seatState and seatState.taskLeaseId ~= nil then
        local activeLease = leases and leases.Get
            and leases.Get(seatState.taskLeaseId) or nil
        if not activeLease then
            if roamingSeat and roamingSeat.Stop then
                roamingSeat.Stop(record, zombie, "task_lease_released")
            else
                runtime.roamingSeat = nil
            end
        else
            return true
        end
    end

    if roamingSeat and roamingSeat.Tick
        and roamingSeat.Tick(record, zombie, now)
    then
        return true
    end

    if AnimationScenes and AnimationScenes.Tick
        and AnimationScenes.Tick(record, zombie, now)
    then
        return true
    end

    if record.runtime and record.runtime.medicalCare then
        return true
    end

    if Treatment and Treatment.Tick and Treatment.Tick(record, zombie, now) then
        return true
    end

    return false
end

return Behavior
