-- Native, presentation, traversal, facing, and vehicle lane defaults.

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local Internal = PNC.PathService.Internal

function Internal.ensureLaneNativeAndPresentationState(lane)
    lane.nativeFailureCount = tonumber(lane.nativeFailureCount) or 0
    lane.nativeFailureGoalX = lane.nativeFailureGoalX ~= nil
        and tonumber(lane.nativeFailureGoalX) or nil
    lane.nativeFailureGoalY = lane.nativeFailureGoalY ~= nil
        and tonumber(lane.nativeFailureGoalY) or nil
    lane.nativeFailureGoalZ = lane.nativeFailureGoalZ ~= nil
        and tonumber(lane.nativeFailureGoalZ) or nil
    lane.nativeBlockedGoalX = lane.nativeBlockedGoalX ~= nil
        and tonumber(lane.nativeBlockedGoalX) or nil
    lane.nativeBlockedGoalY = lane.nativeBlockedGoalY ~= nil
        and tonumber(lane.nativeBlockedGoalY) or nil
    lane.nativeBlockedGoalZ = lane.nativeBlockedGoalZ ~= nil
        and tonumber(lane.nativeBlockedGoalZ) or nil
    lane.nativeBlockedUntil = tonumber(lane.nativeBlockedUntil) or 0
    lane.lastSpecialActionKey = lane.lastSpecialActionKey or nil
    lane.lastSpecialActionAt = tonumber(lane.lastSpecialActionAt) or 0
    lane.specialMoveUntil = tonumber(lane.specialMoveUntil) or 0
    lane.specialAnim = lane.specialAnim or nil
    lane.resolvedMode = lane.resolvedMode or nil
    lane.animSpeed = tonumber(lane.animSpeed) or 1.0
    lane.speed = tonumber(lane.speed) or 0
    lane.moveAnim = lane.moveAnim or "Idle"
    lane.walkType = lane.walkType or ""
    lane.engineWalkType = lane.engineWalkType or ""
    lane.profileKey = lane.profileKey or "idle"
    lane.staminaMode = lane.staminaMode or "travel"
    lane.isRunning = lane.isRunning == true
    lane.isCrawling = lane.isCrawling == true
    lane.motionProfile = lane.motionProfile or nil
    lane.motionHint = type(lane.motionHint) == "table" and lane.motionHint or nil
    lane.lastSuppressAudioAt = tonumber(lane.lastSuppressAudioAt) or 0
    lane.lastNetworkX = lane.lastNetworkX ~= nil and tonumber(lane.lastNetworkX) or nil
    lane.lastNetworkY = lane.lastNetworkY ~= nil and tonumber(lane.lastNetworkY) or nil
    lane.lastNetworkZ = lane.lastNetworkZ ~= nil and tonumber(lane.lastNetworkZ) or nil
    lane.lastNetworkAt = tonumber(lane.lastNetworkAt) or 0
end

function Internal.ensureLaneTraversalAndFacingState(lane)
    lane.lastTraversalObstacleKey = lane.lastTraversalObstacleKey or nil
    lane.lastTraversalKind = lane.lastTraversalKind or nil
    lane.lastTraversalFromKey = lane.lastTraversalFromKey or nil
    lane.lastTraversalToKey = lane.lastTraversalToKey or nil
    lane.lastTraversalFromX = lane.lastTraversalFromX ~= nil and tonumber(lane.lastTraversalFromX) or nil
    lane.lastTraversalFromY = lane.lastTraversalFromY ~= nil and tonumber(lane.lastTraversalFromY) or nil
    lane.lastTraversalFromZ = lane.lastTraversalFromZ ~= nil and tonumber(lane.lastTraversalFromZ) or nil
    lane.lastTraversalToX = lane.lastTraversalToX ~= nil and tonumber(lane.lastTraversalToX) or nil
    lane.lastTraversalToY = lane.lastTraversalToY ~= nil and tonumber(lane.lastTraversalToY) or nil
    lane.lastTraversalToZ = lane.lastTraversalToZ ~= nil and tonumber(lane.lastTraversalToZ) or nil
    lane.lastTraversalAttemptAt = tonumber(lane.lastTraversalAttemptAt) or 0
    lane.lastTraversalGoalRevision = tonumber(lane.lastTraversalGoalRevision) or 0
    lane.lastNonLocomotionState = lane.lastNonLocomotionState or nil
    lane.lastNonLocomotionAt = tonumber(lane.lastNonLocomotionAt) or 0
    lane.ownerMode = lane.ownerMode or "idle"
    lane.facingOwner = lane.facingOwner or "idle"
    lane.combatFacingUntil = tonumber(lane.combatFacingUntil) or 0
    lane.combatFacingX = lane.combatFacingX ~= nil and tonumber(lane.combatFacingX) or nil
    lane.combatFacingY = lane.combatFacingY ~= nil and tonumber(lane.combatFacingY) or nil
    lane.combatFacingZ = lane.combatFacingZ ~= nil and tonumber(lane.combatFacingZ) or nil
    lane.combatFacingReason = lane.combatFacingReason or nil
    lane.lastFacingAt = tonumber(lane.lastFacingAt) or 0
    lane.lastFacingDirX = lane.lastFacingDirX ~= nil and tonumber(lane.lastFacingDirX) or nil
    lane.lastFacingDirY = lane.lastFacingDirY ~= nil and tonumber(lane.lastFacingDirY) or nil
    lane.lastFacingX = lane.lastFacingX ~= nil and tonumber(lane.lastFacingX) or nil
    lane.lastFacingY = lane.lastFacingY ~= nil and tonumber(lane.lastFacingY) or nil
    lane.vehicleBlockedGoalX = lane.vehicleBlockedGoalX ~= nil
        and tonumber(lane.vehicleBlockedGoalX) or nil
    lane.vehicleBlockedGoalY = lane.vehicleBlockedGoalY ~= nil
        and tonumber(lane.vehicleBlockedGoalY) or nil
    lane.vehicleBlockedGoalZ = lane.vehicleBlockedGoalZ ~= nil
        and tonumber(lane.vehicleBlockedGoalZ) or nil
    lane.vehicleBlockedFromX = lane.vehicleBlockedFromX ~= nil
        and tonumber(lane.vehicleBlockedFromX) or nil
    lane.vehicleBlockedFromY = lane.vehicleBlockedFromY ~= nil
        and tonumber(lane.vehicleBlockedFromY) or nil
    lane.vehicleBlockedFromZ = lane.vehicleBlockedFromZ ~= nil
        and tonumber(lane.vehicleBlockedFromZ) or nil
    lane.vehicleBlockedAt = tonumber(lane.vehicleBlockedAt) or 0
    lane.vehicleBlockedReason = lane.vehicleBlockedReason or nil
end
