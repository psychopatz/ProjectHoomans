--[[
    PNC Network Snapshots - Combat Debug Attack Payload
    Serializes aiming, fire lane, attack, firearm, and range diagnostics.
]]

local Network = PNC.Network
local Parts = Network.Internal.SnapshotParts
local Const = PNC.Const

function Parts.BuildCombatDebugAttackPayload(context)
    local firearmState = context.firearmState
    local aim = context.aim
    local fireLane = context.fireLane
    local retreat = context.retreat
    local action = context.action
    local now = context.now

    return {
        aimConfidence = aim.confidence,
        aimRequiredConfidence = aim.requiredConfidence,
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
            effectiveCooldownMs = action.effectiveCooldownMs,
            rangedHitChance = action.rangedShotProfile
                and action.rangedShotProfile.hitChance or nil,
            rangedRoll = action.rangedOutcome
                and action.rangedOutcome.profile
                and action.rangedOutcome.profile.roll or nil,
            rangedOutcome = action.rangedOutcome
                and action.rangedOutcome.reason or nil,
            traitFingerprint = action.rangedShotProfile
                and action.rangedShotProfile.traitFingerprint or nil,
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
