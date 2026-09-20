-- Pure response formatting for semantic task results and camp acknowledgments.
-- Request correlation and conversation message delivery live in separate spokes.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input
local Internal = Input.Internal or {}
Input.Internal = Internal
local CampResponses = require
    "PNC/Semantics/PNC_SemanticDialogueInput_TaskResponses_Camp"

local TaskResponses = {}
TaskResponses.CampSiteDetails = CampResponses.CampSiteDetails
TaskResponses.CampLocationPhrase = CampResponses.CampLocationPhrase
TaskResponses.CampResponseFor = CampResponses.CampResponseFor

function TaskResponses.ActionName(payload, pending)
    return string.upper(tostring(payload and payload.action
        or pending and pending.action or ""))
end

-- The general presentation spoke loads before this one and reads these helpers
-- when it formats immediate camp acknowledgments.
Internal.CampSiteDetails = TaskResponses.CampSiteDetails
Internal.CampLocationPhrase = TaskResponses.CampLocationPhrase
Internal.CampResponseFor = TaskResponses.CampResponseFor

function TaskResponses.ForResult(payload, pending, action)
    action = action or TaskResponses.ActionName(payload, pending)
    local status = string.lower(tostring(payload and payload.status or ""))
    local reason = string.lower(tostring(payload and payload.reason or ""))
    if status == "completed" then
        if action == "GIVE" or action == "FETCH" then
            return "Here you go."
        end
        if action == "WAIT_AT" then
            return "I'm here."
        end
        if action == "CAMP" then
            return TaskResponses.CampResponseFor(
                payload, pending, "completed")
        end
        if action == "EAT" then
            return "That hit the spot."
        end
        if action == "DRINK" then
            return "I feel better."
        end
        if action == "REFILL" then
            return "It's full now."
        end
        if action == "CONSUME" then
            return "That's done."
        end
        return "It's done."
    end
    if (action == "GIVE" or action == "FETCH")
        and (string.find(reason, "item", 1, true)
            or string.find(reason, "inventory", 1, true)
            or string.find(reason, "classification", 1, true))
    then
        return "I don't have that."
    end
    if action == "FETCH" and reason == "fetch_source_unsupported" then
        return "I can only fetch something I'm already carrying."
    end
    if action == "FETCH" and reason == "fetch_destination_unsupported" then
        return "I can bring that to you, but not to someone else right now."
    end
    if (action == "EAT" or action == "DRINK" or action == "CONSUME")
        and (string.find(reason, "item", 1, true)
            or string.find(reason, "suitable", 1, true)
            or string.find(reason, "consum", 1, true)
            or string.find(reason, "classification", 1, true))
    then
        return "I don't have anything suitable."
    end
    if action == "REFILL"
        and (string.find(reason, "water", 1, true)
            or string.find(reason, "container", 1, true)
            or string.find(reason, "source", 1, true))
    then
        return "I can't refill that here."
    end
    if action == "CAMP" then
        local campFailure = CampResponses.FailureResponse(reason)
        if campFailure then return campFailure end
    end
    if action == "WAIT_AT"
        and (string.find(reason, "not_found", 1, true)
            or string.find(reason, "world_", 1, true)
            or string.find(reason, "target", 1, true))
    then
        return "I can't find that place nearby."
    end
    if reason == "npc_action_plan_active" then
        return "I'm still handling the last thing you asked."
    end
    if reason == "npc_action_plan_stale_cleanup_failed" then
        return "I need a moment to finish my last task."
    end
    if string.find(reason, "path", 1, true)
        or string.find(reason, "movement", 1, true)
    then
        return "I can't get there right now."
    end
    return "I couldn't do that right now."
end

Internal.TaskResponses = TaskResponses

return TaskResponses
