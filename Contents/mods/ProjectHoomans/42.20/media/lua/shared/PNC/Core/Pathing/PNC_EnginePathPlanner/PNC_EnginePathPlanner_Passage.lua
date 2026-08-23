-- Scripted passage handoff from native path ownership.

local Planner = PNC.EnginePathPlanner
local Internal = Planner.Internal

function Internal.HandoffUpcomingPassage(record, body, navigation)
    local handled
    local state
    if not Internal.StageUpcomingPathPassage
        or not Internal.StageUpcomingPathPassage(
            record,
            body,
            navigation
        )
    then
        return false, nil
    end
    Internal.ClearEngineRequest(body, navigation)
    if PNC.PathService and PNC.PathService.AdvanceScriptedPassage then
        handled, state = PNC.PathService.AdvanceScriptedPassage(
            record,
            body,
            "engine_passage_handoff"
        )
        return true, state or (handled
            and "native_passage_handoff"
            or "native_passage_waiting")
    end
    return true, "native_passage_waiting"
end
