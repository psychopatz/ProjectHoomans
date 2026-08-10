--[[
    PNC Network Snapshots - Detailed Debug State
    Builds the diagnostic section embedded in a full NPC snapshot.
]]

local Network = PNC.Network
local Parts = Network.Internal.SnapshotParts

function Parts.BuildDetailedDebugState(
    record,
    combat,
    firearmState,
    staminaInfo,
    canRevive,
    aiState,
    vehiclePassenger
)
    local pathing = record.runtime and record.runtime.pathing or nil
    local navigation = record.runtime
        and record.runtime.localNavigation or nil
    local navigationRouter = record.runtime
        and record.runtime.navigationRouter or nil
    return {
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
    }
end

return Parts
