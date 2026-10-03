-- Combat and threat ownership handoff for live FollowOwner ticks.
-- Keep retreat, urgent threat response, and owner-leash threat scanning in
-- one boundary so formation movement cannot replace an active combat lease.
PNC = PNC or {}
PNC.BehaviorCompanion = PNC.BehaviorCompanion or {}
PNC.BehaviorCompanion.Internal = PNC.BehaviorCompanion.Internal or {}

local Companion = PNC.BehaviorCompanion
local Internal = Companion.Internal
local H = Internal.FollowOwnerCombatHandoff
if type(H) ~= "table" then return Companion end

local Const = H.Const
local RetreatHandoff = H.RetreatHandoff
local HordeHandoff = H.HordeHandoff
local LeashHandoff = H.LeashHandoff

function H.TryHandle(
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
    local hordeCount = tonumber(hazard and hazard.count) or 0
    local prioritizeOwner
    local retreatState
    local retreatHandled
    local hordeHandled
    local leashHandled

    -- Combat retreat owns movement once it has started. The provider keeps
    -- the retreat lease ahead of formation and horde-steering movement.
    if RetreatHandoff and RetreatHandoff.TryHandle then
        retreatHandled, retreatState = RetreatHandoff.TryHandle(
            record,
            zombie,
            now
        )
        if retreatHandled then
            return true
        end
    end
    prioritizeOwner = ownerDist >= (
            tonumber(Const.FOLLOW_COMBAT_LEASH_DISTANCE) or 5.5
        )
        or (
            followState.ownerMoving == true
            and hordeCount
                >= (tonumber(Const.FOLLOW_HORDE_AVOID_COUNT) or 3)
        )
    -- Damage memory and the zombie-aggro bridge are cheap urgent signals.
    -- They bypass the owner leash so a separated follower never ignores an
    -- attacker just because it was already trying to catch up.
    if record.runtime.recentThreat
        or record.runtime.zombieAttacker
        or record.runtime.target
            and record.runtime.target.immediateSelfDefense == true
    then
        if Internal.TryRespondToImmediateThreat(record, zombie) then
            Internal.SetFollowMode(record, "combat_self_defense")
            return true
        end
    end
    if HordeHandoff and HordeHandoff.TryHandle then
        hordeHandled = HordeHandoff.TryHandle(
            record,
            zombie,
            followState,
            hazard,
            retreatState,
            now
        )
        if hordeHandled then
            return true
        end
    end
    if LeashHandoff and LeashHandoff.TryHandle then
        leashHandled = LeashHandoff.TryHandle(
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
        if leashHandled then
            return true
        end
    end
    return false
end

return Companion
