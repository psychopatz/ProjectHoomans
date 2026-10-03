-- Stationary presentation movement ownership for the shared behavior helper.
-- Keep seat and sleep holds together so every movement producer observes the
-- same native presentation boundary before it asks for a route.
PNC = PNC or {}
PNC.BehaviorCommon = PNC.BehaviorCommon or {}

local Common = PNC.BehaviorCommon
local H = Common.Internal and Common.Internal.StationaryMovementHold
if type(H) ~= "table" then return Common end

local Core = H.Core
local Diagnostics = H.Diagnostics
local HaltMovement = H.HaltMovement

function H.Apply(record, zombie, moveReason, runtime, scene)
    local liveBodyControl = PNC.LiveBodyControl
    local now = Core and Core.Now and Core.Now() or 0
    local presentationKind
    local presentationReason
    local presentationHoldReason
    if liveBodyControl
        and liveBodyControl.ResolveStationaryPresentation
    then
        presentationKind, presentationReason =
            liveBodyControl.ResolveStationaryPresentation(record, now)
    elseif liveBodyControl
        and liveBodyControl.IsSeated
        and liveBodyControl.IsSeated(record) == true
        and liveBodyControl.IsPresentationCombatActive
        and not liveBodyControl.IsPresentationCombatActive(record, now)
    then
        presentationKind = "seat"
        presentationReason = "seated_safety"
    end
    if not presentationKind then return false, nil end

    presentationHoldReason = presentationKind == "sleep"
        and "sleep_hold" or "seated_hold"
    if presentationKind == "seat"
        and Diagnostics and Diagnostics.LogSeatingState
        and Diagnostics.IsSeatingRuntime
        and Diagnostics.IsSeatingRuntime(runtime, scene)
    then
        Diagnostics.LogSeatingState(
            "behavior_move_blocked_seated",
            record,
            zombie,
            scene,
            moveReason
        )
    end
    if liveBodyControl.ReleasePresentationMovement then
        liveBodyControl.ReleasePresentationMovement(
            record,
            zombie,
            presentationReason
        )
    end
    HaltMovement(record, zombie, presentationHoldReason)
    return true, presentationHoldReason
end

return Common
