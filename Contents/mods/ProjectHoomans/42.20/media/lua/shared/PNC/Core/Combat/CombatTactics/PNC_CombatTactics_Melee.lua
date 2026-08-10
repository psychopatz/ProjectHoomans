-- Ground-target handling, formation approach, and melee pre-attack decisions.

PNC = PNC or {}
PNC.CombatTactics = PNC.CombatTactics or {}

local Tactics = PNC.CombatTactics
Tactics.Internal = Tactics.Internal or {}

local Internal = Tactics.Internal
local Core = PNC.Core
local Const = PNC.Const
local Perception = PNC.Perception
local Skills = PNC.Skills
local Spatial = PNC.SpatialIndex
local Stamina = PNC.Stamina
local TraversalQuery = PNC.TraversalQuery

local function targetObject(target)
    if not target then return nil end
    if target.kind == "zombie" then
        return Perception and Perception.FindZombieByID
            and Perception.FindZombieByID(target.zombieId) or nil
    end
    if target.kind == "player" then
        return target.player
    end
    return nil
end

function Tactics.IsGroundTarget(target)
    local object = targetObject(target)
    local Unarmed = PNC.CombatUnarmed
    return object ~= nil
        and Unarmed
        and Unarmed.IsGroundTarget
        and Unarmed.IsGroundTarget(object) == true
end

function Tactics.ShouldUseGroundFinisher(record, target)
    local report
    if not Tactics.IsGroundTarget(target) then
        return false, "target_not_grounded"
    end
    report = Internal.AssessThreat(record, target)
    if report.pressureCount
        > (tonumber(Const.COMBAT_GROUND_FINISHER_MAX_PRESSURE) or 1)
    then
        return false, "ground_finisher_unsafe"
    end
    return true, "ground_finisher_safe"
end

function Tactics.ResolveMeleeApproach(record, dist)
    local state = Internal.EnsureRetreatState(record)
    local shouldApproach
    local preferredMode
    dist = tonumber(dist) or math.huge
    if not state then
        return false, Const.MELEE_RANGE, "walk"
    end
    if state.approachActive then
        if dist <= (Const.MELEE_RANGE - Const.COMBAT_KITE_MELEE_STOP_BUFFER) then
            state.approachActive = false
        end
    elseif dist > (Const.MELEE_RANGE + Const.COMBAT_KITE_MELEE_ENTER_BUFFER) then
        state.approachActive = true
    end
    shouldApproach = state.approachActive == true
    preferredMode = dist > (Const.MELEE_RANGE + Const.COMBAT_KITE_MELEE_HOLD_BUFFER) and "run" or "walk"
    return shouldApproach,
        tonumber(Const.MELEE_APPROACH_STOP_DISTANCE)
            or math.max(0.75, (tonumber(Const.MELEE_RANGE) or 1.3) - 0.35),
        preferredMode
end

function Tactics.GetMeleeApproachPoint(record, target)
    local candidates
    local other
    local allyCount = 0
    local angle
    local radius
    local x
    local y
    local i
    if not record or not target or not Spatial or not Spatial.QueryNPCs then
        return target and target.x, target and target.y, false
    end
    candidates = Spatial.QueryNPCs(
        target.x,
        target.y,
        tonumber(Const.COMBAT_FORMATION_QUERY_RADIUS) or 2.4
    )
    for i = 1, #candidates do
        other = candidates[i]
        if Internal.IsProtectedNPC(record, other, target)
            and math.abs((tonumber(other.z) or record.z) - record.z) < 1
        then
            allyCount = allyCount + 1
        end
    end
    if allyCount <= 0 then return target.x, target.y, false end
    angle = Internal.StableDirection(record.id)
    radius = tonumber(Const.COMBAT_FORMATION_SLOT_RADIUS) or 1.05
    x = target.x + math.cos(angle) * radius
    y = target.y + math.sin(angle) * radius
    if TraversalQuery and TraversalQuery.CanOccupy
        and not TraversalQuery.CanOccupy(x, y, target.z or record.z)
    then
        angle = angle + math.pi
        x = target.x + math.cos(angle) * radius
        y = target.y + math.sin(angle) * radius
    end
    return x, y, true
end

function Tactics.PreAttackDecision(record, zombie, target, effectiveMode, equipmentInfo)
    local report
    local state
    local now
    local dist
    local meleeLane
    local grounded
    local sourceX
    local sourceY
    local centroidCount
    local skillID
    local meleeSkill
    local pressureTolerance
    local shouldShove
    local canSpendMelee
    local retreatMinPressure
    local continued
    local continueReason
    local safetyRadius
    local safetyBuffer
    local recoveryThreshold
    local retreatDistance
    if not record or not zombie or not target or target.kind ~= "zombie" then
        return false, nil, nil
    end
    now = Core.Now()
    state = Internal.EnsureRetreatState(record)
    dist = math.sqrt(tonumber(target.distSq)
        or Core.DistanceSq(record.x, record.y, target.x, target.y))
    safetyRadius = tonumber(Const.NPC_ZOMBIE_DEFENSE_RADIUS) or 2.2
    safetyBuffer = tonumber(Const.COMBAT_RETREAT_SAFETY_BUFFER) or 0.25
    recoveryThreshold = tonumber(
        Const.COMBAT_EXHAUSTED_REENGAGE_CURRENT
    ) or 35
    meleeLane = effectiveMode == "melee"
        or (
            effectiveMode == "mixed"
            and dist <= (tonumber(Const.MELEE_RANGE) or 1.3) * 1.1
        )
    if not meleeLane then return false, nil, nil end
    continued, continueReason = Internal.ContinueLockedRetreat(
        record,
        zombie,
        target,
        state,
        now
    )
    if continued then
        return true, continueReason or state.reason or "combat_retreat", nil
    end
    if continueReason == "retreat_stalled" then
        return false, continueReason, nil
    end

    report = Internal.AssessThreat(record, target)
    grounded = Tactics.IsGroundTarget(target)
    retreatMinPressure = tonumber(
        Const.COMBAT_TACTICAL_RETREAT_MIN_PRESSURE
    ) or 2
    if state.lowStaminaPhase == "recover" then
        if Internal.StaminaCurrent(record) >= recoveryThreshold then
            state.lowStaminaPhase = nil
            state.lowStaminaAttackUntil = 0
        elseif dist < safetyRadius then
            retreatDistance = math.max(
                0.8,
                safetyRadius - dist + safetyBuffer
            )
            record.runtime.combatTactical.decision =
                "exhausted_recovery_retreat"
            continued, continueReason = Internal.StartRetreat(
                record,
                zombie,
                target,
                retreatDistance,
                "walk",
                0.3,
                tonumber(Const.COMBAT_KITE_RETREAT_LOCK_MS) or 1100,
                "exhausted_recovery_retreat",
                "retreat",
                nil,
                nil,
                nil,
                safetyRadius
            )
            if continued then
                state.lowStaminaPhase = "retreat"
            end
            return continued, continueReason, nil
        else
            record.runtime.combatTactical.decision =
                "recovering_stamina_safe"
            Internal.RequestHold(record, zombie, "recovering_stamina_safe")
            return true, "recovering_stamina_safe", nil
        end
    end
    if not grounded
        and now <= (tonumber(state.nearMissUntil) or 0)
        and report.pressureCount < retreatMinPressure
        and dist <= (tonumber(Const.COMBAT_SHOVE_RANGE) or 1.35)
    then
        state.nearMissUntil = 0
        record.runtime.combatTactical.decision =
            "lone_threat_counter"
        return false, "lone_threat_counter", "shove"
    end
    if Internal.TryNearMissRetreat(record, zombie, target, state, now, report) then
        return true, "near_miss_kite", nil
    end
    skillID = Skills and Skills.ResolveWeaponSkill
        and Skills.ResolveWeaponSkill(
            record,
            record.equipment and record.equipment.primaryFullType,
            "melee"
        ) or "Strength"
    meleeSkill = Skills and Skills.GetLevel
        and Skills.GetLevel(record, skillID) or 0
    pressureTolerance = 2
        + math.floor(math.min(meleeSkill, 9) / 3)
        + (equipmentInfo and equipmentInfo.hasWeapon and 1 or 0)
    pressureTolerance = math.min(
        tonumber(Const.COMBAT_PRESSURE_COUNT) or 4,
        pressureTolerance
    )
    shouldShove = not grounded
        and dist <= (tonumber(Const.COMBAT_SHOVE_RANGE) or 1.35)
        and report.surroundedCount
            < (tonumber(Const.COMBAT_SURROUND_COUNT) or 3)
        and report.pressureCount
            >= (tonumber(Const.COMBAT_SHOVE_PRESSURE_COUNT) or 2)
        and (
            equipmentInfo == nil
            or equipmentInfo.hasWeapon ~= true
            or report.pressureCount > pressureTolerance
        )
        and not Tactics.NeedsRecoveryRetreat(record)

    if shouldShove then
        record.runtime.combatTactical.decision = "pressure_shove"
        record.runtime.combatTactical.meleeSkill = meleeSkill
        record.runtime.combatTactical.pressureTolerance = pressureTolerance
        return false, "pressure_shove", "shove"
    end

    canSpendMelee = not Stamina
        or not Stamina.CanSpendAttack
        or Stamina.CanSpendAttack(record, "melee", skillID)
    if Tactics.NeedsRecoveryRetreat(record)
        and report.pressureCount >= retreatMinPressure
    then
        sourceX, sourceY, centroidCount = Internal.BuildZombieThreatCentroid(
            record,
            Const.COMBAT_HORDE_RADIUS
        )
        record.runtime.combatTactical.decision = "recovering_stamina"
        continued, continueReason = Internal.StartRetreat(
            record,
            zombie,
            target,
            2.8 + math.min(tonumber(centroidCount) or 0, 5) * 0.35,
            "walk",
            0.6,
            math.max(650, tonumber(Const.COMBAT_KITE_RETREAT_LOCK_MS) or 450),
            "recovering_stamina",
            "retreat",
            sourceX,
            sourceY,
            record.z,
            safetyRadius
        )
        if continued then
            state.lowStaminaPhase = "retreat"
        end
        return continued, continueReason, nil
    end
    if Tactics.NeedsRecoveryRetreat(record) and not grounded then
        if state.lowStaminaPhase ~= "counter" then
            state.lowStaminaPhase = "counter"
            state.lowStaminaAttackUntil = now
                + (tonumber(Const.COMBAT_EXHAUSTED_COUNTER_MS) or 1800)
        end
        if now < (tonumber(state.lowStaminaAttackUntil) or 0) then
            record.runtime.combatTactical.decision =
                "exhausted_lone_counter"
            if not canSpendMelee then
                record.runtime.emergencyMeleeUntil = now + 300
            end
            return false, "exhausted_lone_counter", nil
        end
        retreatDistance = math.max(
            0.8,
            safetyRadius - dist + safetyBuffer
        )
        record.runtime.combatTactical.decision =
            "exhausted_recovery_retreat"
        continued, continueReason = Internal.StartRetreat(
            record,
            zombie,
            target,
            retreatDistance,
            "walk",
            0.3,
            tonumber(Const.COMBAT_KITE_RETREAT_LOCK_MS) or 1100,
            "exhausted_recovery_retreat",
            "retreat",
            nil,
            nil,
            nil,
            safetyRadius
        )
        if continued then
            state.lowStaminaPhase = "retreat"
        end
        return continued, continueReason, nil
    end
    record.runtime.combatTactical.decision = grounded
        and "ground_finisher_window" or "melee_commit_window"
    record.runtime.combatTactical.meleeSkill = meleeSkill
    record.runtime.combatTactical.pressureTolerance = pressureTolerance
    return false, nil, grounded and "ground" or nil
end

return Tactics
