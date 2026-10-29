-- Bounded group turn arbitration for semantic social Scenes.
-- Selects at most one next actor. It does not generate or realize dialogue.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local TurnPolicy = PNC.Semantics.SocialTurnPolicy or {}
PNC.Semantics.SocialTurnPolicy = TurnPolicy

TurnPolicy.VERSION = 1
TurnPolicy.MAX_PARTICIPANTS = 4
TurnPolicy.RECIPIENT_BOOST = 2.0

local function cleanID(value)
    value = tostring(value or "")
    if value == "" or #value > 128
        or string.find(value, "[^%w_%.:%-]")
    then
        return nil
    end
    return value
end

local function participantMap(participants)
    local map = {}
    local order = {}
    for index = 1, math.min(
        #(type(participants) == "table" and participants or {}),
        TurnPolicy.MAX_PARTICIPANTS
    ) do
        local row = participants[index]
        local id = type(row) == "table" and cleanID(row.id) or nil
        if id and not map[id] then
            map[id] = row
            order[#order + 1] = id
        end
    end
    return map, order
end

function TurnPolicy.Select(spec)
    spec = type(spec) == "table" and spec or {}
    local participants, order = participantMap(spec.participants)
    local currentSpeakerID = cleanID(spec.currentSpeakerID)
    local currentRecipientID = cleanID(spec.currentRecipientID)
    local choices = type(spec.choicesByActor) == "table"
        and spec.choicesByActor or {}
    local interjections = type(spec.interjections) == "table"
        and spec.interjections or {}
    local rows = {}

    for index, actorID in ipairs(order) do
        local participant = participants[actorID]
        if actorID ~= currentSpeakerID then
            local choice = choices[actorID]
            local isRecipient = actorID == currentRecipientID
            local interjection = interjections[actorID]
            local player = participant and (
                participant.isPlayer == true
                or tostring(participant.kind or "") == "player"
            )
            local row = {
                actorID = actorID,
                order = index,
                role = isRecipient and "recipient" or "participant",
                eligible = false,
            }

            if participant and participant.actor
                and participant.actor.alive == false
            then
                row.reason = "actor_unavailable"
            elseif player and isRecipient then
                row.eligible = true
                row.waitForPlayer = true
                row.score = TurnPolicy.RECIPIENT_BOOST
                row.reason = "player_recipient_wait"
            elseif type(choice) ~= "table" or choice.selected == nil then
                row.reason = type(choice) == "table"
                    and choice.reason or "choice_unavailable"
            elseif isRecipient then
                row.eligible = true
                row.score = TurnPolicy.RECIPIENT_BOOST
                    + (tonumber(choice.selectedScore) or 0)
                    + (tonumber(choice.turnPriority) or 0)
                row.reason = "recipient_reply"
                row.choice = choice
            elseif type(interjection) == "table"
                and interjection.allowed == true
            then
                row.eligible = true
                row.score = (tonumber(choice.selectedScore) or 0)
                    + (tonumber(interjection.priority) or 0)
                    + (tonumber(choice.turnPriority) or 0)
                row.reason = "explicit_interjection"
                row.choice = choice
                row.motive = interjection.motive
            else
                row.reason = "interjection_not_eligible"
            end

            if row.eligible then
                row.targetID = cleanID(
                    type(choice) == "table" and choice.targetID or nil
                ) or currentSpeakerID
                if row.targetID == actorID then
                    row.eligible = false
                    row.reason = "self_target_rejected"
                end
            end
            rows[#rows + 1] = row
        end
    end

    local eligible = {}
    local npcInterjections = {}
    for _, row in ipairs(rows) do
        if row.eligible then
            eligible[#eligible + 1] = row
            if row.waitForPlayer ~= true
                and row.reason == "explicit_interjection"
            then
                npcInterjections[#npcInterjections + 1] = row
            end
        end
    end
    if spec.allowInterjectionOverPlayerWait == true
        and #npcInterjections > 0
    then
        eligible = npcInterjections
    end
    table.sort(eligible, function(left, right)
        if left.score ~= right.score then return left.score > right.score end
        if left.role ~= right.role then return left.role == "recipient" end
        if left.actorID ~= right.actorID then return left.actorID < right.actorID end
        return left.order < right.order
    end)

    local winner = eligible[1]
    if not winner then
        return {
            schemaVersion = TurnPolicy.VERSION,
            mode = "terminate",
            reason = "no_social_speaker",
            rows = rows,
        }
    end
    if winner.waitForPlayer then
        return {
            schemaVersion = TurnPolicy.VERSION,
            mode = "wait_player",
            actorID = winner.actorID,
            targetID = winner.targetID,
            reason = winner.reason,
            rows = rows,
        }
    end
    return {
        schemaVersion = TurnPolicy.VERSION,
        mode = "emit",
        actorID = winner.actorID,
        targetID = winner.targetID,
        choice = winner.choice,
        motive = winner.motive,
        reason = winner.reason,
        rows = rows,
    }
end

return TurnPolicy
