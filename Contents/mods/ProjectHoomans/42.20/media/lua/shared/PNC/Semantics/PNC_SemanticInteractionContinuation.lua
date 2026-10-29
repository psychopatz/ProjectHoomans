-- Generic semantic continuation policy for InteractionScene.
-- Decisions are derived from selected behavior metadata and semantic plans;
-- realized speech is never an input.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local ValueBounds = require "PNC/Semantics/PNC_SemanticValueBounds"

local Continuation = PNC.Semantics.InteractionContinuation or {}
PNC.Semantics.InteractionContinuation = Continuation

Continuation.VERSION = 1
Continuation.MAX_HISTORY = 8
Continuation.MAX_REPEAT = 2
Continuation.MAX_STEPS = 8
Continuation.MAX_REFS = 16

local function copy(value)
    return ValueBounds.Copy(value)
end

local function boundedToken(value)
    value = tostring(value or "")
    if value == "" or #value > 64
        or not string.match(value, "^[A-Z][A-Z0-9_]*$")
    then
        return nil
    end
    return value
end

local function boundedID(value)
    value = tostring(value or "")
    if value == "" or #value > 128
        or string.find(value, "[^%w_%.:%-]")
    then
        return nil
    end
    return value
end

local function refList(values)
    local output = {}
    local seen = {}
    for _, value in ipairs(type(values) == "table" and values or {}) do
        local id = boundedID(value)
        if id and not seen[id] then
            output[#output + 1] = id
            seen[id] = true
            if #output >= Continuation.MAX_REFS then break end
        end
    end
    return output
end

local function inheritedRefs(plan, stimulus, planField, payloadField)
    local values = type(plan) == "table" and plan[planField] or nil
    if type(values) == "table" and #values > 0 then
        return refList(values)
    end
    local payload = type(stimulus) == "table"
        and type(stimulus.payload) == "table"
        and stimulus.payload or {}
    return refList(payload[payloadField])
end

local function repeatCount(scene, key)
    local count = 0
    for _, row in ipairs(
        type(scene) == "table"
            and type(scene.continuationHistory) == "table"
            and scene.continuationHistory or {}
    ) do
        if row.key == key then count = count + 1 end
    end
    return count
end

local function repeatKey(sourceID, targetID, intent, speechAct, topic, facts, events)
    return table.concat({
        tostring(sourceID or ""),
        tostring(targetID or ""),
        tostring(intent or ""),
        tostring(speechAct or ""),
        tostring(topic or ""),
        tostring(facts[1] or ""),
        tostring(events[1] or ""),
    }, "|")
end

function Continuation.Decide(scene, turn)
    scene = type(scene) == "table" and scene or {}
    turn = type(turn) == "table" and turn or {}
    local plan = type(turn.plan) == "table" and turn.plan or {}
    local policy = type(plan.continuation) == "table"
        and plan.continuation or nil
    if not policy then
        return {
            schemaVersion = Continuation.VERSION,
            mode = "none",
            reason = "continuation_not_declared",
        }
    end

    local mode = tostring(policy.mode or "")
    if mode == "terminate" then
        return {
            schemaVersion = Continuation.VERSION,
            mode = "terminate",
            reason = "behavior_terminate",
            expectedResponse = boundedToken(policy.expectedResponse),
        }
    end

    local previousSource = boundedID(turn.sourceID)
    local previousResponder = boundedID(turn.responderID)
    local targetID
    if policy.target == "source" then
        targetID = previousSource
    elseif policy.target == "other" and previousResponder then
        for _, participantID in ipairs(
            type(scene.participantOrder) == "table"
                and scene.participantOrder or {}
        ) do
            participantID = boundedID(participantID)
            if participantID and participantID ~= previousResponder then
                targetID = participantID
                break
            end
        end
    end
    if not previousResponder or not targetID then
        return {
            schemaVersion = Continuation.VERSION,
            mode = "terminate",
            reason = "continuation_target_unavailable",
        }
    end
    local sourceParticipant = scene.participants
        and scene.participants[previousResponder] or nil
    local targetParticipant = scene.participants
        and scene.participants[targetID] or nil
    if not sourceParticipant or not targetParticipant then
        return {
            schemaVersion = Continuation.VERSION,
            mode = "terminate",
            reason = "continuation_participant_unavailable",
        }
    end

    if mode == "wait" or targetParticipant.isPlayer == true then
        return {
            schemaVersion = Continuation.VERSION,
            mode = "wait",
            reason = targetParticipant.isPlayer == true
                and "player_input_required"
                or "behavior_wait",
            sourceID = previousResponder,
            targetID = targetID,
            expectedResponse = boundedToken(policy.expectedResponse),
        }
    end
    if mode ~= "emit" then
        return {
            schemaVersion = Continuation.VERSION,
            mode = "terminate",
            reason = "continuation_mode_invalid",
        }
    end

    local intent = boundedToken(policy.intent)
        or boundedToken(plan.behaviorAct)
    local speechAct = boundedToken(policy.speechAct)
        or boundedToken(plan.dialogueAct)
        or intent
    if not intent or not speechAct then
        return {
            schemaVersion = Continuation.VERSION,
            mode = "terminate",
            reason = "continuation_semantic_act_invalid",
        }
    end

    local facts = policy.inheritFactRefs ~= false
        and inheritedRefs(plan, turn.stimulus, "groundedFactRefs", "factRefs")
        or {}
    local events = policy.inheritEventRefs ~= false
        and inheritedRefs(plan, turn.stimulus, "groundedEventRefs", "eventRefs")
        or {}
    local key = repeatKey(
        previousResponder,
        targetID,
        intent,
        speechAct,
        plan.topic,
        facts,
        events
    )
    if repeatCount(scene, key) >= Continuation.MAX_REPEAT then
        return {
            schemaVersion = Continuation.VERSION,
            mode = "terminate",
            reason = "continuation_repeat_suppressed",
            key = key,
        }
    end

    return {
        schemaVersion = Continuation.VERSION,
        mode = "emit",
        reason = "behavior_continuation",
        sourceID = previousResponder,
        targetID = targetID,
        intent = intent,
        speechAct = speechAct,
        topic = plan.topic,
        subject = plan.subject,
        factRefs = facts,
        eventRefs = events,
        expectedResponse = boundedToken(policy.expectedResponse),
        key = key,
    }
end

function Continuation.Remember(scene, decision, sequence)
    if type(scene) ~= "table"
        or type(decision) ~= "table"
        or decision.mode ~= "emit"
        or not decision.key
    then
        return false
    end
    scene.continuationHistory = type(scene.continuationHistory) == "table"
        and scene.continuationHistory or {}
    scene.continuationHistory[#scene.continuationHistory + 1] = {
        key = tostring(decision.key),
        sequence = tonumber(sequence) or 0,
        sourceID = decision.sourceID,
        targetID = decision.targetID,
        intent = decision.intent,
    }
    while #scene.continuationHistory > Continuation.MAX_HISTORY do
        table.remove(scene.continuationHistory, 1)
    end
    return true
end

function Continuation.Snapshot(scene)
    local history = {}
    for _, row in ipairs(
        type(scene) == "table"
            and type(scene.continuationHistory) == "table"
            and scene.continuationHistory or {}
    ) do
        history[#history + 1] = copy(row)
    end
    return {
        schemaVersion = Continuation.VERSION,
        last = copy(scene and scene.lastContinuation),
        history = history,
        count = #history,
        limits = {
            maxHistory = Continuation.MAX_HISTORY,
            maxRepeat = Continuation.MAX_REPEAT,
            maxSteps = Continuation.MAX_STEPS,
        },
    }
end

return Continuation
