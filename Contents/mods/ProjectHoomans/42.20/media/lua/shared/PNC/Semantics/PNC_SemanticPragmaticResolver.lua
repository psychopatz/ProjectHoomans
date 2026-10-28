-- Context-sensitive pragmatic interpretation over semantic interaction state.
-- Never parses text; it resolves an already-semantic stimulus against bounded
-- conversation/scene state.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local ValueBounds = require "PNC/Semantics/PNC_SemanticValueBounds"
local Relations = require "PNC/Semantics/PNC_SemanticInteractionRelations"

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

local function hasRelation(row, kind, relation)
    local values = row.relations and row.relations[kind] or {}
    for index = 1, math.min(#values, 8) do
        if values[index] == relation then return true end
    end
    return false
end

local function compatibleActors(row, actor, target, relation)
    if not row.actorID or not row.targetID then return false end
    if row.effectiveStrength ~= nil and row.effectiveStrength <= 0
        or row.confidence ~= nil and row.confidence < 0.25 then return false end
    local direction = hasRelation(row, "opens", relation) and Relations.Direction(relation) or "same"
    return (direction == "same" or direction == "either")
            and row.actorID == actor and row.targetID == target
        or (direction == "reverse" or direction == "either")
            and row.actorID == target and row.targetID == actor
end

-- Pure relation matching over the provider read model. No event-name lookup,
-- parser branch, store mutation or gameplay permission is owned here.
function Resolver.ResolveEvidence(stimulus, evidence)
    local semantic = stimulus.semantic or {}
    local metadata = Relations.GetAct(semantic.speechAct or semantic.intent)
    local wanted = {}
    for _, kind in ipairs({ "addresses", "resolves", "violates", "explains" }) do
        for _, relation in ipairs(metadata and metadata.relations[kind] or {}) do
            if #wanted < 8 then wanted[#wanted + 1] = relation end
        end
    end
    local result = { status = "unrelated", admitted = false, candidates = {},
        reason = "act_has_no_context_requirement", relations = wanted }
    if #wanted == 0 then return result end
    result.status, result.reason = "unresolved", "no_compatible_antecedent"
    local actor = stimulus.source and stimulus.source.actorID
    local target = stimulus.targets and stimulus.targets[1]
    if not actor or not target then result.reason = "actor_target_unavailable"; return result end
    local rows = evidence and evidence.rows or {}
    local tierOrder = { SESSION = 1, TODAY = 2, DURABLE = 3 }
    for _, relation in ipairs(wanted) do
        local latestSession, latestToday, latestDurable, todayHasClosure
        for index = 1, math.min(#rows, 16) do
            local row = rows[index]
            if row.sourceTier == "SESSION" and compatibleActors(row, actor, target, relation)
                and (hasRelation(row, "opens", relation) or hasRelation(row, "addresses", relation)
                    or hasRelation(row, "resolves", relation))
                and (not latestSession or (row.sequence or 0) > (latestSession.sequence or 0)) then
                latestSession = row
            end
            if compatibleActors(row, actor, target, relation)
                and (hasRelation(row, "opens", relation) or hasRelation(row, "addresses", relation)
                    or hasRelation(row, "resolves", relation)) then
                if row.sourceTier == "TODAY" then
                    if not hasRelation(row, "opens", relation) then todayHasClosure = true end
                    if not latestToday or (row.sequence or 0) > (latestToday.sequence or 0) then latestToday = row end
                elseif row.sourceTier == "DURABLE" and (not latestDurable
                    or (row.occurredAt or 0) > (latestDurable.occurredAt or 0)
                    or (row.occurredAt or 0) == (latestDurable.occurredAt or 0)
                        and (row.sequence or 0) > (latestDurable.sequence or 0)) then
                    latestDurable = row
                end
            end
        end
        local sessionClosed = latestSession and not hasRelation(latestSession, "opens", relation)
        if latestToday and todayHasClosure then
            sessionClosed = not hasRelation(latestToday, "opens", relation)
        elseif not latestSession and not latestToday and latestDurable then
            sessionClosed = not hasRelation(latestDurable, "opens", relation)
        end
        for index = 1, math.min(#rows, 16) do
            local row = rows[index]
            if compatibleActors(row, actor, target, relation) and hasRelation(row, "opens", relation)
                and (row.effectiveStrength == nil or row.effectiveStrength > 0)
                and (row.confidence == nil or row.confidence >= 0.25)
                and not sessionClosed and #result.candidates < 8 then
                local age = row.ageHours or 24
                local recency = 1 / (1 + age / 24)
                local topicMatch = semantic.topic and row.topic == semantic.topic or false
                local relevance = 0.4 + 0.2 * recency + 0.15 * (row.confidence or 0.5)
                    + 0.15 * (row.effectiveStrength or 0.5)
                    + 0.1 * ((row.retentionSalience or 0) / 255)
                    + (topicMatch and 0.05 or 0)
                result.candidates[#result.candidates + 1] = {
                    sourceRef = row.sourceRef, providerID = row.providerID,
                    sourceTier = row.sourceTier, relation = relation,
                    actorID = row.actorID, targetID = row.targetID,
                    retentionSalience = row.retentionSalience, confidence = row.confidence,
                    effectiveStrength = row.effectiveStrength, ageHours = row.ageHours,
                    recency = recency, topicMatch = topicMatch,
                    contextualRelevance = relevance, relationCompatible = true,
                    priority = tierOrder[row.sourceTier],
                    actorTargetCompatible = true, sequence = row.sequence,
                }
            end
        end
        if sessionClosed then result.reason = "relation_already_addressed" end
    end
    table.sort(result.candidates, function(a, b)
        if a.sourceTier ~= b.sourceTier then return tierOrder[a.sourceTier] < tierOrder[b.sourceTier] end
        if a.sequence ~= b.sequence then return (a.sequence or 0) > (b.sequence or 0) end
        if a.contextualRelevance ~= b.contextualRelevance then return a.contextualRelevance > b.contextualRelevance end
        return a.sourceRef < b.sourceRef
    end)
    local selected = result.candidates[1]
    if selected then
        local second = result.candidates[2]
        if second and selected.relation ~= second.relation and selected.sourceTier == second.sourceTier
            and math.abs(selected.contextualRelevance - second.contextualRelevance) < 0.02 then
            result.status, result.reason = "ambiguous", "multiple_compatible_relations"
        else
            result.status, result.reason, result.admitted = "grounded", "compatible_relation", true
            result.selected = copy(selected)
        end
    end
    return result
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
        contextualAdmission = Resolver.ResolveEvidence(stimulus, root.evidence),
    }
end

return Resolver
