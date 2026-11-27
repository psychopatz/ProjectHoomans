-- Ordered live-behavior ownership gates used before ordinary dispatch.

PNC = PNC or {}
PNC.BehaviorSystem = PNC.BehaviorSystem or {}

local Behavior = PNC.BehaviorSystem
local H = Behavior.Internal and Behavior.Internal.TickOwnership
if type(H) ~= "table" then
    return Behavior
end

local LiveBodyControl = H.LiveBodyControl
local FireSafety = H.FireSafety
local Suicide = H.Suicide
local Combat = H.Combat
local ThreatGuard = H.ThreatGuard
local AnimationScenes = H.AnimationScenes
local Treatment = H.Treatment
local choreographyOwnsBehavior = H.choreographyOwnsBehavior

local function holdForIncomingMedicalCare(record, now)
    local runtime = record and record.runtime or nil
    local medicId = runtime and runtime.receivingMedicalCareBy or nil
    if medicId == nil then return false end
    local untilAt = tonumber(runtime.receivingMedicalCareUntil) or 0
    local active = false
    if untilAt == 0 or now <= untilAt then
        local registry = PNC.Registry
        local medic = registry and registry.Get and registry.Get(medicId) or nil
        local mState = medic and medic.alive ~= false
            and medic.runtime and medic.runtime.medicalCare or nil
        if mState and mState.phase == "treating"
            and tostring(mState.patientId or "") == tostring(record.id or "")
        then
            active = true
        end
    end
    if not active then
        runtime.receivingMedicalCareBy = nil
        runtime.receivingMedicalCareTaskId = nil
        runtime.receivingMedicalCareUntil = nil
        return false
    end
    return true
end

function H.Run(record, zombie, now)
    -- If an NPC is in the fatal suicide ragdoll-settle phase, let BehaviorSuicide
    -- own the body until ragdoll physics finishes instead of letting grounded
    -- recovery stand them back up.
    if record and record.runtime and record.runtime.suicideState
        and record.runtime.suicideState.phase == "ragdoll_settle"
        and Suicide and Suicide.Tick
        and Suicide.Tick(record, zombie, now)
    then
        return true
    end

    if LiveBodyControl and LiveBodyControl.TickGroundedRecovery
        and LiveBodyControl.TickGroundedRecovery(record, zombie, now)
    then
        return true
    end

    if FireSafety and FireSafety.Tick
        and FireSafety.Tick(record, zombie, now)
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

    if choreographyOwnsBehavior(record) then
        return true
    end

    if holdForIncomingMedicalCare(record, now) then
        return true
    end

    if Suicide and Suicide.Tick
        and Suicide.Tick(record, zombie, now)
    then
        return true
    end

    local scriptRunner = PNC.ConvoEngine and PNC.ConvoEngine.BehaviorScriptRunner or nil
    if scriptRunner then
        local tickFn = scriptRunner.Tick or scriptRunner.Reconcile
        if type(tickFn) == "function" and tickFn(record, zombie, now) then
            return true
        end
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
            if runtime.animationScene ~= nil
                and AnimationScenes and AnimationScenes.Tick
            then
                AnimationScenes.Tick(record, zombie, now)
            end
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
            if runtime.animationScene ~= nil
                and AnimationScenes and AnimationScenes.Tick
            then
                AnimationScenes.Tick(record, zombie, now)
            end
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

    local behaviorLoot = PNC.BehaviorLoot
    if behaviorLoot and type(behaviorLoot.Tick) == "function" then
        local leader = nil
        local ownerPlayer = nil
        local isFollowing = type(record.orderSpec) == "table"
            and tostring(record.orderSpec.kind or "") == "follow"
        if isFollowing and type(getSpecificPlayer) == "function" then
            local okP, p = pcall(getSpecificPlayer, 0)
            if okP and p then
                ownerPlayer = p
                if type(p.getX) == "function" and type(p.getY) == "function" then
                    leader = { x = p:getX(), y = p:getY() }
                end
            end
        elseif record.recruited == true and type(getSpecificPlayer) == "function" then
            local okP, p = pcall(getSpecificPlayer, 0)
            if okP and p then ownerPlayer = p end
        end
        local activeLoot = behaviorLoot.Tick(record, now, {
            leader = leader,
            ownerPlayer = ownerPlayer,
            maxLeashDist = 8,
        })
        if activeLoot then
            return true
        end
    end

    return false
end

return Behavior
