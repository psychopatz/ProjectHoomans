-- Bounded, read-only World Knowledge diagnostics for the native debug UI.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.WorldKnowledgeDebug = PNC.WorldKnowledgeDebug or {}

local Debug = PNC.WorldKnowledgeDebug
local Adapter = PNC.WorldKnowledge
local Core = PNC.Core

Debug.VERSION = 2
Debug.MAX_FACTS = 64
Debug.MAX_ACTORS = 128
Debug.MAX_REFS = 64
Debug.MAX_CANDIDATES = 16
Debug.MAX_TRACE = 64
Debug.MAX_CONSUMERS = 256

local function limit(value, maximum, fallback)
    value = tonumber(value)
    if not value or value ~= value then value = fallback end
    return math.max(1, math.min(maximum, math.floor(value)))
end

local function id(value)
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function compactReference(reference, fact)
    if type(reference) ~= "table" then return nil end
    return {
        factID = id(reference.factID), kind = fact and fact.kind or nil,
        producer = fact and fact.producer or nil,
        learnedAt = reference.learnedAt,
        firstLearnedAt = reference.firstLearnedAt,
        provenance = reference.provenance,
        sourceActorID = reference.sourceActorID,
        source = reference.source,
        acquisitionPath = reference.acquisitionPath,
        confidence = reference.confidence,
    }
end

local function compactFact(fact)
    if type(fact) ~= "table" then return nil end
    return {
        factID = fact.factID, kind = fact.kind, producer = fact.producer,
        subject = fact.subject, object = fact.object, location = fact.location,
        cause = fact.cause, occurredAt = fact.occurredAt,
        observedAt = fact.observedAt, severity = fact.severity,
        retention = fact.retention, expiresAt = fact.expiresAt,
        revision = fact.revision, shareable = fact.shareable,
        payload = fact.payload,
    }
end

local function compactCandidate(candidate)
    local fact = candidate and candidate.fact or nil
    local reference = candidate and candidate.reference or nil
    if not fact or not reference then return nil end
    return {
        factID = fact.factID, kind = fact.kind, producer = fact.producer,
        score = candidate.score, provenance = reference.provenance,
        confidence = reference.confidence, why = candidate.why,
    }
end

local function compactTrace(entry)
    if type(entry) ~= "table" then return nil end
    return {
        factID = entry.factID, fromActorID = entry.fromActorID,
        toActorID = entry.toActorID, provenance = entry.provenance,
        confidence = entry.confidence, reason = entry.reason,
        channel = entry.channel, at = entry.at,
    }
end

local function producerPath(fact)
    local kind = fact and tostring(fact.kind or "") or ""
    if kind == "npc.death" then
        return "PNC.Health.Kill -> WorldKnowledge_Server -> PublishDeath"
    end
    if kind == "zombie.pressure" then
        return "SocialEventHooks.ObserveZombieHorde -> PublishZombiePressure"
    end
    if kind == "faction.incident" then
        return "FactionIncidentService.AddIncident -> PublishIncident"
    end
    if kind == "faction.status" then
        return "Factions.Destroy/status -> PublishFactionStatus"
    end
    if kind == "world.state" then
        return "WorldKnowledge_PZ.ObserveAuthoritativeWorldState"
    end
    return tostring(fact and fact.producer or "unknown")
end

local function addConsumerEvidence(output, maximum, entry)
    if #output >= maximum or type(entry) ~= "table" then return end
    output[#output + 1] = entry
end

local function buildConsumerEvidence(knowledgeState, facts, context, trace, maximum)
    local output = {}
    local factIDs = {}
    local fact
    local factID
    local actorID
    local entry
    local reference
    local candidate
    local statementFactID
    local index

    for index = 1, #(facts or {}) do
        fact = facts[index]
        factID = id(fact and fact.factID)
        if factID then
            factIDs[factID] = true
            addConsumerEvidence(output, maximum, {
                factID = factID, system = producerPath(fact),
                role = "producer", status = "published",
                evidence = "fact_record", detail = "authoritative producer path",
            })
            addConsumerEvidence(output, maximum, {
                factID = factID,
                system = "PsychopatzCore.WorldKnowledge.Ledger",
                role = "storage", status = "stored",
                evidence = "ledger_record", detail = "fact is present in bounded ledger",
            })
        end
    end

    for actorID, entry in pairs(knowledgeState and knowledgeState.byActor or {}) do
        for factID, reference in pairs(entry and entry.refs or {}) do
            factID = id(factID)
            if factID and factIDs[factID] and type(reference) == "table" then
                addConsumerEvidence(output, maximum, {
                    factID = factID,
                    system = "PNC.WorldKnowledge.acquire / CoreWKG.Acquire",
                    role = "actor_knowledge", status = "acquired",
                    evidence = "actor_reference", actorID = tostring(actorID),
                    provenance = reference.provenance,
                    source = reference.source,
                    sourceActorID = reference.sourceActorID,
                    acquisitionPath = reference.acquisitionPath,
                    confidence = reference.confidence,
                    learnedAt = reference.learnedAt,
                    detail = "authorized actor reference exists",
                })
            end
        end
    end

    for index = 1, #((context and context.worldKnowledge
        and context.worldKnowledge.candidates) or {}) do
        candidate = context.worldKnowledge.candidates[index]
        factID = id(candidate and candidate.factID)
        if factID and factIDs[factID] then
            addConsumerEvidence(output, maximum, {
                factID = factID,
                system = "Core.ActorWorldKnowledge.BuildContext",
                role = "relevance", status = "debug_preview_selected",
                evidence = "inspector_context_preview",
                actorID = context.worldKnowledge.actorID,
                provenance = candidate.provenance,
                confidence = candidate.confidence,
                score = candidate.score,
                detail = "selected for the inspector's requested actor",
            })
        end
    end

    for index = 1, #((context and context.npcGossip
        and context.npcGossip.factRefs) or {}) do
        statementFactID = id(context.npcGossip.factRefs[index])
        if statementFactID and factIDs[statementFactID] then
            addConsumerEvidence(output, maximum, {
                factID = statementFactID,
                system = "PNC.SemanticCognitionService",
                role = "conversation", status = "debug_preview_projected",
                evidence = "inspector_context_preview",
                actorID = context.worldKnowledge
                    and context.worldKnowledge.actorID or nil,
                detail = "npcGossip projection is available; no live request is implied",
            })
        end
    end

    for index = 1, #(trace or {}) do
        entry = trace[index]
        factID = id(entry and entry.factID)
        if factID and factIDs[factID] then
            addConsumerEvidence(output, maximum, {
                factID = factID,
                system = "CoreWKG.Share / propagation trace",
                role = "propagation",
                status = entry.accepted == false and "rejected" or "transferred",
                evidence = "runtime_trace",
                actorID = entry.toActorID,
                sourceActorID = entry.fromActorID,
                provenance = entry.provenance,
                confidence = entry.confidence,
                channel = entry.channel,
                detail = entry.reason or "bounded opportunistic share",
            })
        end
    end

    table.sort(output, function(left, right)
        if left.factID ~= right.factID then
            return tostring(left.factID) < tostring(right.factID)
        end
        if left.role ~= right.role then
            return tostring(left.role) < tostring(right.role)
        end
        return tostring(left.system) < tostring(right.system)
    end)
    return output
end

local function buildActorRows(state, selectedID, maximum)
    local rows = {}
    for actorID, entry in pairs(state.byActor or {}) do
        rows[#rows + 1] = {
            actorID = tostring(actorID),
            selected = tostring(actorID) == tostring(selectedID or ""),
            referenceCount = entry and entry.order and #entry.order or 0,
        }
    end
    table.sort(rows, function(left, right)
        return tostring(left.actorID) < tostring(right.actorID)
    end)
    while #rows > maximum do table.remove(rows) end
    return rows
end

local function buildActor(state, ledger, actorID, maximum)
    local entry = state.byActor and state.byActor[actorID] or nil
    local output = {
        actorID = actorID, known = entry ~= nil,
        referenceCount = entry and entry.order and #entry.order or 0,
        references = {},
    }
    if not entry then return output end
    local order = entry.order or {}
    local start = math.max(1, #order - maximum + 1)
    for index = #order, start, -1 do
        local factID = order[index]
        local reference = entry.refs and entry.refs[factID] or nil
        local compact = compactReference(reference, ledger.Get(ledger, factID))
        if compact then output.references[#output.references + 1] = compact end
    end
    return output
end

local function buildExplanation(raw, maximum)
    if type(raw) ~= "table" then return nil end
    local output = {
        factID = raw.factID, kind = raw.kind, producer = raw.producer,
        occurredAt = raw.occurredAt, learnedAt = raw.learnedAt,
        acquisitionPath = raw.acquisitionPath, source = raw.source,
        sourceActorID = raw.sourceActorID, provenance = raw.provenance,
        confidence = raw.confidence, ranking = {},
    }
    for index = 1, math.min(maximum, #(raw.ranking or {})) do
        local candidate = compactCandidate(raw.ranking[index])
        if candidate then output.ranking[#output.ranking + 1] = candidate end
    end
    return output
end

local function buildContext(actorID, now, maximum, language)
    if not actorID then
        return { worldKnowledge = { candidates = {} },
            npcGossip = { statements = {}, factRefs = {} } }
    end
    return Adapter.Core.Context(actorID, {
        max = maximum, now = now,
        renderFact = function(fact, reference)
            return Adapter.RenderFact(fact, reference, { language = language })
        end,
    })
end

local function buildMetrics(ledgerState, knowledgeState, factModule, now,
    trace, facts, context, consumers)
    local factKinds = {}
    local factCount = 0
    for _, factID in ipairs(ledgerState.order or {}) do
        local fact = ledgerState.facts and ledgerState.facts[factID] or nil
        if fact and not factModule.IsExpired(fact, now) then
            factCount = factCount + 1
            local kind = tostring(fact.kind or "unknown")
            factKinds[kind] = (factKinds[kind] or 0) + 1
        end
    end

    local knownActorCount = 0
    local referenceCount = 0
    for _, entry in pairs(knowledgeState.byActor or {}) do
        local count = entry and entry.order and #entry.order or 0
        referenceCount = referenceCount + count
        if count > 0 then knownActorCount = knownActorCount + 1 end
    end

    local candidates = context and context.worldKnowledge
        and context.worldKnowledge.candidates or {}
    local statements = context and context.npcGossip
        and context.npcGossip.statements or {}
    return {
        ledger = ledgerState.metrics,
        knowledge = knowledgeState.metrics,
        ledgerRevision = ledgerState.revision,
        factCount = factCount,
        returnedFactCount = #(facts or {}),
        factKinds = factKinds,
        knownActorCount = knownActorCount,
        referenceCount = referenceCount,
        contextCandidateCount = #candidates,
        statementCount = #statements,
        traceCount = #trace,
        consumerEvidenceCount = #(consumers or {}),
    }
end

function Debug.BuildSnapshotForPlayer(_, request)
    request = type(request) == "table" and request or {}
    local worldKnowledge = Adapter and Adapter.Core or nil
    local ledger = worldKnowledge and worldKnowledge.Ledger
    local knowledge = worldKnowledge and worldKnowledge.ActorKnowledge
    local ledgerState = worldKnowledge and worldKnowledge.LedgerState or nil
    local knowledgeState = worldKnowledge and worldKnowledge.KnowledgeState or nil
    if not ledger or not knowledge or not ledgerState or not knowledgeState then
        return nil, "world_knowledge_unavailable"
    end
    local now = Core and Core.Now and Core.Now() or 0
    local actorID, factID = id(request.actorID), id(request.factID)
    local language = tostring(request.language or "EN"):upper()
    if language ~= "TL" then language = "EN" end
    local facts = {}
    if factID then
        local fact = ledger.Get(ledgerState, factID)
        if fact and not worldKnowledge.Fact.IsExpired(fact, now) then
            facts[1] = compactFact(fact)
        end
    else
        for _, fact in ipairs(ledger.Query(ledgerState, {
            max = limit(request.factLimit, Debug.MAX_FACTS, Debug.MAX_FACTS),
            kind = id(request.kind), producer = id(request.producer),
            retention = id(request.retention), subjectID = id(request.subjectID),
            locationID = id(request.locationID), now = now,
        })) do
            facts[#facts + 1] = compactFact(fact)
        end
    end
    local maxRefs = limit(request.referenceLimit, Debug.MAX_REFS, Debug.MAX_REFS)
    local maxCandidates = limit(request.candidateLimit,
        Debug.MAX_CANDIDATES, Debug.MAX_CANDIDATES)
    local context = buildContext(actorID, now, maxCandidates, language)
    local explanation, explanationReason
    if actorID and factID then
        local explainActor = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(actorID) or { coreActorID = actorID }
        local rawExplanation, rawReason = Adapter.Explain(
            explainActor, factID, now)
        explanation = buildExplanation(rawExplanation, maxCandidates)
        explanationReason = rawReason
        if not explanation then explanationReason = explanationReason or "knowledge_not_found" end
    end
    local trace = {}
    local sourceTrace = worldKnowledge.Trace or {}
    local traceLimit = limit(request.traceLimit, Debug.MAX_TRACE, Debug.MAX_TRACE)
    local start = math.max(1, #sourceTrace - traceLimit + 1)
    for index = #sourceTrace, start, -1 do
        local item = compactTrace(sourceTrace[index])
        if item then trace[#trace + 1] = item end
    end
    local consumerLimit = limit(request.consumerLimit,
        Debug.MAX_CONSUMERS, Debug.MAX_CONSUMERS)
    local consumerEvidence = buildConsumerEvidence(
        knowledgeState, facts, context, trace, consumerLimit)
    return {
        schema = "PNC.WorldKnowledgeDebug", schemaVersion = Debug.VERSION,
        serverTime = now, actorID = actorID, factID = factID, facts = facts,
        actors = buildActorRows(knowledgeState, actorID,
            limit(request.actorLimit, Debug.MAX_ACTORS, Debug.MAX_ACTORS)),
        actor = actorID and buildActor(knowledgeState, ledger, actorID, maxRefs)
            or nil,
        context = {
            worldKnowledge = context.worldKnowledge or { candidates = {} },
            npcGossip = context.npcGossip or { statements = {}, factRefs = {} },
        },
        explanation = explanation, explanationReason = explanationReason,
        trace = trace,
        consumerEvidence = consumerEvidence,
        metrics = buildMetrics(ledgerState, knowledgeState, worldKnowledge.Fact,
            now, trace, facts, context, consumerEvidence),
        persistence = {
            owner = "ProjectHoomans",
            modDataKey = "PNC.WorldKnowledge",
            saveEvent = "Events.OnSave",
            storesHistoricalFacts = true,
            storesActorReferences = true,
            storesLocalizedProse = false,
            storesTranscripts = false,
        },
        worldState = {
            observed = Adapter and Adapter.WorldState
                and Adapter.WorldState.last ~= nil or false,
        },
        limits = {
            facts = Debug.MAX_FACTS, actors = Debug.MAX_ACTORS,
            references = Debug.MAX_REFS, candidates = Debug.MAX_CANDIDATES,
            trace = Debug.MAX_TRACE, consumers = Debug.MAX_CONSUMERS,
        },
    }, "ok"
end

return Debug
