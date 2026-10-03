-- Ordered movement-record provider.
-- The surrounding file keeps the shared namespace and dependency wiring.

PNC = PNC or {}
PNC.BehaviorCommon = PNC.BehaviorCommon or {}

local Common = PNC.BehaviorCommon
local H = Common.Internal and Common.Internal.MoveRecord
if type(H) ~= "table" then
    return Common
end

local Const = H.Const
local PathService = H.PathService
local ActorControl = H.ActorControl
local SeatingAudit = H.SeatingAudit

function Common.MoveRecord(
    record,
    zombie,
    tx,
    ty,
    tz,
    mode,
    stopDistance,
    reason,
    navigationOptions,
    abstractSpeedOverride
)
    local moveReason = reason
        or (record and record.runtime and record.runtime.combatBlockReason)
        or (record and record.activeBehavior and ("move_" .. tostring(record.activeBehavior)))
        or (record and record.activeJob and ("move_" .. tostring(record.activeJob)))
        or "behavior_move"
    local finalX = tx
    local finalY = ty
    local finalZ = tz
    local intentNavigation = navigationOptions
    local controlOwner
    local runtime = record and record.runtime or nil
    local scene = runtime and runtime.animationScene or nil
    local stationaryHold = Common.Internal
        and Common.Internal.StationaryMovementHold
    if stationaryHold and stationaryHold.Apply then
        local held, holdReason = stationaryHold.Apply(
            record,
            zombie,
            moveReason,
            runtime,
            scene
        )
        if held then
            return false, holdReason
        end
    end
    if ActorControl and ActorControl.ResolveOwner then
        controlOwner = ActorControl.ResolveOwner(nil, moveReason)
    end
    if SeatingAudit and SeatingAudit.LogRequest
    then
        SeatingAudit.LogRequest(
            record,
            zombie,
            runtime,
            scene,
            moveReason,
            tx,
            ty,
            tz,
            mode,
            stopDistance
        )
    end
    if record.presenceState == Const.PRESENCE_LIVE then
        local movementRouting = Common.Internal
            and Common.Internal.MovementRouting
        if movementRouting and movementRouting.Apply then
            tx, ty, tz, mode, stopDistance, intentNavigation =
                movementRouting.Apply(
                    record,
                    zombie,
                    finalX,
                    finalY,
                    finalZ,
                    mode,
                    stopDistance,
                    moveReason,
                    navigationOptions,
                    controlOwner
                )
        end
    end
    local movementDispatch = Common.Internal
        and Common.Internal.MovementDispatch
    if movementDispatch and movementDispatch.Apply then
        return movementDispatch.Apply(
            record,
            zombie,
            tx,
            ty,
            tz,
            mode,
            stopDistance,
            moveReason,
            intentNavigation,
            controlOwner,
            abstractSpeedOverride
        )
    end
    if record.presenceState == Const.PRESENCE_LIVE then
        return PathService.MoveToward(
            record,
            zombie,
            tx,
            ty,
            tz,
            mode,
            stopDistance,
            moveReason,
            intentNavigation,
            controlOwner
        )
    end
    PathService.AdvanceAbstract(
        record,
        tx,
        ty,
        tz,
        stopDistance,
        abstractSpeedOverride
    )
    return true, "abstract_move"
end

return Common
