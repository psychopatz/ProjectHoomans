-- Formation, personal-space, hazard-steering, and movement handoff for
-- live FollowOwner ticks.

PNC = PNC or {}
PNC.BehaviorCompanion = PNC.BehaviorCompanion or {}
PNC.BehaviorCompanion.Internal = PNC.BehaviorCompanion.Internal or {}

local Companion = PNC.BehaviorCompanion
local Internal = Companion.Internal
local H = Internal.FollowOwnerMovementHandoff
if type(H) ~= "table" then return Companion end

local Const = H.Const
local MovementPlan = H.MovementPlan

function H.TryHandle(record, zombie, owner, ownerDist, followState, hazard, now)
    -- A stationary owner is the formation anchor. Nearby followers keep their
    -- current safe position instead of orbiting through synthetic slots every
    -- time the player's facing direction changes.
    if followState.ownerMoving ~= true
        and ownerDist >= (
            tonumber(Const.FOLLOW_PERSONAL_SPACE_MIN) or 1.25
        )
        and ownerDist <= (
            tonumber(Const.FOLLOW_IDLE_EXIT_DISTANCE) or 3.2
        )
        and math.abs(owner:getZ() - record.z) < 1
    then
        followState.stationaryHolding = true
        return Internal.HoldAndFaceOwner(
            record,
            zombie,
            owner,
            "idle_near_owner",
            "owner_stationary_hold"
        )
    end
    followState.stationaryHolding = false
    if MovementPlan and MovementPlan.Run then
        return MovementPlan.Run(
            record,
            zombie,
            owner,
            ownerDist,
            followState,
            hazard,
            now
        )
    end
    return false
end

return Companion
