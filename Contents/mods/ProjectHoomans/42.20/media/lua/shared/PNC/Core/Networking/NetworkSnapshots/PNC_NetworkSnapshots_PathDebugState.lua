--[[
    PNC Network Snapshots - Path Debug State
    Serializes pathing and navigation diagnostics.
]]

local Network = PNC.Network
local Parts = Network.Internal.SnapshotParts

function Parts.BuildPathDebugState(record)
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

return Parts
