-- Movement request dispatch for the shared behavior helper.
-- This boundary owns the live move-intent preference and the path-service
-- fallbacks for both live and abstract records.
PNC = PNC or {}
PNC.BehaviorCommon = PNC.BehaviorCommon or {}

local Common = PNC.BehaviorCommon
local H = Common.Internal and Common.Internal.MovementDispatch
if type(H) ~= "table" then return Common end

local Const = H.Const
local PathService = H.PathService
local resolveMoveIntent = H.resolveMoveIntent

function H.Apply(
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
    if record.presenceState == Const.PRESENCE_LIVE then
        local moveIntent = resolveMoveIntent()
        if moveIntent and moveIntent.RequestMove then
            local accepted, requestReason = moveIntent.RequestMove(
                record,
                tx,
                ty,
                tz,
                mode,
                stopDistance,
                moveReason,
                intentNavigation,
                controlOwner
            )
            if accepted == false then
                return false, requestReason or "movement_request_rejected"
            end
            return true, requestReason or "move_intent"
        end
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
