PNC = PNC or {}
PNC.EnginePathPlanner = PNC.EnginePathPlanner or {}
PNC.EnginePathPlanner.Internal = PNC.EnginePathPlanner.Internal or {}

local Internal = PNC.EnginePathPlanner.Internal
local Diagnostics = PNC.PerformanceScalingDiagnostics

local function isSeatingNavigation(navigation)
    local record = navigation and navigation.record
    local runtime = record and record.runtime or nil
    return runtime and (
        runtime.facilityActivity and runtime.facilityActivity.seating == true
        or runtime.animationScene
            and runtime.animationScene.id == "facility.living.sitFurniture"
    )
end

function Internal.ClearEngineRequest(body, navigation)
    body = body or (navigation and navigation.body)
    local behavior = Internal.GetPathBehavior(body)
    if behavior then
        if behavior.cancel then behavior:cancel() end
        if behavior.reset then behavior:reset() end
    end
    if body and body.setPath2 then body:setPath2(nil) end
    local actionState = body and body.getActionStateName
        and string.lower(tostring(body:getActionStateName() or ""))
        or ""
    if Diagnostics and Diagnostics.SeatingAuditEnabled == true
        and isSeatingNavigation(navigation)
        and Diagnostics.LogSeatingAudit
    then
        Diagnostics.LogSeatingAudit("path_clear", {
            "npc=" .. tostring(navigation.record
                and navigation.record.id or ""),
            "bodyAction=" .. actionState,
            "pathPhase=" .. tostring(navigation.record.runtime.pathing
                and navigation.record.runtime.pathing.phase or ""),
            "nativeActive=" .. tostring(navigation.nativeActive == true),
            "requestPending=" .. tostring(navigation.requestPending == true),
            "reason=" .. tostring(navigation.lastPlanReason or ""),
            "revision=" .. tostring(navigation.requestRevision or ""),
        })
    end
    if actionState == "pathfind"
        and body.changeState
        and ZombieIdleState
        and ZombieIdleState.instance
    then
        body:changeState(ZombieIdleState.instance())
    end
    if navigation then
        Internal.SetServerMovementLease(body, navigation, false)
        navigation.requestPending = false
        navigation.requestStartedAt = 0
        navigation.movingStartedAt = 0
        navigation.lastPumpAt = 0
        navigation.lastPumpSource = nil
        navigation.nativeActive = false
        navigation.controllerMode = nil
        navigation.lastBehaviorResult = nil
        navigation.lastBehaviorUpdateAt = 0
        navigation.clientDelegated = false
        navigation.serverMovementLease = false
        navigation.nativeTraversalState = nil
        navigation.nativeTraversalStartedAt = 0
        navigation.nativeTraversalResult = nil
        navigation.inspectedEdgeX = nil
        navigation.inspectedEdgeY = nil
        navigation.inspectedEdgeZ = nil
        navigation.inspectedDirectionX = nil
        navigation.inspectedDirectionY = nil
        navigation.inspectedRequestRevision = nil
        navigation.upcomingPassage = nil
        navigation.lastObservedX = nil
        navigation.lastObservedY = nil
        navigation.lastObservedZ = nil
        navigation.lastPhysicalProgressAt = 0
        navigation.nativeBumpStartedAt = 0
    end
end

return Internal
