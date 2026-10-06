-- Follow-owner coordinator provider.

PNC = PNC or {}
PNC.BehaviorCompanion = PNC.BehaviorCompanion or {}
PNC.BehaviorCompanion.Internal = PNC.BehaviorCompanion.Internal or {}

local Companion = PNC.BehaviorCompanion
local Internal = Companion.Internal
local H = Internal.FollowOwnerTick
if type(H) ~= "table" then
    return Companion
end

local Core = H.Core
local Const = H.Const
local Stealth = H.Stealth
local Common = H.Common
local CompanionVehicle = H.CompanionVehicle

function Internal.TickFollowOwner(record, zombie)
    local owner = Common.GetOwner(record)
    local now = Core.Now and Core.Now() or 0
    local ownerVehicle
    local ownerDist
    local followState
    local hazard
    local ownerEngaged
    record.runtime = record.runtime or {}
    record.runtime.followOrderActive = true
    if Stealth and Stealth.UpdateFollowState then
        Stealth.UpdateFollowState(record, owner)
    end
    if not owner then
        if CompanionVehicle and CompanionVehicle.IsPassenger
            and CompanionVehicle.IsPassenger(record)
            and CompanionVehicle.Tick
        then
            CompanionVehicle.Tick(record, zombie, nil)
        end
        -- Losing the owner reference is a transient MP/live-to-abstract
        -- condition, not a cancellation of the follow order. Never send an
        -- actively following colonist to its base as a side effect of one
        -- failed owner lookup; hold and retry the authoritative owner.
        Internal.SetFollowMode(record, "owner_unresolved")
        if Stealth and Stealth.Clear then
            Stealth.Clear(record, "owner_missing")
        end
        Common.ClearCombatTarget(record, "owner_missing_hold")
        record.activeBehavior = "FollowOwner:owner_unresolved"
        if zombie and Common.HaltMovement then
            Common.HaltMovement(record, zombie, "follow_owner_unresolved")
        end
        return true
    end

    local stateHandoff = Internal.FollowOwnerStateHandoff
    if stateHandoff and stateHandoff.Prepare then
        followState, ownerEngaged = stateHandoff.Prepare(
            record,
            zombie,
            owner,
            now
        )
    end
    ownerVehicle = owner.getVehicle and owner:getVehicle() or nil
    local vehicleHandoff = Internal.FollowOwnerVehicleHandoff
    if vehicleHandoff and vehicleHandoff.TryHandle
        and vehicleHandoff.TryHandle(
            record,
            zombie,
            owner,
            ownerVehicle
        )
    then
        return true
    end
    ownerDist = Core.Distance(
        record.x,
        record.y,
        owner:getX(),
        owner:getY()
    )
    if followState.ownerMoving == true
        or ownerDist >= (tonumber(Const.FOLLOW_WALK_DISTANCE) or 4)
    then
        hazard = Internal.AssessFollowHazards(record, zombie, now)
    else
        record.runtime.followHazard = record.runtime.followHazard or {}
        hazard = record.runtime.followHazard
        hazard.count = 0
        hazard.active = false
        hazard.combatCount = 0
        hazard.combatCountReady = false
        hazard.nearestDistance = nil
        hazard.expiresAt = 0
    end
    local combatHandoff = Internal.FollowOwnerCombatHandoff
    if combatHandoff and combatHandoff.TryHandle
        and combatHandoff.TryHandle(
            record,
            zombie,
            owner,
            ownerDist,
            followState,
            hazard,
            now,
            ownerEngaged,
            ownerVehicle
        )
    then
        return true
    end
    local movementHandoff = Internal.FollowOwnerMovementHandoff
    if movementHandoff and movementHandoff.TryHandle
        and movementHandoff.TryHandle(
            record,
            zombie,
            owner,
            ownerDist,
            followState,
            hazard,
            now
        )
    then
        return true
    end
    return true
end

return Companion
