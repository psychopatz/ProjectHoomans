--[[
    PNC Network Snapshots - Combat Debug Tactical Payload
    Serializes target, pressure, defense, and temporal diagnostics.
]]

local Network = PNC.Network
local Parts = Network.Internal.SnapshotParts
local Const = PNC.Const

function Parts.BuildCombatDebugTacticalPayload(context)
    local record = context.record
    local combat = context.combat
    local runtime = context.runtime
    local target = context.target
    local tactical = context.tactical
    local retreat = context.retreat
    local defense = context.defense
    local now = context.now
    local attackLane = context.attackLane
    local temporalState = context.temporalState

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
            proximityAlert = target.proximityAlert == true,
            alertOnly = target.alertOnly == true,
            alertSequence = target.alertSequence,
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
        viewZombies = context.viewZombies,
        visibleZombieCount = context.visibleZombieCount,
        nearbyZombieCount = context.nearbyZombieCount,
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
        zombieAttacker = temporalState.zombieAttacker,
        zombieStimulus = temporalState.zombieStimulus,
        zombieAlert = temporalState.zombieAlert,
    }
end

return Parts
