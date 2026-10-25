-- Bounded Talk response and inspector payload projections.

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local TalkParity = PNC.Conversation.TalkParity
local Internal = TalkParity.Internal
local copy = Internal.copy
local resolvedText = Internal.resolvedText
local choicesFor = Internal.choicesFor

local function messageText(message)
    if type(message) ~= "table" then return "" end
    local payload = message.payload or message.value
    return resolvedText(payload)
end

local function compactMessages(messages)
    local result = {}
    for _, message in ipairs(messages or {}) do
        if type(message) == "table" then
            result[#result + 1] = {
                id = message.id or message.messageID,
                speaker = message.speaker,
                text = messageText(message),
                kind = message.kind,
            }
        end
    end
    return result
end

local function compactRelationshipRecord(value, Values)
    local result = Values.copy(value)
    if type(result) ~= "table" then return result end
    for _, key in ipairs({
        "memories", "saturation", "cooldowns", "interactionJournal",
        "events", "history", "recentEvents",
    }) do
        result[key] = nil
    end
    return result
end

local function compactStart(value, Values)
    local result = Values.copy(value)
    if type(result) ~= "table" or type(result.opening) ~= "table" then
        return result
    end
    -- The opening suggestions are already returned by snapshot.suggestions;
    -- avoid repeating the full production candidate graph in every response.
    result.opening.suggestions = nil
    return result
end

local function compactTurn(context, turn)
    local Values = context.Values
    local result = type(turn) == "table" and turn.result or nil
    local ir = type(result) == "table" and result.ir or nil
    return {
        ok = turn and turn.ok == true or false,
        type = turn and turn.type,
        input = turn and turn.input,
        accepted = turn and turn.accepted == true or false,
        reason = turn and turn.reason,
        result = type(result) == "table" and {
            accepted = result.accepted == true,
            reason = result.reason,
            sequence = result.sequence,
            ir = type(ir) == "table" and {
                intent = ir.intent,
                speechAct = ir.speechAct,
                action = ir.action,
                subject = ir.subject,
                confidence = ir.confidence,
                normalizedText = ir.normalizedText,
            } or nil,
            actionResult = Values.copy(result.actionResult),
        } or nil,
        messages = compactMessages(turn and turn.messages or {}),
        toolCalls = Values.copy(turn and turn.toolCalls or {}),
        relationshipBefore = compactRelationshipRecord(
            turn and turn.relationshipBefore or {}, Values
        ),
        relationshipAfter = compactRelationshipRecord(
            turn and turn.relationshipAfter or {}, Values
        ),
    }
end

local function compactObservation(context, start, turn, snapshot)
    local observation = turn and turn.observation or {}
    local response = observation and observation.response or {}
    local contextSnapshot = snapshot and snapshot.context or {}
    local actor = contextSnapshot.actorConversationContext or {}
    local relationship = actor.relationship or {}
    local graph = observation.conversationGraph
        or turn and turn.conversationGraph
        or snapshot and snapshot.conversationGraph
    local suggestions = observation.suggestions or {}
    local choices = {}
    for _, candidate in ipairs(suggestions.candidates or {}) do
        if type(candidate) == "table" then
            choices[#choices + 1] = {
                id = candidate.id,
                action = candidate.action,
                label = candidate.display and candidate.display.label
                    or candidate.labelFallback,
                status = candidate.status,
            }
        end
    end
    local responseText = response.text
    if not responseText and turn and turn.messages then
        for index = #turn.messages, 1, -1 do
            local message = turn.messages[index]
            if message and message.speaker == "npc" then
                responseText = messageText(message)
                break
            end
        end
    end
    return {
        npcResponse = responseText,
        semanticHubChoices = choices,
        speechStyleContext = contextSnapshot.speechStyleContext
            or response.speechStyleContext or {},
        relationship = {
            standing = relationship.state or relationship.standing or "unknown",
            bond = context.Values.copy(
                relationship.bond
                or snapshot.simulationProjection
                    and snapshot.simulationProjection.npc
                    and snapshot.simulationProjection.npc.bond
                or {}
            ),
            approval = relationship.approval,
            respect = relationship.respect,
            familiarity = relationship.familiarity,
        },
        runtimeGraphPath = {
            kind = graph and graph.graphKind or "none",
            graph = context.Values.copy(graph),
        },
        suggestions = context.Values.copy(suggestions),
        choices = choicesFor(context.Runtime.view),
        messages = compactMessages(turn and turn.messages or {}),
        toolCalls = context.Values.copy(turn and turn.toolCalls or {}),
        accepted = turn and turn.accepted == true or false,
        reason = turn and turn.reason,
        start = compactStart(start, context.Values),
    }
end

local function compactScenario(value, Values)
    local result = Values.copy(value)
    if type(result) == "table" and type(result.npc) == "table" then
        result.npc.social = nil
        if type(result.npc.relationship) == "table" then
            result.npc.relationship = compactRelationshipRecord(
                result.npc.relationship, Values
            )
        end
    end
    return result
end

local function compactWorkingWorld(value, Values)
    local result = Values.copy(value)
    if type(result) ~= "table" then return result end
    for _, key in ipairs({ "effective", "baseline" }) do
        if type(result[key]) == "table"
            and type(result[key].npc) == "table"
        then
            result[key] = compactScenario(result[key], Values)
        end
    end
    return result
end

local function compactContext(value, Values)
    local result = Values.copy(value)
    if type(result) ~= "table" then return result end
    for _, key in ipairs({
        "knowledge", "dossier", "dialogue", "state", "engineFacts",
        "engineEvents", "categoryDiagnostics", "conversationRoot",
        "conversationBlock",
    }) do
        result[key] = nil
    end
    local actor = result.actorConversationContext
    if type(actor) == "table" and type(actor.relationship) == "table" then
        actor.relationship = compactRelationshipRecord(actor.relationship, Values)
    end
    return result
end

local function compactSnapshot(value, Values)
    local result = Values.copy(value)
    if type(result) ~= "table" then return result end
    result.scenario = compactScenario(result.scenario, Values)
    result.workingWorld = compactWorkingWorld(result.workingWorld, Values)
    result.context = compactContext(result.context, Values)
    result.relationship = compactRelationshipRecord(
        result.relationship, Values
    )
    local simulation = result.simulationProjection
    local relationship = type(simulation) == "table"
        and simulation.relationship or nil
    if type(relationship) == "table" then
        relationship.record = compactRelationshipRecord(
            relationship.record, Values
        )
    end
    return result
end

local function compactTalkSnapshot(value, Values)
    local result = compactSnapshot(value, Values)
    if type(result) ~= "table" then return result end
    -- TALK_START is a conversation boundary, not the full inspector
    -- boundary. Keep the projections needed by the UI and semantic parity,
    -- while avoiding repeated module manifests, transport history, source
    -- payloads, and diagnostic copies in both configured and snapshot.
    local keep = {
        ok = true,
        type = true,
        scenario = true,
        sourceSnapshot = true,
        workingWorld = true,
        suggestions = true,
        relationship = true,
        context = true,
        conversationGraph = true,
        simulationProjection = true,
        interactionLifecycle = true,
    }
    for key in pairs(result) do
        if not keep[key] then result[key] = nil end
    end
    return result
end

Internal.compactMessages = compactMessages
Internal.compactRelationshipRecord = compactRelationshipRecord
Internal.compactStart = compactStart
Internal.compactTurn = compactTurn
Internal.compactObservation = compactObservation
Internal.compactScenario = compactScenario
Internal.compactWorkingWorld = compactWorkingWorld
Internal.compactContext = compactContext
Internal.compactSnapshot = compactSnapshot
Internal.compactTalkSnapshot = compactTalkSnapshot

return TalkParity
