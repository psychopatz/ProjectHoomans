--[[
    PNC Networking - Snapshot Parts
    Serializes reusable roster, identity, visual, and debug-state sections.
]]

PNC = PNC or {}
PNC.Network = PNC.Network or {}
PNC.Network.Internal = PNC.Network.Internal or {}

local Network = PNC.Network
local Internal = Network.Internal
local Core = PNC.Core
local Const = PNC.Const
local Equipment = PNC.Equipment
local Stamina = PNC.Stamina
local MotionHints = PNC.MotionHints
local Identity = PNC.Identity
local Settings = PNC.Sandbox

local function buildTravelSummary(record, includeRoute)
    return PNC.Travel
        and PNC.Travel.Model
        and PNC.Travel.Model.BuildSummary
        and PNC.Travel.Model.BuildSummary(record and record.travel, includeRoute)
        or nil
end

local function buildMapPresentationSummary(record)
    return PNC.MapPresentation
        and PNC.MapPresentation.BuildSummary
        and PNC.MapPresentation.BuildSummary(
            record and record.mapPresentation
        )
        or nil
end

local function resolveAIState(record)
    local healthState = record.health and tostring(record.health.state or "normal") or "normal"
    local hasTarget = record.runtime and record.runtime.target ~= nil
    local inCombat = hasTarget
        or ((tonumber(record.runtime and record.runtime.inCombatUntil or 0) or 0) > Core.Now())
    if record.alive == false then
        return "Dead", false
    end
    if healthState == "incapacitated" then
        return "Downed", true
    end
    if record.runtime and record.runtime.vehiclePassenger
        and record.runtime.vehiclePassenger.active == true
    then
        return "VehiclePassenger", false
    end
    if record.presenceState == Const.PRESENCE_ABSTRACT then
        return "Abstract", false
    end
    if inCombat then
        return "Combat", true
    end
    if record.activeBehavior and record.activeBehavior ~= "" then
        return tostring(record.activeBehavior), false
    end
    return "Idle", false
end

local function buildIdentitySummary(record)
    local summary = PNC.Identity and PNC.Identity.GetCharacterSummary and PNC.Identity.GetCharacterSummary(record) or {}
    return {
        displayName = summary.displayName or record.name,
        archetypeID = summary.archetypeID or record.archetypeID,
        archetypeLabel = summary.archetypeLabel or record.archetypeLabel,
        identitySeed = summary.identitySeed or record.identitySeed,
        isFemale = summary.isFemale == true or record.isFemale == true,
        survivor = Core.DeepCopy(summary.survivor or {}),
    }
end

local function buildCombatSummary(record, equipmentInfo)
    local target = record.runtime and record.runtime.target or nil
    local tactical = record.runtime and record.runtime.combatTactical or {}
    local aim = record.runtime and record.runtime.combatAim or {}
    local fireLane = record.runtime and record.runtime.combatFireLane or {}
    equipmentInfo = equipmentInfo or Equipment and Equipment.Describe and Equipment.Describe(record) or {}
    return {
        targetKind = target and target.kind or "none",
        combatModeResolved = equipmentInfo.combatModeResolved or record.weaponMode,
        weaponStatus = equipmentInfo.weaponStatus or "unknown",
        combatBlockReason = record.runtime and record.runtime.combatBlockReason or nil,
        tacticalDecision = tactical.decision,
        pressureCount = tactical.pressure,
        visiblePressureCount = tactical.visiblePressure,
        hordeCount = tactical.horde,
        visibleHordeCount = tactical.visibleHorde,
        pressureTolerance = tactical.pressureTolerance,
        aimConfidence = aim.confidence,
        aimReadyAt = aim.readyAt,
        fireLaneSafe = fireLane.safe,
        fireLaneBlockerKind = fireLane.blockerKind,
    }
end

local function buildCommandFeedback(record)
    local runtime = record and record.runtime or nil
    local revision = tonumber(runtime and runtime.lastCompanionCommandRevision)
    if not runtime or not runtime.lastCompanionCommand or revision == nil then
        return false
    end
    if Core.Now() - (tonumber(runtime.lastCompanionCommandAt) or 0)
        > (tonumber(Const.COMPANION_COMMAND_FEEDBACK_MS) or 5000)
    then
        return false
    end
    return {
        id = tostring(runtime.lastCompanionCommand),
        revision = revision,
        issuedAt = tonumber(runtime.lastCompanionCommandAt) or 0,
        ownerUsername = runtime.lastCompanionCommandOwner,
    }
end

local function buildBandageFeedback(record)
    local runtime = record and record.runtime or nil
    local revision = tonumber(runtime and runtime.bandageCompletionRevision)
    local completedAt = tonumber(runtime and runtime.bandageCompletionAt) or 0
    if not runtime or revision == nil then return false end
    if Core.Now() - completedAt
        > (tonumber(Const.BANDAGE_COMPLETION_FEEDBACK_MS) or 5000)
    then
        return false
    end
    return {
        revision = revision,
        completedAt = completedAt,
        partId = runtime.bandageCompletionPartId,
        sound = tostring(
            Const.BANDAGE_COMPLETION_SOUND or "PNC_BandageComplete"
        ),
    }
end

local function buildVisualState(record)
    local runtime = record and record.runtime or nil
    local path = runtime and runtime.pathing or nil
    local navigation = runtime
        and runtime.localNavigation or nil
    local attack = runtime and runtime.attackAction or nil
    local now = Core.Now()
    local healthState = record and record.health and tostring(record.health.state or "normal") or "normal"
    local moving = path and (
        path.phase == "requested"
        or path.phase == "active"
        or now < (tonumber(path.visualMovingUntil) or 0)
    ) or false
    local mode = moving and tostring(path.resolvedMode or path.mode or "walk") or nil
    local walkType = moving and tostring(path.walkType or "") or ""
    local moveAnim = moving and tostring(path.moveAnim or "") or ""
    local engineWalkType = moving and tostring(path.engineWalkType or "") or ""
    local anim = "Idle"
    local attackActive = attack ~= nil and now < (tonumber(attack.finishAt) or 0)
    local specialActive = path ~= nil and now < (tonumber(path.specialMoveUntil) or 0)
    local nativeTraversalState = navigation
        and navigation.nativeTraversalState or nil
    local nativeTraversalActive =
        nativeTraversalState ~= nil
    local nativeMoveActive = moving
        and navigation
        and navigation.nativeActive == true
        and navigation.clientDelegated == true
        or false
    local animSpeed = path and tonumber(path.animSpeed) or 1.0
    local profileKey = path and tostring(path.profileKey or "") or ""
    local isRunning = path and path.isRunning == true or false
    local isCrawling = path and path.isCrawling == true or false
    local motionHint = path and MotionHints and MotionHints.BuildNetworkHint and MotionHints.BuildNetworkHint(record, path, now) or nil
    local travelDirX = tonumber(motionHint and motionHint.dirX) or tonumber(path and path.lastFacingDirX)
    local travelDirY = tonumber(motionHint and motionHint.dirY) or tonumber(path and path.lastFacingDirY)
    local travelLen = travelDirX and travelDirY and math.sqrt((travelDirX * travelDirX) + (travelDirY * travelDirY)) or 0
    local facingDirX = tonumber(path and path.lastFacingDirX)
    local facingDirY = tonumber(path and path.lastFacingDirY)

    if travelLen > 0.0001 then
        travelDirX = travelDirX / travelLen
        travelDirY = travelDirY / travelLen
    else
        travelDirX = nil
        travelDirY = nil
    end

    if healthState == "incapacitated" then
        walkType = moving and tostring(path and path.walkType or "Crawl") or ""
        moveAnim = moving and tostring(path and path.moveAnim or "Crawl") or ""
        engineWalkType = moving and tostring(path and path.engineWalkType or "") or ""
        anim = moving and moveAnim or "Downed"
        isCrawling = moving
        profileKey = moving and tostring(path and path.profileKey or "crawl") or "downed"
    elseif moving then
        anim = moveAnim ~= "" and moveAnim or "Walk"
    end

    if specialActive and path and path.specialAnim then
        anim = tostring(path.specialAnim)
        moving = false
        walkType = ""
        moveAnim = ""
        engineWalkType = ""
    end

    if attackActive and attack and attack.anim then
        anim = tostring(attack.anim)
    end

    return {
        moving = moving,
        mode = mode,
        walkType = walkType,
        moveAnim = moveAnim,
        engineWalkType = engineWalkType,
        anim = anim,
        attackActive = attackActive,
        attackAnim = attack and attack.anim or nil,
        attackStartedAt = attack and attack.startedAt or 0,
        attackHitAt = attack and attack.hitAt or 0,
        attackFinishAt = attack and attack.finishAt or 0,
        animSpeed = animSpeed,
        isRunning = isRunning,
        isCrawling = isCrawling,
        profileKey = profileKey,
        motionHint = motionHint,
        travelDirX = travelDirX,
        travelDirY = travelDirY,
        facingDirX = facingDirX,
        facingDirY = facingDirY,
        facingOwner = path and path.facingOwner or nil,
        stationaryFacing = not moving and path and path.facingOwner == "behavior_idle" or false,
        specialActive = specialActive,
        specialAnim = specialActive and path and path.specialAnim or nil,
        specialFinishAt = specialActive and path and path.specialMoveUntil or 0,
        nativeTraversalActive = nativeTraversalActive,
        nativeTraversalState = nativeTraversalState,
        nativeMoveActive = nativeMoveActive,
        nativeMoveX = nativeMoveActive
            and navigation.requestX or nil,
        nativeMoveY = nativeMoveActive
            and navigation.requestY or nil,
        nativeMoveZ = nativeMoveActive
            and navigation.requestZ or nil,
        nativeMoveStopDistance = nativeMoveActive
            and navigation.requestStopDistance or nil,
        nativeMoveRevision = nativeMoveActive
            and navigation.requestRevision or 0,
    }
end

function Network.BuildRosterSnapshot(record, includeTravelRoute)
    local aiState
    local inCombat
    local staminaInfo
    local identity
    if type(record) ~= "table" then
        return nil
    end
    aiState, inCombat = resolveAIState(record)
    staminaInfo = Stamina and Stamina.BuildSnapshot and Stamina.BuildSnapshot(record) or {}
    identity = buildIdentitySummary(record)
    return {
        interestDetailed = false,
        id = record.id,
        displayName = identity.displayName,
        name = identity.displayName,
        archetypeID = identity.archetypeID,
        archetypeLabel = identity.archetypeLabel,
        identitySeed = identity.identitySeed,
        portrait = Identity
            and Identity.BuildPortraitSummary
            and Identity.BuildPortraitSummary(record)
            or nil,
        faction = record.faction,
        presenceState = record.presenceState,
        zombieTargetable = Settings
            and Settings.CanZombieTargetRecord
            and Settings.CanZombieTargetRecord(record)
            or false,
        x = record.x,
        y = record.y,
        z = record.z,
        orderKind = record.orderSpec and record.orderSpec.kind or nil,
        attackType = record.attackType or "auto",
        ownerUsername = record.ownerUsername
            or record.characterWindow
                and record.characterWindow.ownerUsername,
        ownerOnlineID = record.ownerOnlineID
            or record.characterWindow
                and record.characterWindow.ownerOnlineID,
        hpCurrent = record.health and record.health.current or nil,
        hpMax = record.health and record.health.max or nil,
        healthState = record.health and record.health.state or nil,
        staminaCurrent = staminaInfo.current,
        staminaMax = staminaInfo.max,
        staminaBaseMax = staminaInfo.baseMax,
        staminaState = staminaInfo.state,
        encumbranceLevel = staminaInfo.encumbranceLevel,
        encumbranceRatio = staminaInfo.encumbranceRatio,
        aiState = aiState,
        inCombat = inCombat,
        recruited = record.recruited == true,
        persist = record.persist ~= false,
        travel = buildTravelSummary(record, includeTravelRoute ~= false),
        mapPresentation = buildMapPresentationSummary(record),
    }
end

function Network.BuildDeathMarkerSnapshot(marker)
    if type(marker) ~= "table" or marker.id == nil then
        return nil
    end
    return {
        interestDetailed = false,
        id = tostring(marker.id),
        displayName = tostring(marker.name or marker.id),
        name = tostring(marker.name or marker.id),
        faction = "dead",
        presenceState = Const.PRESENCE_CORPSE,
        alive = false,
        deathMarker = true,
        colonist = marker.colonist == true,
        infected = marker.infected == true,
        portrait = marker.portrait and Core.DeepCopy(marker.portrait) or nil,
        corpseToken = marker.corpseToken,
        createdWorldHour = marker.createdWorldHour,
        x = tonumber(marker.x) or 0,
        y = tonumber(marker.y) or 0,
        z = tonumber(marker.z) or 0,
        hpCurrent = 0,
        hpMax = 0,
        healthState = "dead",
        aiState = "Dead",
        inCombat = false,
        recruited = false,
        persist = true,
    }
end

local function buildPathDebugState(record)
    local lane = record.runtime and record.runtime.pathing or nil
    local navigation = record.runtime
        and record.runtime.localNavigation or nil
    local router = record.runtime
        and record.runtime.navigationRouter or nil
    return {
        movePhase = lane and lane.phase or "idle",
        moveMode = lane and (lane.resolvedMode or lane.mode) or nil,
        moveGoal = lane and lane.goal or nil,
        moveFinalGoal = lane
            and lane.finalGoalX ~= nil and {
                x = lane.finalGoalX,
                y = lane.finalGoalY,
                z = lane.finalGoalZ,
            } or nil,
        moveBlockReason = lane and lane.blockReason or nil,
        moveLastStep = lane and lane.lastStepLabel or nil,
        moveGoalDistance = lane and lane.goalDistance or nil,
        moveNonProgressSteps = lane
            and lane.nonProgressStepCount or 0,
        moveRetargetCount = lane and lane.retargetCount or 0,
        moveSteeringTurnDot = lane
            and lane.steeringTurnDot or nil,
        moveBlockedStepReason = lane and lane.blockedStepReason or nil,
        navigationPolicy = lane
            and lane.navigationPolicy or router and router.policy or nil,
        navigationProvider = lane
            and lane.navigationProvider or router and router.provider or nil,
        navigationPlanReason = navigation
            and navigation.lastPlanReason or nil,
        navigationSteeringKind = navigation
            and navigation.steeringKind or nil,
        navigationTraversalKind = navigation
            and navigation.currentTraversalKind or nil,
        navigationPathIndex = navigation and navigation.index or nil,
        navigationSteeringIndex = navigation
            and navigation.steeringIndex
            or lane and lane.steeringIndex or nil,
        navigationPathLength = navigation
            and navigation.path and #navigation.path or 0,
        navigationPlanFailures = navigation
            and navigation.planFailures or 0,
        navigationInvalidationReason = router
            and router.lastInvalidationReason or nil,
    }
end

local function buildCombatDebugState(record, combat, firearmState)
    local runtime = record.runtime or {}
    local target = runtime.target
    local tactical = runtime.combatTactical or {}
    local aim = runtime.combatAim or {}
    local fireLane = runtime.combatFireLane or {}
    local retreat = runtime.combatRetreat or {}
    local defense = runtime.combatDefense or {}
    local action = runtime.attackAction
    local now = Core.Now()
    local zombieAttacker = runtime.zombieAttacker
    local zombieAttackerAge = zombieAttacker
        and math.max(
            0,
            now - (tonumber(zombieAttacker.observedAt) or now)
        ) or nil
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

Internal.SnapshotParts = {
    BuildTravelSummary = buildTravelSummary,
    BuildMapPresentationSummary = buildMapPresentationSummary,
    ResolveAIState = resolveAIState,
    BuildIdentitySummary = buildIdentitySummary,
    BuildCombatSummary = buildCombatSummary,
    BuildCommandFeedback = buildCommandFeedback,
    BuildBandageFeedback = buildBandageFeedback,
    BuildVisualState = buildVisualState,
    BuildPathDebugState = buildPathDebugState,
    BuildCombatDebugState = buildCombatDebugState,
}
