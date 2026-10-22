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

local function appendActor(rows, seen, item)
    local actorID = item and (item.actorID or item.id or item.npcID)
    if not actorID then return end
    actorID = tostring(actorID)
    if seen[actorID] then return end
    seen[actorID] = true
    rows[#rows + 1] = row(actorID,
        "references: " .. tostring(item.referenceCount or 0), {
            actorID = actorID,
            referenceCount = item.referenceCount or 0,
        })
end

function Model.ActorItems(snapshot, roster)
    local rows, seen = {}, {}
    for _, item in ipairs(roster or {}) do appendActor(rows, seen, item) end
    for _, item in ipairs(snapshot and snapshot.actors or {}) do
        appendActor(rows, seen, item)
    end
    table.sort(rows, function(left, right) return left.label < right.label end)
    return rows
end

function Model.FactRows(snapshot)
    local rows = {}
    for _, fact in ipairs(snapshot and snapshot.facts or {}) do
        rows[#rows + 1] = row(fact.factID,
            value(fact.kind) .. " / " .. value(fact.producer), {
                factID = fact.factID, fact = fact,
            })
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
    return rows
end

function Model.Rows(snapshot, view)
    if view == "knowledge" then return Model.KnowledgeRows(snapshot) end
    if view == "context" then return Model.ContextRows(snapshot) end
    if view == "why" then return Model.ExplanationRows(snapshot) end
    if view == "trace" then return Model.TraceRows(snapshot) end
    return Model.FactRows(snapshot)
end

local function addDetail(rows, label, item)
    rows[#rows + 1] = { label = label, value = value(item) }
end

function Model.DetailRows(snapshot, item, view)
    local rows = {}
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
    elseif item.statement then
        addDetail(rows, "Fact ref", item.factID)
        addDetail(rows, "Final statement", item.statement)
    end
    addDetail(rows, "View", view)
    addDetail(rows, "Actor", snapshot and snapshot.actorID)
    return rows
end

return Model
