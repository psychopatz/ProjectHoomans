-- Ordered movement-record seating audit provider.
-- The composition root supplies diagnostics so MoveRecord keeps one public
-- movement contract while the seating observation remains independently owned.

PNC = PNC or {}
PNC.BehaviorCommon = PNC.BehaviorCommon or {}

local Common = PNC.BehaviorCommon
local H = Common.Internal and Common.Internal.MoveRecordSeatingAudit
if type(H) ~= "table" then
    return Common
end

local Diagnostics = H.Diagnostics

function H.LogRequest(
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
    local state = runtime and runtime.facilityActivity
        and runtime.facilityActivity.seating == true
        and runtime.facilityActivity
        or runtime and runtime.roamingSeat
    if Diagnostics and Diagnostics.LogSeatingState
        and Diagnostics.IsSeatingRuntime
        and Diagnostics.IsSeatingRuntime(runtime, scene)
        and (state and state.seatEntered == true or scene)
    then
        Diagnostics.LogSeatingState(
            "behavior_move_request_while_seated",
            record,
            zombie,
            scene,
            moveReason,
            {
                "requestedX=" .. tostring(tx or ""),
                "requestedY=" .. tostring(ty or ""),
                "requestedZ=" .. tostring(tz or ""),
                "requestedMode=" .. tostring(mode or ""),
                "requestedStopDistance=" .. tostring(stopDistance or ""),
            }
        )
    end
end

return Common
