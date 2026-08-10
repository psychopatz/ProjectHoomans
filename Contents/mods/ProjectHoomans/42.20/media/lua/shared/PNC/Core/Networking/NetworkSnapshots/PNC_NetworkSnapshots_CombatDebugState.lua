--[[
    PNC Network Snapshots - Combat Debug State
    Serializes tactical, defensive, aiming, and attack diagnostics.
]]

local Network = PNC.Network
local Parts = Network.Internal.SnapshotParts
local Core = PNC.Core
local Const = PNC.Const

function Parts.BuildCombatDebugState(record, combat, firearmState)
    local runtime = record.runtime or {}
    local npcIdentity = Parts.BuildIdentitySummary(record)
    local target = runtime.target
    local tactical = runtime.combatTactical or {}
    local aim = runtime.combatAim or {}
    local fireLane = runtime.combatFireLane or {}
    local retreat = runtime.combatRetreat or {}
    local defense = runtime.combatDefense or {}
    local action = runtime.attackAction
    local now = Core.Now()
    local zombieAttacker = runtime.zombieAttacker
    local attackLane = runtime.zombieAttackLane
    local zombieAttackerAge = zombieAttacker
        and math.max(
            0,
            now - (tonumber(zombieAttacker.observedAt) or now)
        ) or nil
    local viewZombies
    local visibleZombieCount
    local nearbyZombieCount
    viewZombies, visibleZombieCount, nearbyZombieCount =
        Parts.BuildCombatDebugObservations(record, target)
    return {
        target = target and {
            kind = target.kind,
            id = target.id or target.zombieId
                or target.onlineID or target.username,
            x = target.x,
            y = target.y,
            z = target.z,
            distSq = target.distSq,
            visible = target.visible ~= false,
            visibilityKind = target.visibilityKind,
            threatening = target.threatening == true,
        } or nil,
        mode = combat.combatModeResolved,
        weaponStatus = combat.weaponStatus,
        blockReason = combat.combatBlockReason,
        decision = tactical.decision,
        attackType = record.attackType or "auto",
        tacticalState = runtime.tacticalState,
        retreatPhase = retreat.phase,
        retreatReason = retreat.reason,
        biteLaneClear = attackLane and attackLane.clear == true or nil,
        biteLaneReason = attackLane and attackLane.reason or nil,
        biteLaneAgeMs = attackLane and math.max(
            0,
            now - (tonumber(attackLane.checkedAt) or now)
        ) or nil,
        viewZombies = viewZombies,
        visibleZombieCount = visibleZombieCount,
        nearbyZombieCount = nearbyZombieCount,
        surroundedCount = tactical.surrounded,
        pressureCount = tactical.pressure,
        visiblePressureCount = tactical.visiblePressure,
        hordeCount = tactical.horde,
        visibleHordeCount = tactical.visibleHorde,
        targetCrowdCount = tactical.targetCrowd,
        pressureTolerance = tactical.pressureTolerance,
        meleeSkill = tactical.meleeSkill,
        assessedAt = tactical.assessedAt,
        assessmentAgeMs = tactical.assessedAt
            and math.max(
                0,
                now - (tonumber(tactical.assessedAt) or now)
            ) or nil,
        staminaRatio = tactical.stamina,
        staminaCurrent = tactical.staminaCurrent,
        defenseRadius = tonumber(defense.radius)
            or tonumber(Const.NPC_ZOMBIE_DEFENSE_RADIUS)
            or 2.2,
        defenseNearbyCount = tonumber(defense.nearbyCount) or 0,
        defenseFitness = tonumber(defense.fitness),
        defenseDamageType = defense.damageType,
        defenseProtection = tonumber(defense.protection),
        defenseAvoidChance = tonumber(defense.avoidChance),
        defenseRoll = tonumber(defense.roll),
        defenseOutcome = defense.outcome,
        defensePushed = defense.pushed == true,
        defenseAgeMs = defense.updatedAt
            and math.max(0, now - (tonumber(defense.updatedAt) or now))
            or nil,
        zombieAttacker = zombieAttacker
            and zombieAttackerAge <= 1500 and {
                zombieId = zombieAttacker.zombieId,
                onlineID = zombieAttacker.onlineID,
                targetKind = "npc",
                targetId = record.id,
                targetName = npcIdentity.displayName
                    or record.displayName
                    or record.name
                    or "Unknown survivor",
                phase = zombieAttacker.phase,
                ageMs = zombieAttackerAge,
                x = zombieAttacker.x,
                y = zombieAttacker.y,
                z = zombieAttacker.z,
                distSq = zombieAttacker.distSq,
                actionState = zombieAttacker.actionState,
                bumpType = zombieAttacker.bumpType,
                path2Active =
                    zombieAttacker.path2Active == true,
            } or nil,
        aimConfidence = aim.confidence,
        aimReadyInMs = aim.readyAt
            and math.max(0, (tonumber(aim.readyAt) or now) - now)
            or nil,
        aimSettleMs = aim.settleMs,
        fireLaneSafe = fireLane.safe,
        fireLaneBlocker = fireLane.blockerKind and {
            kind = fireLane.blockerKind,
            id = fireLane.blockerID,
            x = fireLane.blockerX,
            y = fireLane.blockerY,
            z = fireLane.blockerZ,
        } or nil,
        tacticalMove = retreat.goalX ~= nil and {
            phase = retreat.phase,
            reason = retreat.reason,
            x = retreat.goalX,
            y = retreat.goalY,
            z = retreat.goalZ,
            mode = retreat.goalMode,
            lockRemainingMs = math.max(
                0,
                (tonumber(retreat.lockUntil) or now) - now
            ),
        } or nil,
        action = action and {
            attackType = action.attackType,
            attackKind = action.attackKind,
            anim = action.anim,
            animationRetries = action.animationRetries,
            animationTriggerMode = action.animationTriggerMode,
            animationStateEntered = action.animationStateEntered == true,
            animationActionState = action.animationActionState,
            phase = action.phase,
            hitRemainingMs = math.max(
                0,
                (tonumber(action.hitAt) or now) - now
            ),
            finishRemainingMs = math.max(
                0,
                (tonumber(action.finishAt) or now) - now
            ),
        } or nil,
        magazineCount = firearmState and firearmState.count or nil,
        magazineCapacity = firearmState and firearmState.capacity or nil,
        ammoReserveCount = firearmState and firearmState.reserveCount or nil,
        ammoReserveUnlimited = firearmState
            and firearmState.unlimitedReserve == true or false,
        reloadActive = firearmState
            and firearmState.reloadActive == true or false,
        meleeRange = Const.MELEE_RANGE,
        rangedMinStandoff = Const.RANGED_MIN_STANDOFF,
        rangedPreferredDistance = Const.RANGED_PREFERRED_MIN_DISTANCE,
        rangedRange = Const.RANGED_RANGE,
        pressureRadius = Const.COMBAT_PRESSURE_RADIUS,
        hordeRadius = Const.COMBAT_HORDE_RADIUS,
        coneRadius = Const.COMBAT_DEBUG_CONE_RADIUS,
        coneHalfAngleDegrees =
            Const.COMBAT_DEBUG_CONE_HALF_ANGLE_DEGREES,
    }
end

return Parts
