PNC = PNC or {}
PNC.WorldKnowledgeDebugModel = PNC.WorldKnowledgeDebugModel or {}

local Model = PNC.WorldKnowledgeDebugModel

local function value(entry, fallback)
    if entry == nil then return fallback or "unknown" end
    if type(entry) == "table" then
        if entry.id then return tostring(entry.id) end
        if entry.kind then return tostring(entry.kind) end
        return "table"
    end
    return tostring(entry)
end

local function row(label, detail, item)
    item = item or {}
    item.label = tostring(label or "")
    item.detail = tostring(detail or "")
    return item
end

local function appendActor(actors, item, fromSnapshot)
    local actorID = item and (item.actorID or item.coreActorID
        or item.id or item.npcID)
    if not actorID then return end
    actorID = tostring(actorID)
    local existing = actors[actorID]
    if not existing then
        existing = { actorID = actorID, referenceCount = 0 }
        actors[actorID] = existing
    end
    if fromSnapshot then
        existing.referenceCount = tonumber(item.referenceCount) or 0
    elseif not existing.referenceCount then
        existing.referenceCount = tonumber(item.referenceCount) or 0
    end
    existing.label = actorID
    existing.detail = "references: " .. tostring(existing.referenceCount or 0)
end

function Model.ActorItems(snapshot, roster)
    local actors = {}
    for _, item in ipairs(roster or {}) do appendActor(actors, item, false) end
    for _, item in ipairs(snapshot and snapshot.actors or {}) do
        appendActor(actors, item, true)
    end
    local rows = {}
    for _, item in pairs(actors) do
        rows[#rows + 1] = row(item.label, item.detail, item)
    end
    table.sort(rows, function(left, right)
        local leftKnown = (tonumber(left.referenceCount) or 0) > 0
        local rightKnown = (tonumber(right.referenceCount) or 0) > 0
        if leftKnown ~= rightKnown then return leftKnown end
        return left.label < right.label
    end)
    return rows
end

local function emptyRow(label, detail, reason)
    return row(label, detail, { empty = true, reason = reason })
end

function Model.FactRows(snapshot)
    local rows = {}
    for _, fact in ipairs(snapshot and snapshot.facts or {}) do
        rows[#rows + 1] = row(fact.factID,
            value(fact.kind) .. " / " .. value(fact.producer), {
                factID = fact.factID, fact = fact,
            })
    end
    if #rows == 0 then
        rows[1] = emptyRow("No facts published",
            "The current bounded ledger has no non-expired facts.", "no_facts")
    end
    return rows
end

function Model.KnowledgeRows(snapshot)
    local rows = {}
    for _, reference in ipairs(snapshot and snapshot.actor
        and snapshot.actor.references or {}) do
        rows[#rows + 1] = row(reference.factID,
            value(reference.provenance) .. " / confidence "
                .. string.format("%.2f", tonumber(reference.confidence) or 0), {
                factID = reference.factID, reference = reference,
            })
    end
    if #rows == 0 then
        local actorID = snapshot and snapshot.actorID or "no actor selected"
        rows[1] = emptyRow("No known facts",
            "Selected actor has no authorized fact references: " .. tostring(actorID),
            "no_actor_knowledge")
    end
    return rows
end

function Model.ContextRows(snapshot)
    local rows = {}
    for _, candidate in ipairs(snapshot and snapshot.context
        and snapshot.context.worldKnowledge
        and snapshot.context.worldKnowledge.candidates or {}) do
        rows[#rows + 1] = row(candidate.factID,
            "score " .. string.format("%.2f", tonumber(candidate.score) or 0)
                .. " / " .. value(candidate.provenance), {
                factID = candidate.factID, candidate = candidate,
            })
    end
    for index, statement in ipairs(snapshot and snapshot.context
        and snapshot.context.npcGossip
        and snapshot.context.npcGossip.statements or {}) do
        rows[#rows + 1] = row("statement " .. tostring(index), statement, {
            statement = statement,
            factID = snapshot.context.npcGossip.factRefs
                and snapshot.context.npcGossip.factRefs[index],
        })
    end
    if #rows == 0 then
        rows[1] = emptyRow("No grounded context",
            "No authorized candidate or localized statement for this actor.",
            "no_grounded_context")
    end
    return rows
end

function Model.ExplanationRows(snapshot)
    local explanation = snapshot and snapshot.explanation
    if not explanation then
        return { row("No explanation", snapshot and snapshot.explanationReason
            or "knowledge_not_found", {}) }
    end
    local rows = {
        row("Fact", explanation.factID, { factID = explanation.factID }),
        row("Provenance", explanation.provenance),
        row("Confidence", string.format("%.2f",
            tonumber(explanation.confidence) or 0)),
        row("Acquisition", explanation.acquisitionPath),
        row("Source", explanation.source),
        row("Source actor", explanation.sourceActorID),
    }
    for index, candidate in ipairs(explanation.ranking or {}) do
        rows[#rows + 1] = row("rank " .. tostring(index),
            candidate.factID .. " / " .. string.format("%.2f",
                tonumber(candidate.score) or 0), {
                factID = candidate.factID, candidate = candidate,
            })
    end
    return rows
end

function Model.TraceRows(snapshot)
    local rows = {}
    for index, entry in ipairs(snapshot and snapshot.trace or {}) do
        rows[#rows + 1] = row("trace " .. tostring(index),
            value(entry.factID) .. " " .. value(entry.fromActorID)
                .. " -> " .. value(entry.toActorID), { trace = entry })
    end
    if #rows == 0 then
        rows[1] = emptyRow("No propagation trace",
            "No bounded fact transfer has been recorded in this runtime.",
            "no_propagation_trace")
    end
    return rows
end

function Model.ConsumerRows(snapshot)
    local rows = {}
    for _, evidence in ipairs(snapshot and snapshot.consumerEvidence or {}) do
        local actor = evidence.actorID and (" / actor " .. tostring(evidence.actorID)) or ""
        rows[#rows + 1] = row(
            tostring(evidence.factID or "unknown") .. " / "
                .. tostring(evidence.system or "unknown"),
            tostring(evidence.role or "consumer") .. " / "
                .. tostring(evidence.status or "unknown") .. actor,
            { factID = evidence.factID, consumer = evidence }
        )
    end
    if #rows == 0 then
        rows[1] = emptyRow("No consumer evidence",
            "No bounded producer, storage, knowledge, preview, or propagation evidence was returned.",
            "no_consumer_evidence")
    end
    return rows
end

function Model.Rows(snapshot, view)
    if view == "knowledge" then return Model.KnowledgeRows(snapshot) end
    if view == "context" then return Model.ContextRows(snapshot) end
    if view == "why" then return Model.ExplanationRows(snapshot) end
    if view == "trace" then return Model.TraceRows(snapshot) end
    if view == "consumers" then return Model.ConsumerRows(snapshot) end
    return Model.FactRows(snapshot)
end

local function addDetail(rows, label, item)
    rows[#rows + 1] = { label = label, value = value(item) }
end

local function formatFactKinds(kinds)
    local names = {}
    for kind in pairs(kinds or {}) do names[#names + 1] = tostring(kind) end
    table.sort(names)
    local values = {}
    for _, kind in ipairs(names) do
        values[#values + 1] = kind .. "=" .. tostring(kinds[kind])
    end
    return #values > 0 and table.concat(values, ", ") or "none"
end

function Model.SummaryRows(snapshot)
    local metrics = snapshot and snapshot.metrics or {}
    local actor = snapshot and snapshot.actor or nil
    local context = snapshot and snapshot.context or {}
    local candidates = context.worldKnowledge
        and context.worldKnowledge.candidates or {}
    local statements = context.npcGossip
        and context.npcGossip.statements or {}
    return {
        { label = "Ledger", detail = tostring(metrics.factCount or 0)
            .. " facts / revision " .. tostring(metrics.ledgerRevision or 0) },
        { label = "Fact kinds", detail = formatFactKinds(metrics.factKinds) },
        { label = "Knowledge", detail = tostring(metrics.knownActorCount or 0)
            .. " actors / " .. tostring(metrics.referenceCount or 0) .. " references" },
        { label = "Selected actor", detail = tostring(snapshot and snapshot.actorID
            or "none") .. " / " .. tostring(actor and actor.referenceCount or 0)
            .. " references" },
        { label = "Context", detail = tostring(#candidates) .. " candidates / "
            .. tostring(#statements) .. " statements" },
        { label = "Propagation", detail = tostring(metrics.traceCount or 0)
            .. " trace entries" },
        { label = "Consumer evidence", detail = tostring(
            metrics.consumerEvidenceCount or 0)
            .. " bounded entries; preview is not live proof" },
        { label = "Store contract", detail = tostring(snapshot and snapshot.persistence
            and snapshot.persistence.modDataKey or "unknown") .. " via "
            .. tostring(snapshot and snapshot.persistence
                and snapshot.persistence.saveEvent or "unknown") },
        { label = "World state", detail = snapshot and snapshot.worldState
            and snapshot.worldState.observed and "authority observed"
            or "no authority observation in this runtime" },
    }
end

function Model.DetailRows(snapshot, item, view)
    local rows = {}
    for _, summary in ipairs(Model.SummaryRows(snapshot)) do
        addDetail(rows, summary.label, summary.detail)
    end
    if not item then return rows end
    addDetail(rows, "Selection", item.label)
    addDetail(rows, "Detail", item.detail)
    if item.fact then
        local fact = item.fact
        addDetail(rows, "Fact ID", fact.factID)
        addDetail(rows, "Kind", fact.kind)
        addDetail(rows, "Producer", fact.producer)
        addDetail(rows, "Subject", fact.subject)
        addDetail(rows, "Cause", fact.cause)
        addDetail(rows, "Occurred", fact.occurredAt)
        addDetail(rows, "Observed", fact.observedAt)
        addDetail(rows, "Retention", fact.retention)
        addDetail(rows, "Payload", fact.payload and "bounded" or "none")
    elseif item.reference then
        for _, key in ipairs({ "factID", "kind", "producer", "provenance",
            "source", "sourceActorID", "acquisitionPath", "learnedAt",
            "confidence" }) do
            addDetail(rows, key, item.reference[key])
        end
    elseif item.candidate then
        for _, key in ipairs({ "factID", "kind", "producer", "provenance",
            "confidence", "score" }) do
            addDetail(rows, key, item.candidate[key])
        end
        addDetail(rows, "Why", item.candidate.why)
    elseif item.trace then
        for _, key in ipairs({ "factID", "fromActorID", "toActorID",
            "provenance", "confidence", "reason", "channel", "at" }) do
            addDetail(rows, key, item.trace[key])
        end
    elseif item.consumer then
        for _, key in ipairs({ "factID", "system", "role", "status",
            "evidence", "detail", "actorID", "sourceActorID", "provenance",
            "source", "acquisitionPath", "confidence", "score", "learnedAt",
            "channel" }) do
            addDetail(rows, key, item.consumer[key])
        end
    elseif item.statement then
        addDetail(rows, "Fact ref", item.factID)
        addDetail(rows, "Final statement", item.statement)
    end
    addDetail(rows, "View", view)
    addDetail(rows, "Actor", snapshot and snapshot.actorID)
    return rows
end

return Model
