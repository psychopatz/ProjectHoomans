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

    local roamingAmbient = PNC.RoamAmbient
    if roamingAmbient and roamingAmbient.Tick
        and roamingAmbient.Tick(record, zombie, now)
    then
        return true
    end

    local roamingSeat = PNC.RoamingSeat
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
