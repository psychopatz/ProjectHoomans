--[[
    PNC Networking - Snapshot Payloads
    Builds detailed, presence-delta, and character-detail payloads.
]]

PNC = PNC or {}
PNC.Network = PNC.Network or {}
PNC.Network.Internal = PNC.Network.Internal or {}

local Network = PNC.Network
local Core = PNC.Core
local Const = PNC.Const
local Equipment = PNC.Equipment
local Inventory = PNC.Inventory
local Skills = PNC.Skills
local Stamina = PNC.Stamina
local Profiles = PNC.VisualProfiles
local Wounds = PNC.NPCWounds
local Firearms = PNC.Firearms
local Parts = Network.Internal.SnapshotParts
local buildTravelSummary = Parts.BuildTravelSummary
local buildMapPresentationSummary = Parts.BuildMapPresentationSummary
local resolveAIState = Parts.ResolveAIState
local buildIdentitySummary = Parts.BuildIdentitySummary
local buildCombatSummary = Parts.BuildCombatSummary
local buildCommandFeedback = Parts.BuildCommandFeedback
local buildBandageFeedback = Parts.BuildBandageFeedback
local buildVisualState = Parts.BuildVisualState
local buildPathDebugState = Parts.BuildPathDebugState
local buildCombatDebugState = Parts.BuildCombatDebugState

function Network.BuildSnapshot(record)
    local aiState
    local canRevive
    local inCombat
    local staminaInfo
    local equipmentInfo
    local identity
    local inventorySummary
    local combat
    local visualState
    local appearance
    local bodyHealth
    local firearmState
    local vehiclePassenger
    local treatmentState
    local attackMode
    local pathing
    local navigation
    local navigationRouter
    aiState, inCombat = resolveAIState(record)
    canRevive = PNC.Health and PNC.Health.CanRevive and PNC.Health.CanRevive(record) or false
    staminaInfo = Stamina and Stamina.BuildSnapshot and Stamina.BuildSnapshot(record) or {}
    equipmentInfo = Equipment and Equipment.Describe and Equipment.Describe(record) or {}
    identity = buildIdentitySummary(record)
    inventorySummary = Inventory and Inventory.BuildSummaryPayload and Inventory.BuildSummaryPayload(record) or nil
    combat = buildCombatSummary(record, equipmentInfo)
    visualState = buildVisualState(record)
    appearance = Profiles and Profiles.RollAppearance and Profiles.RollAppearance(record) or nil
    bodyHealth = Wounds and Wounds.BuildSnapshot and Wounds.BuildSnapshot(record) or nil
    firearmState = Firearms and Firearms.BuildDebugState
        and Firearms.BuildDebugState(record)
        or nil
    vehiclePassenger = record.runtime and record.runtime.vehiclePassenger or nil
    pathing = record.runtime and record.runtime.pathing or nil
    navigation = record.runtime and record.runtime.localNavigation or nil
    navigationRouter = record.runtime
        and record.runtime.navigationRouter or nil
    treatmentState = PNC.BehaviorTreatment
        and PNC.BehaviorTreatment.BuildSnapshot
        and PNC.BehaviorTreatment.BuildSnapshot(record) or nil
    attackMode = record.runtime and (
        record.runtime.target ~= nil
        or (
            record.runtime.attackAction ~= nil
            and Core.Now() < (
                tonumber(record.runtime.attackAction.finishAt) or 0
            )
        )
    ) or false
    return {
        interestDetailed = true,
        id = record.id,
        name = identity.displayName,
        displayName = identity.displayName,
        identitySeed = identity.identitySeed,
        portrait = PNC.Identity
            and PNC.Identity.BuildPortraitSummary
            and PNC.Identity.BuildPortraitSummary(record)
            or nil,
        archetypeID = identity.archetypeID,
        archetypeLabel = identity.archetypeLabel,
        recruited = record.recruited == true,
        persist = record.persist ~= false,
        faction = record.faction,
        visualProfile = record.visualProfile,
        isFemale = identity.isFemale,
        identity = identity,
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
        commandFeedback = buildCommandFeedback(record),
        bandageFeedback = buildBandageFeedback(record),
        activeJob = record.activeJob,
        activeBehavior = record.activeBehavior,
        presenceState = record.presenceState,
        alive = record.alive,
        hpCurrent = record.health and record.health.current or nil,
        hpMax = record.health and record.health.max or nil,
        healthState = record.health and record.health.state or nil,
        canRevive = canRevive,
        reviveUntil = record.health and record.health.reviveUntil or 0,
        recentDamageUntil = record.health and record.health.recentDamageUntil or 0,
        bodyHealth = bodyHealth,
        treatmentState = treatmentState,
        staminaCurrent = staminaInfo.current,
        staminaMax = staminaInfo.max,
        staminaBaseMax = staminaInfo.baseMax,
        staminaState = staminaInfo.state,
        staminaVisibleUntil = staminaInfo.visibleUntil,
        encumbranceLevel = staminaInfo.encumbranceLevel,
        encumbranceRatio = staminaInfo.encumbranceRatio,
        staminaRatio = math.max(0, math.min(1, (tonumber(staminaInfo.current) or 0) / math.max(1, tonumber(staminaInfo.max) or 1))),
        skillLevels = Skills and Skills.BuildSnapshot and Skills.BuildSnapshot(record) or {},
        weaponMode = record.weaponMode,
        weaponFullType = record.equipment and record.equipment.primaryFullType or nil,
        combatModeResolved = equipmentInfo.combatModeResolved or record.weaponMode,
        weaponStatus = equipmentInfo.weaponStatus or "unknown",
        firearmState = firearmState,
        vehiclePassenger = vehiclePassenger and {
            active = vehiclePassenger.active == true,
            vehicleId = vehiclePassenger.vehicleId,
            seat = vehiclePassenger.seat,
            ownerOnlineID = vehiclePassenger.ownerOnlineID,
            boardedAt = vehiclePassenger.boardedAt,
        } or nil,
        presenceRevision = record.presenceRevision,
        liveBodyInstanceID = record.liveBodyInstanceID,
        liveBodyOnlineID = record.liveBodyOnlineID,
        liveBodyLease = record.runtime and record.runtime.bodyLease or nil,
        aiState = aiState,
        inCombat = inCombat,
        attackMode = attackMode,
        visualState = visualState,
        pathDebugState = buildPathDebugState(record),
        combatDebugState = buildCombatDebugState(
            record,
            combat,
            firearmState
        ),
        appearance = appearance and Core.DeepCopy(appearance) or nil,
        travel = buildTravelSummary(record, true),
        mapPresentation = buildMapPresentationSummary(record),
        equipmentSummary = {
            primaryFullType = record.equipment and record.equipment.primaryFullType or nil,
            secondaryFullType = record.equipment and record.equipment.secondaryFullType or nil,
            worn = Core.DeepCopy(record.equipment and record.equipment.worn or {}),
            attached = Core.DeepCopy(record.equipment and record.equipment.attached or {}),
        },
        inventorySummary = inventorySummary,
        characterWindow = {
            displayName = identity.displayName,
            archetypeID = identity.archetypeID,
            archetypeLabel = identity.archetypeLabel,
            identitySeed = identity.identitySeed,
            ownerUsername = record.ownerUsername,
            recruited = record.recruited == true,
            canRevive = canRevive,
            carry = inventorySummary,
        },
        debugState = {
            aiState = aiState,
            activeJob = record.activeJob,
            activeBehavior = record.activeBehavior,
            orderKind = record.orderSpec and record.orderSpec.kind or nil,
            attackType = record.attackType or "auto",
            targetKind = combat.targetKind,
            healthState = record.health and record.health.state or nil,
            canRevive = canRevive,
            weaponMode = record.weaponMode,
            combatModeResolved = combat.combatModeResolved,
            weaponStatus = combat.weaponStatus,
            magazineCount = firearmState and firearmState.count or nil,
            magazineCapacity = firearmState and firearmState.capacity or nil,
            ammoReserveUnlimited = firearmState and firearmState.unlimitedReserve == true or false,
            ammoReserveCount = firearmState and firearmState.reserveCount or nil,
            firearmReloadActive = firearmState and firearmState.reloadActive == true or false,
            vehiclePassenger = vehiclePassenger and vehiclePassenger.active == true or false,
            vehicleId = vehiclePassenger and vehiclePassenger.vehicleId or nil,
            vehicleSeat = vehiclePassenger and vehiclePassenger.seat or nil,
            vehicleBlockReason = record.runtime and record.runtime.vehicleBlockReason or nil,
            combatBlockReason = combat.combatBlockReason,
            tacticalDecision = combat.tacticalDecision,
            pressureCount = combat.pressureCount,
            visiblePressureCount = combat.visiblePressureCount,
            hordeCount = combat.hordeCount,
            visibleHordeCount = combat.visibleHordeCount,
            pressureTolerance = combat.pressureTolerance,
            aimConfidence = combat.aimConfidence,
            aimReadyAt = combat.aimReadyAt,
            fireLaneSafe = combat.fireLaneSafe,
            fireLaneBlockerKind = combat.fireLaneBlockerKind,
            staminaState = staminaInfo.state,
            staminaCurrent = staminaInfo.current,
            staminaMax = staminaInfo.max,
            staminaBaseMax = staminaInfo.baseMax,
            encumbranceLevel = staminaInfo.encumbranceLevel,
            encumbranceRatio = staminaInfo.encumbranceRatio,
            stealthActive = record.runtime and record.runtime.stealthActive == true or false,
            debugEnabled = record.runtime and record.runtime.debug == true or false,
            presenceState = record.presenceState,
            movePhase = pathing and pathing.phase or "idle",
            moveMode = pathing
                and (pathing.resolvedMode or pathing.mode) or nil,
            moveGoal = pathing and pathing.goal or nil,
            moveFinalGoal = pathing
                and pathing.finalGoalX ~= nil and {
                    x = pathing.finalGoalX,
                    y = pathing.finalGoalY,
                    z = pathing.finalGoalZ,
                } or nil,
            moveCancelReason = pathing and pathing.cancelReason or nil,
            moveBlockReason = pathing and pathing.blockReason or nil,
            moveIntentReason = pathing and pathing.intentReason or nil,
            moveOwnerMode = pathing and pathing.ownerMode or nil,
            moveLastStep = pathing and pathing.lastStepLabel or nil,
            moveLastStepDistance = pathing
                and pathing.lastStepDistance or nil,
            moveLastProgressDelta = pathing
                and pathing.lastProgressDelta or nil,
            moveGoalDistance = pathing and pathing.goalDistance or nil,
            moveBestGoalDistance = pathing
                and pathing.bestGoalDistance or nil,
            moveNonProgressSteps = pathing
                and pathing.nonProgressStepCount or 0,
            moveBlockedStepReason = pathing
                and pathing.blockedStepReason or nil,
            navigationPolicy = pathing
                and pathing.navigationPolicy
                or navigationRouter and navigationRouter.policy
                or nil,
            navigationProvider = pathing
                and pathing.navigationProvider
                or navigationRouter and navigationRouter.provider
                or nil,
            navigationPlanReason = navigation
                and navigation.lastPlanReason or nil,
            navigationSteeringKind = navigation
                and navigation.steeringKind or nil,
            navigationTraversalKind = navigation
                and navigation.currentTraversalKind or nil,
            navigationPathIndex = navigation
                and navigation.index or nil,
            navigationPathLength = navigation
                and navigation.path and #navigation.path or 0,
            navigationPlanFailures = navigation
                and navigation.planFailures or 0,
            navigationInvalidations = navigationRouter
                and navigationRouter.invalidations or 0,
            navigationInvalidationReason = navigationRouter
                and navigationRouter.lastInvalidationReason or nil,
        },
    }
end

function Network.BuildPresenceDelta(record)
    local aiState
    local inCombat
    local now = Core.Now()
    local staminaInfo = Stamina and Stamina.BuildSnapshot and Stamina.BuildSnapshot(record) or {}
    local firearmState = Firearms and Firearms.BuildDebugState
        and Firearms.BuildDebugState(record)
        or nil
    local vehiclePassenger = record.runtime and record.runtime.vehiclePassenger or nil
    aiState, inCombat = resolveAIState(record)
    local pathDebugState
    local lastPathDebugAt = record.runtime
        and tonumber(record.runtime.pathDebugReplicatedAt) or 0
    if lastPathDebugAt <= 0 or now - lastPathDebugAt >= 350 then
        pathDebugState = buildPathDebugState(record)
        if record.runtime then
            record.runtime.pathDebugReplicatedAt = now
        end
    end
    local combatDebugState
    local lastCombatDebugAt = record.runtime
        and tonumber(record.runtime.combatDebugReplicatedAt) or 0
    local combatDebugTransitioned = record.runtime
        and record.runtime.combatDebugWasActive ~= inCombat
        or false
    if lastCombatDebugAt <= 0
        or combatDebugTransitioned
        or (inCombat and now - lastCombatDebugAt >= 150)
    then
        local equipmentInfo = Equipment
            and Equipment.Describe
            and Equipment.Describe(record)
            or {}
        local combat = buildCombatSummary(record, equipmentInfo)
        combatDebugState = buildCombatDebugState(
            record,
            combat,
            firearmState
        )
        if record.runtime then
            record.runtime.combatDebugReplicatedAt = now
        end
    end
    if record.runtime then
        record.runtime.combatDebugWasActive = inCombat
    end
    return {
        interestDetailed = true,
        id = record.id,
        x = record.x,
        y = record.y,
        z = record.z,
        presenceState = record.presenceState,
        alive = record.alive,
        hpCurrent = record.health and record.health.current or nil,
        hpMax = record.health and record.health.max or nil,
        healthState = record.health and record.health.state or nil,
        attackType = record.attackType or "auto",
        commandFeedback = buildCommandFeedback(record),
        bandageFeedback = buildBandageFeedback(record),
        treatmentState = PNC.BehaviorTreatment
            and PNC.BehaviorTreatment.BuildSnapshot
            and PNC.BehaviorTreatment.BuildSnapshot(record) or nil,
        recentDamageUntil = record.health and record.health.recentDamageUntil or 0,
        staminaCurrent = staminaInfo.current,
        staminaMax = staminaInfo.max,
        staminaBaseMax = staminaInfo.baseMax,
        staminaState = staminaInfo.state,
        staminaVisibleUntil = staminaInfo.visibleUntil,
        encumbranceLevel = staminaInfo.encumbranceLevel,
        encumbranceRatio = staminaInfo.encumbranceRatio,
        presenceRevision = record.presenceRevision,
        liveBodyInstanceID = record.liveBodyInstanceID,
        liveBodyOnlineID = record.liveBodyOnlineID,
        liveBodyLease = record.runtime and record.runtime.bodyLease or nil,
        aiState = aiState,
        inCombat = inCombat,
        attackMode = record.runtime and record.runtime.target ~= nil or false,
        firearmState = firearmState,
        vehiclePassenger = vehiclePassenger and {
            active = vehiclePassenger.active == true,
            vehicleId = vehiclePassenger.vehicleId,
            seat = vehiclePassenger.seat,
            ownerOnlineID = vehiclePassenger.ownerOnlineID,
            boardedAt = vehiclePassenger.boardedAt,
        } or nil,
        visualState = buildVisualState(record),
        pathDebugState = pathDebugState,
        combatDebugState = combatDebugState,
        travel = buildTravelSummary(record, false),
    }
end

function Network.BuildCharacterPayload(record)
    local snapshot = Network.BuildSnapshot(record)
    local inventoryPayload = Inventory and Inventory.BuildFullPayload and Inventory.BuildFullPayload(record) or nil
    local identity = buildIdentitySummary(record)
    return {
        npcId = record.id,
        revision = record.presenceRevision,
        snapshot = snapshot,
        identity = identity,
        health = Core.DeepCopy(record.health or {}),
        stamina = Stamina and Stamina.BuildSnapshot and Stamina.BuildSnapshot(record) or {},
        inventory = inventoryPayload,
        equipment = Core.DeepCopy(record.equipment or {}),
        progression = {
            recruited = record.recruited == true,
            skillLevels = Skills and Skills.BuildSnapshot and Skills.BuildSnapshot(record) or {},
            skillXP = Core.DeepCopy(record.progression and record.progression.skillXP or {}),
        },
    }
end
