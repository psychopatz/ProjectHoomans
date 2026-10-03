-- Goal progression and movement plan for area roaming.

PNC = PNC or {}
PNC.BehaviorRoaming = PNC.BehaviorRoaming or {}

local Roaming = PNC.BehaviorRoaming
local H = Roaming.Internal and Roaming.Internal.AreaMovement
if type(H) ~= "table" then
    return Roaming
end

local Core = H.Core
local Const = H.Const
local Common = H.Common
local ChooseAreaGoal = H.ChooseAreaGoal
local SyncAreaBounds = H.SyncAreaBounds
local AreaStateChanged = H.AreaStateChanged
local HasActivePassage = H.HasActivePassage
local BeginAreaPause = H.BeginAreaPause

function H.Run(record, zombie, order, state, now)
    local reachedDistance = math.max(
        0.1,
        tonumber(order.reachedDistance) or Const.ROAM_REACHED_DISTANCE
    )

    if state.pausePending then
        if HasActivePassage(record) then
            Common.ClearCombatTarget(record, "roam_pause_deferred", zombie)
            Common.MoveRecord(
                record,
                zombie,
                state.goalX,
                state.goalY,
                state.goalZ,
                tostring(order.moveMode or "walk"),
                reachedDistance,
                "roam_area"
            )
            return true
        end
        state.pausePending = nil
        if BeginAreaPause(record, zombie, order, state, now) then
            return true
        end
    end

    if AreaStateChanged(record, order, state) then
        state.waitUntil = nil
        SyncAreaBounds(record, order, state)
        if BeginAreaPause(record, zombie, order, state, now) then
            return true
        end
        ChooseAreaGoal(record, order, state)
    elseif state.waitUntil then
        if now < state.waitUntil then
            state.phase = "idle"
            record.activeBehavior = "Roam:area:idle"
            if PNC.RoamAmbient and PNC.RoamAmbient.TryStart
                and PNC.RoamAmbient.TryStart(
                    record, zombie, order, state, now)
            then
                return true
            end
            if PNC.RoamingSeat and PNC.RoamingSeat.TryStart
                and PNC.RoamingSeat.TryStart(
                    record, zombie, order, state, now)
            then
                return true
            end
            return true
        end
        state.waitUntil = nil
        ChooseAreaGoal(record, order, state)
    elseif not state.goalX then
        ChooseAreaGoal(record, order, state)
    elseif Core.Distance(record.x, record.y, state.goalX, state.goalY)
        <= reachedDistance
    then
        local paused, deferred = BeginAreaPause(
            record,
            zombie,
            order,
            state,
            now
        )
        if paused then return true end
        if deferred then
            Common.ClearCombatTarget(record, "roam_pause_deferred", zombie)
            Common.MoveRecord(
                record,
                zombie,
                state.goalX,
                state.goalY,
                state.goalZ,
                tostring(order.moveMode or "walk"),
                reachedDistance,
                "roam_area"
            )
            return true
        end
        ChooseAreaGoal(record, order, state)
    end

    Common.ClearCombatTarget(record, "roaming")
    Common.MoveRecord(
        record,
        zombie,
        state.goalX,
        state.goalY,
        state.goalZ,
        tostring(order.moveMode or "walk"),
        reachedDistance,
        "roam_area"
    )
    return true
end

return Roaming
