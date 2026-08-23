-- Motion provider: native engine-path execution boundary.

local Internal = PNC.PathService.Internal

function Internal.updateNativeMove(
    record,
    zombie,
    lane,
    navigation,
    enginePlanner,
    pumpNative,
    now
)
    local fromX = zombie:getX()
    local fromY = zombie:getY()
    local fromZ = zombie:getZ()
    local handled, state = Internal.tryNativeAdjacentPassage(
        record, zombie, lane, enginePlanner, now
    )
    if handled then
        return handled, state
    end

    local nativeTraversalState = enginePlanner.Internal
        and enginePlanner.Internal.GetNativeTraversalState
        and enginePlanner.Internal.GetNativeTraversalState(zombie)
        or nil
    if lane.goal then
        lane.resolvedMode = Internal.refreshResolvedLocomotion(
            record,
            lane,
            zombie,
            lane.goal
        )
        if nativeTraversalState == nil then
            Internal.setWalkAnim(
                zombie,
                record,
                lane.resolvedMode or lane.mode or lane.goal.mode,
                false
            )
        end
    end
    handled, state = pumpNative(record, zombie, lane)
    if not handled then
        return nil
    end
    return Internal.recordNativeMove(
        record,
        zombie,
        lane,
        navigation,
        enginePlanner,
        now,
        state,
        fromX,
        fromY,
        fromZ
    )
end
