-- Follow-owner orchestration across formation, hazards, vehicles, and threats.

local Internal = PNC.BehaviorCompanion.Internal
local Core = PNC.Core
local Const = PNC.Const
local Stealth = PNC.Stealth
local Common = PNC.BehaviorCommon
local CompanionVehicle = PNC.CompanionVehicle
local CombatTactics = PNC.CombatTactics
local BehaviorCombat = PNC.BehaviorCombat
local Perception = PNC.Perception

function Internal.TickFollowOwner(record, zombie)
    local owner = Common.GetOwner(record)
    local now = Core.Now and Core.Now() or 0
    local ownerVehicle
    local vehicleHandled
    local vehicleReason
    local ownerDist
    local slotTarget
    local slotDist
    local moveMode
    local followState
    local hazard
    local moveTarget
    local prioritizeOwner
    local hordeCount
    local ownerEngaged
    local retreatState
    local retreatWasActive
    local retreatContinued
    local retreatReason
    local combatHordeCount
    local attackRetreatTriggered
    local combatTarget
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
        Internal.SetFollowMode(record, "returning_to_anchor")
        if Stealth and Stealth.Clear then
            Stealth.Clear(record, "owner_missing")
        end
        Common.ClearCombatTarget(record, "owner_missing_return_anchor")
        Common.MoveRecord(
            record,
            zombie,
            record.anchorX,
            record.anchorY,
            record.anchorZ,
            "walk",
            0.8,
            "owner_missing_return_anchor"
        )
        return true
    end

    if record.ownerUsername ~= owner:getUsername() then
        record.ownerUsername = owner:getUsername()
        if PNC.Registry and PNC.Registry.MarkDirty then
            PNC.Registry.MarkDirty(record, "owner")
        end
    end
    record.ownerOnlineID = owner:getOnlineID()
    followState = Internal.UpdateOwnerMotionState(record, owner, now)
    ownerEngaged = Internal.UpdateOwnerCombatState(record, owner, now)
    -- A follower may still be inside its formation tolerance when the owner
    -- first moves. End ambient presentation immediately instead of waiting
    -- for MoveRecord to be requested several ticks later.
    if followState.ownerMoving == true
        and PNC.AnimationScenes
        and PNC.AnimationScenes.Interrupt
    then
        PNC.AnimationScenes.Interrupt(record, zombie, "movement")
    end
    ownerVehicle = owner.getVehicle and owner:getVehicle() or nil
    if CompanionVehicle and CompanionVehicle.Tick then
        vehicleHandled, vehicleReason = CompanionVehicle.Tick(
            record,
            zombie,
            owner
        )
        if vehicleHandled then
            Internal.SetFollowMode(
                record,
                CompanionVehicle.IsPassenger
                    and CompanionVehicle.IsPassenger(record)
                    and "vehicle_passenger"
                    or "vehicle_disembark"
            )
            return true
        end
    end
    -- A companion trying to catch its owner's car should not abandon that
    -- task for opportunistic combat. When no seat exists, it waits instead of
    -- repeatedly pathing into the occupied vehicle.
    if ownerVehicle and vehicleReason == "vehicle_full" then
        Internal.SetFollowMode(record, "vehicle_full")
        record.activeBehavior = "FollowOwner:vehicle_full"
        Common.ClearCombatTarget(record, "vehicle_full", zombie)
        Common.HaltMovement(record, zombie, "vehicle_full")
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
        hazard.nearestDistance = nil
        hazard.expiresAt = 0
    end
    hordeCount = tonumber(hazard and hazard.count) or 0
    -- Combat retreat owns movement once it has started. Without this handoff,
    -- the follow formation pass can replace the retreat intent with a slot or
    -- horde-steering target on the very next behavior tick.
    if CombatTactics and CombatTactics.Internal
        and CombatTactics.Internal.EnsureRetreatState
    then
        retreatState = CombatTactics.Internal.EnsureRetreatState(record)
        retreatWasActive = retreatState and retreatState.phase == "retreat"
        if retreatWasActive then
            combatTarget = record.runtime and record.runtime.target or nil
            retreatContinued, retreatReason =
                CombatTactics.Internal.ContinueLockedRetreat(
                    record,
                    zombie,
                    combatTarget,
                    retreatState,
                    now
                )
            if retreatContinued then
                Internal.SetFollowMode(record, "combat_retreat")
                return true
            end
            if retreatReason == "retreat_complete"
                or retreatReason == "retreat_safe_radius"
            then
                if combatTarget and combatTarget.kind == "zombie"
                    and BehaviorCombat and BehaviorCombat.TickEngage
                    and tostring(record.attackType or Const.ATTACK_TYPE_AUTO)
                        ~= tostring(Const.ATTACK_TYPE_NONE or "none")
                then
                    BehaviorCombat.TickEngage(record, zombie, combatTarget)
                    Internal.SetFollowMode(record, "combat")
                    return true
                end
            end
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
    -- A near miss does not necessarily populate recentThreat, but it still
    -- arms the combat retreat marker. Do not let owner-priority formation
    -- logic hide that marker while a four-zombie horde is present.
    combatHordeCount = hordeCount
    if Perception and Perception.CountEnemyZombies then
        combatHordeCount = Perception.CountEnemyZombies(
            record, Const.COMBAT_HORDE_RADIUS
        )
    end
    attackRetreatTriggered = CombatTactics
        and CombatTactics.IsHordeAttackRetreatTriggered
        and CombatTactics.IsHordeAttackRetreatTriggered(
            retreatState,
            { hordeCount = combatHordeCount },
            now
        )
    if attackRetreatTriggered then
        if Internal.TryRespondToImmediateThreat(record, zombie) then
            Internal.SetFollowMode(record, "combat_retreat")
            return true
        end
        combatTarget = record.runtime and record.runtime.target or nil
        if combatTarget and combatTarget.kind == "zombie"
            and BehaviorCombat and BehaviorCombat.TickEngage
            and tostring(record.attackType or Const.ATTACK_TYPE_AUTO)
                ~= tostring(Const.ATTACK_TYPE_NONE or "none")
        then
            BehaviorCombat.TickEngage(record, zombie, combatTarget)
            Internal.SetFollowMode(record, "combat_retreat")
            return true
        end
    end
    if not ownerVehicle
        and not prioritizeOwner
        and Internal.ShouldScanFollowThreat(
            record,
            now,
            followState.ownerMoving == true
                or ownerDist >= (
                    tonumber(Const.FOLLOW_WALK_DISTANCE) or 4
                )
        )
        and Internal.TryRespondToThreat(
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
        Internal.SetFollowMode(record, "combat")
        return true
    end
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
    slotTarget = Internal.ResolveSampledFollowSlot(
        record,
        owner,
        followState.ownerMoving == true,
        now
    )
    slotTarget = Internal.EnforceOwnerPersonalSpace(
        record,
        owner,
        slotTarget,
        ownerDist
    )
    slotDist = slotTarget
        and Core.Distance(
            record.x,
            record.y,
            slotTarget.x,
            slotTarget.y
        )
        or ownerDist
    moveTarget = Internal.ResolveHordeAwareFollowTarget(
        record,
        slotTarget,
        slotDist,
        hazard,
        now
    ) or slotTarget
    if moveTarget == slotTarget
        and slotDist <= (
            slotTarget and slotTarget.stopDistance or Const.FOLLOW_DISTANCE
        )
        and math.abs(
            (slotTarget and slotTarget.z or owner:getZ()) - record.z
        ) < 1
    then
        return Internal.HoldAndFaceOwner(
            record,
            zombie,
            owner,
            "formation_hold",
            record.runtime.stealthActive
                and "holding_follow_stealth"
                or "holding_follow_position"
        )
    end
    Internal.SetFollowMode(record, "moving")
    record.activeBehavior = "FollowOwner:moving"
    moveMode = Stealth
        and Stealth.ResolveFollowMoveMode
        and Stealth.ResolveFollowMoveMode(
            record,
            owner,
            ownerDist,
            slotDist,
            hazard.count
        )
        or (
            ownerDist >= (
                tonumber(Const.FOLLOW_RUN_DISTANCE) or 10
            )
            and "run"
            or "walk"
        )
    if not Internal.ShouldIssueFollowMove(
        record,
        moveTarget,
        moveMode,
        now
    ) then
        return true
    end
    Common.ClearCombatTarget(
        record,
        moveTarget and moveTarget.avoidance
            and "following_owner_horde_avoidance"
            or (
                moveMode == "sneak"
                and "following_owner_sneak"
                or ("following_owner_" .. tostring(moveMode))
            )
    )
    Common.MoveRecord(
        record,
        zombie,
        moveTarget and moveTarget.x or owner:getX(),
        moveTarget and moveTarget.y or owner:getY(),
        moveTarget and moveTarget.z or owner:getZ(),
        moveMode,
        moveTarget and moveTarget.stopDistance or Const.FOLLOW_DISTANCE,
        moveTarget and moveTarget.avoidance
            and "follow_owner_horde_avoidance"
            or (
                moveMode == "sneak"
                and "follow_owner_sneak"
                or ("follow_owner_" .. tostring(moveMode))
            )
    )
    return true
end
