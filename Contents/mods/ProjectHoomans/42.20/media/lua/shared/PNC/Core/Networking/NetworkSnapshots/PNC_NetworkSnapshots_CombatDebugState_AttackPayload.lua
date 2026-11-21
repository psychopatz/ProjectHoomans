--[[
    PNC Network Snapshots - Combat Debug Attack Payload
    Serializes aiming, fire lane, attack, firearm, and range diagnostics.
]]

local Network = PNC.Network
local Parts = Network.Internal.SnapshotParts
local Const = PNC.Const

function Parts.BuildCombatDebugAttackPayload(context)
    local record = context.record
    local runtime = context.runtime
    local firearmState = context.firearmState
    local aim = context.aim
    local fireLane = context.fireLane
    local retreat = context.retreat
    local action = context.action
    local now = context.now

    local pSvc = PNC.PerceptionService
    local profile = pSvc and type(pSvc.GetProfile) == "function"
        and pSvc.GetProfile(record) or nil
    local coneRadius = profile and tonumber(profile.visionRange)
        or Const.COMBAT_DEBUG_CONE_RADIUS
    local coneHalfAngle = (profile and pSvc and type(pSvc.GetHalfFovDegrees) == "function"
        and pSvc.GetHalfFovDegrees(profile))
        or Const.COMBAT_DEBUG_CONE_HALF_ANGLE_DEGREES
    local peripheralRadius = math.sqrt(
        tonumber(pSvc and pSvc.CLOSE_PERIPHERAL_DIST_SQ) or 6.25
    )
    local cluesPayload = nil
    local clueCount = 0
    if record and pSvc and type(pSvc.GetClues) == "function" then
        local clues = pSvc.GetClues(record, now) or {}
        clueCount = #clues
        if clueCount > 0 then
            cluesPayload = {}
            local startIdx = math.max(1, clueCount - 3)
            for idx = clueCount, startIdx, -1 do
                local c = clues[idx]
                if type(c) == "table" and c.x ~= nil and c.y ~= nil then
                    cluesPayload[#cluesPayload + 1] = {
                        kind = c.kind,
                        x = c.x,
                        y = c.y,
                        z = c.z or 0,
                    }
                end
            end
        end
    end
    local agState = record and record.id ~= nil
        and PNC.AgitationService
        and type(PNC.AgitationService.GetState) == "function"
        and PNC.AgitationService.GetState(record.id, now)
        or nil
    local sc = runtime and type(runtime.secondaryChannel) == "table"
        and runtime.secondaryChannel or nil
    local frameRejected = runtime and type(runtime.perceptionFrame) == "table"
        and tonumber(runtime.perceptionFrame.coneRejectedCount) or 0

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
        coneRadius = coneRadius,
        coneHalfAngleDegrees = coneHalfAngle,
        peripheralRadius = peripheralRadius,
        perceptionProfileId = profile and profile.id or nil,
        hearingRange = profile and tonumber(profile.hearingRange) or nil,
        coneRejectedCount = frameRejected,
        clueCount = clueCount,
        clues = cluesPayload,
        agitationStage = agState and agState.stage or nil,
        agitationScore = agState and agState.score or nil,
        secondaryAlertLevel = sc and sc.alertLevel or nil,
        secondaryPosture = sc and sc.posture or nil,
        secondaryState = sc and sc.secondaryState or nil,
    }
end

return Parts
