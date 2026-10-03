-- Shared movement stop and reset contract.
PNC = PNC or {}
PNC.BehaviorCommon = PNC.BehaviorCommon or {}

local Common = PNC.BehaviorCommon
local H = Common.Internal and Common.Internal.MovementHalt
if type(H) ~= "table" then return Common end

local Const = H.Const
local PathService = H.PathService
local ActorControl = H.ActorControl
local resolveMoveIntent = H.resolveMoveIntent

function Common.HaltMovement(record, zombie, reason, owner)
    local moveIntent = resolveMoveIntent()
    local controlOwner = owner
    local accepted
    local holdReason
    if ActorControl and ActorControl.ResolveOwner then
        controlOwner = ActorControl.ResolveOwner(owner, reason)
    end
    if record and record.presenceState == Const.PRESENCE_LIVE
        and moveIntent and moveIntent.Hold
    then
        accepted, holdReason = moveIntent.Hold(
            record,
            reason or "hold",
            controlOwner
        )
        if accepted == false then
            return false, holdReason or "movement_hold_rejected"
        end
        -- A live engine route must be relinquished before callers apply an
        -- idle presentation.  Deferring this to the next PathService pump
        -- leaves Behavior2/path2 alive while Animation.Apply writes the
        -- vanilla locomotion state, which makes doDeferredMovement reject the
        -- route as WalkTowardState + path2 ownership conflict.
        local planner = PNC.EnginePathPlanner
        local navigation = record.runtime and record.runtime.localNavigation
            or nil
        if navigation
            and navigation.provider == "engine_path"
            and planner
            and planner.Invalidate
        then
            planner.Invalidate(record, reason or "hold", zombie)
        end
        return true, "hold"
    end
    if zombie and PathService and PathService.Reset then
        if PathService.Commands and PathService.Commands.Reset then
            return PathService.Commands.Reset(
                record,
                zombie,
                reason,
                controlOwner
            )
        else
            return PathService.Reset(zombie, record, reason, controlOwner)
        end
    end
    return false, "movement_service_unavailable"
end

return Common

