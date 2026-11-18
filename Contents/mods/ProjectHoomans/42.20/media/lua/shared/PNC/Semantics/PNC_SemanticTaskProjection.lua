-- Bounded read-only task-state projection shared by native conversation
-- context and the headless semantic worker. Derives presentation state from
-- existing authoritative task/session/plan state without creating a second
-- task-authority store.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Projection = PNC.Semantics.TaskProjection or {}
PNC.Semantics.TaskProjection = Projection

local STATUS_MAP = {
    active = "active",
    admitted = "active",
    accepted = "active",
    pending = "active",
    sent = "active",
    running = "active",
    completed = "completed",
    failed = "failed",
    rejected = "rejected",
    cancelled = "cancelled",
    canceled = "cancelled",
}

local RETIRE_WAIT_AT = {
    active = true,
    completed = true,
    failed = true,
    rejected = true,
}

local function normalizedAction(value)
    value = string.upper(tostring(value or ""))
    value = string.gsub(value, "[%s%-]+", "_")
    return value ~= "" and value or nil
end

function Projection.NormalizeStatus(status)
    local key = string.lower(tostring(status or ""))
    return STATUS_MAP[key]
end

local function normalizeEntry(action, raw, defaultStatus, npcID)
    action = normalizedAction(action or (type(raw) == "table" and raw.action))
    if not action then return nil end
    local status = type(raw) == "table"
        and Projection.NormalizeStatus(raw.status)
        or Projection.NormalizeStatus(defaultStatus)
    if not status then return nil end
    local requestID = type(raw) == "table" and raw.requestID or nil
    if requestID == nil and type(raw) == "table"
        and type(raw.request) == "table"
    then
        requestID = raw.request.requestID
    end
    local entryNpcID = type(raw) == "table" and raw.npcID or npcID
    return {
        action = action,
        status = status,
        requestID = requestID ~= nil and tostring(requestID) or nil,
        npcID = entryNpcID ~= nil and tostring(entryNpcID) or nil,
        reason = type(raw) == "table" and raw.reason or nil,
        authoritative = true,
    }
end

local function applyOutcomeTable(output, outcomes, npcID)
    if type(outcomes) ~= "table" then return end
    for key, raw in pairs(outcomes) do
        local action = type(raw) == "table" and raw.action or key
        local entry = normalizeEntry(action, raw, nil, npcID)
        if entry then
            output[entry.action] = entry
        end
    end
end

local function planFromEntry(entry)
    if type(entry) ~= "table" then return nil end
    if type(entry.record) == "table"
        and type(entry.record.semanticActionPlan) == "table"
    then
        return entry.record.semanticActionPlan
    end
    if type(entry.snapshot) == "table"
        and type(entry.snapshot.semanticActionPlan) == "table"
    then
        return entry.snapshot.semanticActionPlan
    end
    return nil
end

function Projection.Build(sources)
    sources = type(sources) == "table" and sources or {}
    local output = {}
    local npcID = sources.npcID ~= nil and tostring(sources.npcID) or nil

    applyOutcomeTable(output, sources.existing, npcID)

    local plan = planFromEntry(sources.entry)
    if type(plan) == "table" and type(plan.metadata) == "table" then
        local planEntry = normalizeEntry(
            plan.metadata.taskAction,
            {
                action = plan.metadata.taskAction,
                status = plan.state,
                requestID = plan.requestID,
                npcID = plan.npcID or npcID,
            },
            nil,
            npcID
        )
        if planEntry then
            output[planEntry.action] = planEntry
        end
    end

    local clientState = type(sources.clientState) == "table"
        and sources.clientState or nil
    if clientState and npcID and npcID ~= ""
        and type(clientState.semanticTaskOutcomes) == "table"
    then
        applyOutcomeTable(
            output,
            clientState.semanticTaskOutcomes[npcID],
            npcID
        )
    end

    local session = type(sources.session) == "table"
        and sources.session or nil
    if session then
        applyOutcomeTable(output, session.semanticTaskOutcomes, npcID)
        if type(session.semanticTaskRequests) == "table" then
            for requestID, pending in pairs(session.semanticTaskRequests) do
                if type(pending) == "table" then
                    local entry = normalizeEntry(
                        pending.action,
                        {
                            action = pending.action,
                            status = "active",
                            requestID = (pending.request
                                and pending.request.requestID) or requestID,
                            npcID = npcID,
                        },
                        "active",
                        npcID
                    )
                    if entry then
                        output[entry.action] = entry
                    end
                end
            end
        end
    end

    return output
end

function Projection.Entry(context, action)
    if type(context) ~= "table" then return nil end
    local key = normalizedAction(action)
    if not key then return nil end
    local projection = context.taskProjection
    if type(projection) ~= "table" then return nil end
    local entry = projection[key]
    return type(entry) == "table" and entry or nil
end

function Projection.ShouldRetire(action, context)
    local key = normalizedAction(action)
    if key ~= "WAIT_AT" then return false end
    local entry = Projection.Entry(context, key)
    if not entry then return false end
    return RETIRE_WAIT_AT[tostring(entry.status or "")] == true
end

return Projection
