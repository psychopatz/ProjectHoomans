-- Early behavior-tick ownership and lifecycle gates.

PNC = PNC or {}
PNC.BehaviorSystem = PNC.BehaviorSystem or {}

local Behavior = PNC.BehaviorSystem
local H = Behavior.Internal and Behavior.Internal.TickPreflight
if type(H) ~= "table" then
    return Behavior
end

local Animation = H.Animation
local Common = H.Common
local OrderSystem = H.OrderSystem
local Incapacitated = H.Incapacitated
local Companion = H.Companion
local AnimationScenes = H.AnimationScenes
local tickPendingSleepWake = H.tickPendingSleepWake
local puppetOperaOwnsBehavior = H.puppetOperaOwnsBehavior
local puppetOperaSafetyBoundary = H.puppetOperaSafetyBoundary
local clearStaleFacilityState = H.clearStaleFacilityState
local isAbstractFollowRecord = H.isAbstractFollowRecord

function H.Run(record, zombie, now)
    if record.alive == false then
        if AnimationScenes and AnimationScenes.Stop then
            AnimationScenes.Stop(record, zombie, "npc_dead")
        end
        record.activeJob = "Dead"
        record.activeBehavior = "Dead"
        Common.ClearCombatTarget(record, "dead")
        if zombie then
            Animation.Apply(zombie, record, "Idle")
        end
        return true
    end

    -- Sleep teardown owns the actor until native bump release, valid exit
    -- placement, surface cleanup, and reservation release have completed.
    if tickPendingSleepWake(record, zombie) then
        return true
    end

    -- Puppet safety boundaries deliberately fall through so combat, vehicles,
    -- traversal, and grounded recovery can abort the scene and take control.
    if puppetOperaOwnsBehavior(record)
        and not puppetOperaSafetyBoundary(record, zombie, now)
    then
        return true
    end

    if OrderSystem and OrderSystem.RecoverStalled
        and OrderSystem.RecoverStalled(record, zombie, now)
    then
        return true
    end
    clearStaleFacilityState(record, zombie)

    if record.health and record.health.state == "incapacitated" then
        if AnimationScenes and AnimationScenes.Stop then
            AnimationScenes.Stop(record, zombie, "npc_incapacitated")
        end
        Incapacitated.Tick(record, zombie)
        return true
    end

    if isAbstractFollowRecord(record)
        and Companion
        and Companion.Internal
        and Companion.Internal.TickAbstractFollowOwner
    then
        Companion.Internal.TickAbstractFollowOwner(record, now)
        return true
    end
    return false
end

return Behavior
