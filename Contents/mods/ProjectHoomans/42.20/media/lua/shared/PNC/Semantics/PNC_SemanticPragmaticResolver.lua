-- Context-sensitive pragmatic interpretation over semantic interaction state.
-- Never parses text; it resolves an already-semantic stimulus against bounded
-- conversation/scene state.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local ValueBounds = require "PNC/Semantics/PNC_SemanticValueBounds"

local Resolver = PNC.Semantics.PragmaticResolver or {}
PNC.Semantics.PragmaticResolver = Resolver

Resolver.VERSION = 1
Resolver.MAX_ACTIVE_FLOWS = 8
Resolver.MAX_RECENT_ACTS = 4
Resolver.MAX_FACT_REFS = 8

local REPLY_ACTS = {
    ACCEPT = true,
    REFUSE = true,
    AGREE = true,
    DISAGREE = true,
    ACKNOWLEDGE = true,
    THANK = true,
    APOLOGIZE = true,
}

local function copy(value)
    return ValueBounds.Copy(value)
end

local function dialogueSnapshot(context)
    context = type(context) == "table" and context or {}
    local live = context.semanticContextState
    if live and type(live.ToContext) == "function" then
        local ok, value = pcall(live.ToContext, live)
        if ok and type(value) == "table" then return value end
    end
    if type(context.semanticDialogueContext) == "table" then
        return context.semanticDialogueContext
    end
    return {}
end

local function activeFlows(snapshot)
    local output = {}
    local sessions = type(snapshot.flowSessions) == "table"
        and snapshot.flowSessions or {}
    for index = 1, #sessions do
        if #output >= Resolver.MAX_ACTIVE_FLOWS then break end
        local session = sessions[index]
        local active = type(session) == "table"
            and type(session.active) == "table"
            and session.active or nil
        if active and active.flowId then
            output[#output + 1] = {
                flowID = tostring(active.flowId),
                nodeID = active.nodeId and tostring(active.nodeId) or nil,
                status = "active",
            }
        end
        local suspended = type(session) == "table"
            and type(session.suspended) == "table"
            and session.suspended or {}
        for suspendedIndex = 1, #suspended do
            if #output >= Resolver.MAX_ACTIVE_FLOWS then break end
            local item = suspended[suspendedIndex]
            if type(item) == "table" and item.flowId then
                output[#output + 1] = {
                    flowID = tostring(item.flowId),
                    nodeID = item.nodeId and tostring(item.nodeId) or nil,
                    status = "suspended",
                }
            end
        end
    end
    return output
end

local function pendingItem(snapshot)
    local pending = snapshot.pendingFollowUp
    if type(pending) == "table" and pending.status ~= "closed" then
        return {
            id = pending.id,
            kind = pending.kind,
            owner = pending.owner,
            topic = pending.topic,
            flowID = pending.flowID,
            nodeID = pending.nodeID,
            openedTurn = pending.openedTurn,
        }
    end
    local agenda = type(snapshot.agenda) == "table" and snapshot.agenda or {}
    for index = 1, #agenda do
        local item = agenda[index]
        if type(item) == "table" and item.status == "open" then
            return {
                id = item.id,
                kind = item.kind,
                owner = item.owner,
                topic = item.topic,
                flowID = item.flowID,
                nodeID = item.nodeID,
                openedTurn = item.openedTurn,
            }
        end
    end
    return nil
end

local function recentActs(snapshot)
    local output = {}
    local recent = type(snapshot.recentTurns) == "table"
        and snapshot.recentTurns or {}
    for index = 1, math.min(#recent, Resolver.MAX_RECENT_ACTS) do
        local row = recent[index]
        if type(row) == "table" then
            output[#output + 1] = {
                sequence = row.sequence,
                speaker = row.speaker,
                intent = row.intent,
                speechAct = row.speechAct,
                topic = row.topic,
                source = row.source,
            }
        end
    end
    return output
end

local function eventRefs(stimulus)
    local output = {}
    local semantic = type(stimulus.semantic) == "table"
        and stimulus.semantic or {}
    if semantic.eventID then output[#output + 1] = semantic.eventID end
    local payload = type(stimulus.payload) == "table"
        and stimulus.payload or {}
    local values = type(payload.eventRefs) == "table"
        and payload.eventRefs or {}
    for index = 1, math.min(#values, Resolver.MAX_FACT_REFS) do
        local value = tostring(values[index] or "")
        if value ~= "" then output[#output + 1] = value end
    end
    return output
end

local function factRefs(stimulus)
    local output = {}
    local semantic = type(stimulus.semantic) == "table"
        and stimulus.semantic or {}
    if semantic.factID then output[#output + 1] = semantic.factID end
    local payload = type(stimulus.payload) == "table"
        and stimulus.payload or {}
    local values = type(payload.factRefs) == "table"
        and payload.factRefs or {}
    for index = 1, math.min(#values, Resolver.MAX_FACT_REFS) do
        local value = tostring(values[index] or "")
        if value ~= "" then output[#output + 1] = value end
    end
    return output
end

function Resolver.Resolve(stimulus, state, context, root)
    stimulus = type(stimulus) == "table" and stimulus or {}
    root = type(root) == "table" and root or {}
    local semantic = type(stimulus.semantic) == "table"
        and stimulus.semantic or {}
    local snapshot = dialogueSnapshot(context)
    local pending = pendingItem(snapshot)
    local flows = activeFlows(snapshot)
    local intent = semantic.intent
    local speechAct = semantic.speechAct
    local replyLike = REPLY_ACTS[tostring(intent or "")] == true
        or REPLY_ACTS[tostring(speechAct or "")] == true

    local topic = semantic.topic
    local topicSource = topic and "stimulus" or nil
    if replyLike and pending and pending.topic then
        topic = pending.topic
        topicSource = "pending_interaction"
    elseif not topic then
        topic = root.scene and root.scene.currentTopic
            or snapshot.currentTopic
        topicSource = topic and "scene" or "unknown"
    end

    local subject = semantic.subject
    local subjectSource = subject and "stimulus" or nil
    if replyLike and pending and pending.topic
        and (not subject
            or string.lower(tostring(subject))
                == string.lower(tostring(pending.topic)))
    then
        -- The discourse resolver may already have materialized the pending
        -- topic into semantic.subject. Preserve where that subject came from
        -- instead of relabeling it as an independent stimulus subject.
        subject = pending.topic
        subjectSource = "pending_interaction"
    end

    local replyTo
    if replyLike and pending then
        replyTo = {
            kind = "pending_interaction",
            id = pending.id,
            interactionKind = pending.kind,
            owner = pending.owner,
            flowID = pending.flowID,
            nodeID = pending.nodeID,
            topic = pending.topic,
        }
    elseif replyLike and #flows > 0 then
        replyTo = {
            kind = "active_flow",
            flowID = flows[1].flowID,
            nodeID = flows[1].nodeID,
        }
    end

    return {
        schemaVersion = Resolver.VERSION,
        kind = "pragmatic_frame",
        stimulusType = stimulus.type,
        semantic = {
            intent = intent,
            speechAct = speechAct,
            subject = semantic.subject,
            confidence = semantic.confidence,
        },
        topic = topic,
        topicSource = topicSource,
        subject = subject,
        subjectSource = subjectSource,
        replyTo = replyTo,
        pending = copy(pending),
        activeFlows = flows,
        recentActs = recentActs(snapshot),
        groundedFactRefs = factRefs(stimulus),
        groundedEventRefs = eventRefs(stimulus),
        evidence = copy(root.evidence or { rows = {}, providers = {} }),
    }
end

return Resolver
