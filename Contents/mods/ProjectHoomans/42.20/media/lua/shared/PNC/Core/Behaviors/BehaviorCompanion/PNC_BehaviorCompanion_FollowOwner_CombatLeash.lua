-- Owner-leash threat scanning for live FollowOwner ticks.

PNC = PNC or {}
PNC.BehaviorCompanion = PNC.BehaviorCompanion or {}
PNC.BehaviorCompanion.Internal = PNC.BehaviorCompanion.Internal or {}

local Companion = PNC.BehaviorCompanion
local H = Companion.Internal.FollowOwnerCombatLeash
if type(H) ~= "table" then
    return Companion
end

local Const = H.Const
local ShouldScanFollowThreat = H.ShouldScanFollowThreat
local TryRespondToThreat = H.TryRespondToThreat
local SetFollowMode = H.SetFollowMode

function H.TryHandle(
    record,
    zombie,
    owner,
    ownerDist,
    followState,
    now,
    ownerEngaged,
    ownerVehicle,
    prioritizeOwner
)
    if ownerVehicle
        or prioritizeOwner
        or not ShouldScanFollowThreat(
            record,
            now,
            followState.ownerMoving == true
                or ownerDist >= (tonumber(Const.FOLLOW_WALK_DISTANCE) or 4)
        )
    then
        return false
    end
    if TryRespondToThreat(
        record,
        zombie,
        {
            x = owner:getX(),
            y = owner:getY(),
            radius = tonumber(Const.FOLLOW_COMBAT_LEASH_DISTANCE) or 5.5,
        },
        { ownerEngaged = ownerEngaged }
    )
    then
        SetFollowMode(record, "combat")
        return true
    end
    return false
end

return Companion
